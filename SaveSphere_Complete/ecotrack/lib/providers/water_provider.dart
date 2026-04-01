import 'dart:async';
import 'package:flutter/material.dart';
import '../models/water_models.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../services/notification_tracker.dart';
import '../utils/analytics.dart';
import '../utils/water_mock_data.dart';
import '../utils/mock_data.dart';

/// Minimum tank level before a "low water" alert is triggered (Liters)
const double kLowTankThreshold = 250.0;
const double kAutoRefillLiters = 150.0;
const double kMaxTankLiters = 1000.0;

/// During sleep mode, if water flows continuously for this many seconds, trigger a leak alert
const int kLeakDetectionSeconds = 120; // 2 minutes

class WaterDataProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  // ── Live tank state (from Firebase) ─────────────────────────────────────────
  WaterLiveData? _liveWater;
  WaterLiveData? get liveWater => _liveWater;

  // ── Historical water logs ────────────────────────────────────────────────────
  List<WaterLiveData> _waterLogs = [];

  // ── Analytics buckets ────────────────────────────────────────────────────────
  List<DeltaLog> _deltas = [];

  List<BucketData> _hourlyLive = [];
  List<BucketData> get hourlyLive => _hourlyLive;

  List<BucketData> _daily = [];
  List<BucketData> get daily => _daily;

  List<BucketData> _weekly = [];
  List<BucketData> get weekly => _weekly;

  List<BucketData> _monthly = [];
  List<BucketData> get monthly => _monthly;

  List<DeltaLog> get deltas => _deltas;

  StreamSubscription? _liveSubscription;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // ── Sleep Mode + Leak Detection ───────────────────────────────────────────────
  bool _sleepMode = false;
  bool get sleepMode => _sleepMode;

  /// Seconds the water has been continuously flowing during sleep mode
  int _continuousFlowSeconds = 0;
  int get continuousFlowSeconds => _continuousFlowSeconds;

  bool _leakDetected = false;
  bool get leakDetected => _leakDetected;

  /// Approx liters wasted since leak started
  double _leakedWaterL = 0.0;
  double get leakedWaterL => _leakedWaterL;

  Timer? _leakTimer;

  // ── Low Tank Alert ────────────────────────────────────────────────────────────
  bool _lowTankAlertSent = false;

  WaterDataProvider() {
    _init();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Initialise: fetch logs + subscribe to live stream
  // ─────────────────────────────────────────────────────────────────────────────
  void _init() async {
    try {
      // Fetch structured water logs
      _waterLogs = await _firebaseService.fetchWaterDataLogs();
      _buildAnalyticsFromWaterLogs();

      // Subscribe to real-time water updates
      _liveSubscription = _firebaseService.getWaterLiveStream().listen((data) {
        if (data != null) {
          _liveWater = data;

          // Check low tank alert
          _checkLowTankAlert(data.tankLevel);

          // Leak detection during sleep mode
          _handleLeakDetection(data.flowRate);

          // Check for unusually high flow rate (> 15 L/min)
          if (data.flowRate > 15.0) {
            _checkHighWaterUsage(data.flowRate);
          }

          // Add to historical if new timestamp
          final isNew = _waterLogs.isEmpty ||
              _waterLogs.last.timestamp != data.timestamp;
          if (isNew) {
            _waterLogs.add(data);
            _buildAnalyticsFromWaterLogs();
          }

          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('WaterDataProvider: Error initialising: $e');
      _buildAnalyticsFromWaterLogs(); // fallback with empty/mock
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build analytics deltas from WaterLiveData logs
  // ─────────────────────────────────────────────────────────────────────────────
  void _buildAnalyticsFromWaterLogs() {
    // Convert WaterLiveData list to EnergyLog-compatible list for analytics reuse.
    // The analytics engine expects an ever-increasing cumulative consumption value.
    // Because tankLevel goes down when used, passing tankLevel directly caused the 
    // engine to treat it as a reset and add the entire tank level to the usage total!
    // We must calculate cumulative drain.
    double cumulativeDrain = 0.0;
    double cumulativeKitchen = 0.0;
    double cumulativeWashroom1 = 0.0;
    double cumulativeWashroom2 = 0.0;
    final energyLogs = <EnergyLog>[];
    
    for (int i = 0; i < _waterLogs.length; i++) {
      final w = _waterLogs[i];
      if (i > 0) {
        final prev = _waterLogs[i - 1];
        if (prev.tankLevel > w.tankLevel) {
          double diff = prev.tankLevel - w.tankLevel;
          cumulativeDrain += diff;
          
          final k = w.sections['kitchen'] ?? 0.0;
          final w1 = w.sections['washroom1'] ?? 0.0;
          final w2 = w.sections['washroom2'] ?? 0.0;
          final tOut = k + w1 + w2;
          if (tOut > 0) {
             cumulativeKitchen += diff * (k / tOut);
             cumulativeWashroom1 += diff * (w1 / tOut);
             cumulativeWashroom2 += diff * (w2 / tOut);
          } else {
             // If fallback, assign to kitchen to not lose it? Or leave unassigned.
             // We'll leave it in cumulativeDrain only
             cumulativeKitchen += diff; 
          }
        }
      }
      
      energyLogs.add(EnergyLog(
        timestamp: w.timestamp,
        power: {
          'kitchen': w.sections['kitchen'] ?? 0.0,
          'bedroom': w.sections['washroom1'] ?? 0.0,
          'livingRoom': w.sections['washroom2'] ?? 0.0,
          'total': w.flowRate,
        },
        energy: {
          'kitchen': cumulativeKitchen,
          'bedroom': cumulativeWashroom1,
          'livingRoom': cumulativeWashroom2,
        },
        switches: {
          'bedroom': w.motorStatus,
          'lrLight': w.outletOn,
          'lrTV': false,
          'kitchen': false,
        },
      ));
    }

    final computedDeltas = computeDeltas(energyLogs);
    final mockDeltas = getJanFebMockWaterDeltas();
    final now = DateTime.now();
    final historicalMockData = mockDeltas.where((m) {
      final parts = m.date.split('-');
      final mMonth = int.tryParse(parts[1]) ?? 0;
      return mMonth < now.month;
    }).toList();

    _deltas = [...historicalMockData, ...computedDeltas];
    _hourlyLive = groupHourlyLive(_deltas);
    _daily = groupDailyMonToSun(_deltas);
    _weekly = groupWeeklyW1ToW4(_deltas);
    _monthly = groupMonthlyJanToDec(_deltas);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Low Tank Alert
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _checkLowTankAlert(double tankLevel) async {
    final motorStatus = _liveWater?.motorStatus ?? false;

    // 1. Auto REFILL Logic (< 150L)
    if (tankLevel < kAutoRefillLiters && !motorStatus) {
      debugPrint('Auto-refill triggered: $tankLevel L is < 150 L');
      await toggleMotor();
      NotificationService().showNotification(
        '🚿 Auto-Refill Started',
        'Tank level below 150L. Motor enabled automatically.',
        type: 'water_info',
      );
    }

    // 2. Auto SHUTOFF Logic (>= 1000L)
    if (tankLevel >= kMaxTankLiters && motorStatus) {
      debugPrint('Auto-shutoff triggered: Tank full at $tankLevel L');
      await toggleMotor();
      _lowTankAlertSent = false; // Reset warning for next cycle
      NotificationService().showNotification(
        '✅ Tank Full',
        'Tank reached 1000L. Motor disabled automatically.',
        type: 'water_info',
      );
    }

    // 3. Low Warning (Existing logic at 250L)
    if (tankLevel < kLowTankThreshold && !_lowTankAlertSent) {
      _lowTankAlertSent = true;
      final tracker = NotificationTracker();
      if (await tracker.shouldNotifyWaterLow()) {
        NotificationService().showNotification(
          '⚠️ Water Tank Low',
          'Water tank is below 250L (currently ${tankLevel.toStringAsFixed(0)}L). Monitoring closely.',
          type: 'water_low',
        );
      }
    } else if (tankLevel >= kLowTankThreshold) {
      _lowTankAlertSent = false; // reset so alert can fire again next time
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // High Usage Alert
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _checkHighWaterUsage(double flowRate) async {
    final tracker = NotificationTracker();
    if (await tracker.shouldNotifyHighWater()) {
      NotificationService().showNotification(
        '⚠️ Water usage unusually high',
        'Your current water flow rate is very high (${flowRate.toStringAsFixed(1)} L/min). Check for open taps.',
        type: 'water_high',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Sleep Mode + Leak Detection
  // ─────────────────────────────────────────────────────────────────────────────

  /// Toggle sleep mode on/off
  void toggleSleepMode() {
    _sleepMode = !_sleepMode;
    if (!_sleepMode) {
      // Reset leak state when sleep mode is disabled
      _continuousFlowSeconds = 0;
      _leakDetected = false;
      _leakedWaterL = 0.0;
      _leakTimer?.cancel();
    } else {
      // Start monitoring immediately if flow already exists
      if ((_liveWater?.flowRate ?? 0) > 0.5) {
        _handleLeakDetection(_liveWater!.flowRate);
      }
    }
    notifyListeners();
  }

  void _handleLeakDetection(double flowRate) {
    final isFlowing = flowRate > 0.5; // threshold: >0.5 L/min means real flow

    if (_sleepMode && isFlowing) {
      if (_leakTimer == null || !_leakTimer!.isActive) {
        // Init state for timer
        _continuousFlowSeconds = 0;
        _leakedWaterL = 0.0;
        _leakDetected = false;

        _leakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          // Break condition if sleep mode off or flow drops
          final currentFlow = _liveWater?.flowRate ?? 0.0;
          if (!_sleepMode || currentFlow <= 0.5) {
            timer.cancel();
            _continuousFlowSeconds = 0;
            _leakedWaterL = 0.0;
            _leakDetected = false;
            notifyListeners();
            return;
          }

          _continuousFlowSeconds++;
          _leakedWaterL += (currentFlow / 60.0); // L/min → L per second

          if (_continuousFlowSeconds >= kLeakDetectionSeconds && !_leakDetected) {
            _leakDetected = true;
            _triggerLeakAlert(currentFlow);
          }
          notifyListeners(); // Refresh UI constantly so flow seconds / status updates immediately
        });
      }
    } else {
      // No flow or sleep mode off
      _leakTimer?.cancel();
      if (!isFlowing) {
        _continuousFlowSeconds = 0;
        _leakedWaterL = 0.0;
        _leakDetected = false;
      }
    }
  }

  Future<void> _triggerLeakAlert(double flowRate) async {
    final wasted = _leakedWaterL.toStringAsFixed(1);
    
    List<String> leakingRooms = [];
    if ((_liveWater?.sections['kitchen'] ?? 0) > 0) leakingRooms.add('Kitchen');
    if ((_liveWater?.sections['washroom1'] ?? 0) > 0) leakingRooms.add('Washroom 1');
    if ((_liveWater?.sections['washroom2'] ?? 0) > 0) leakingRooms.add('Washroom 2');
    
    String roomString = leakingRooms.isEmpty ? "unknown room" : leakingRooms.join(' and ');

    NotificationService().showNotification(
      '🚨 Leakage in $roomString!',
      'Flow rate: ${flowRate.toStringAsFixed(1)} L/min continuously for over 2 minutes in $roomString! Approx ${wasted}L wasted so far.',
      type: 'water_leak',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Motor Control (push to Firebase)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> toggleMotor() async {
    final current = _liveWater?.motorStatus ?? false;
    try {
      await _firebaseService.updateWaterMotorState(!current);
      // Optimistic UI update
      if (_liveWater != null) {
        _liveWater = WaterLiveData(
          timestamp: _liveWater!.timestamp,
          tankLevel: _liveWater!.tankLevel,
          flowRate: _liveWater!.flowRate,
          motorStatus: !current,
          outletOn: _liveWater!.outletOn,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('WaterDataProvider: Failed to toggle motor: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Computed Water Metrics
  // ─────────────────────────────────────────────────────────────────────────────
  WaterMetrics? get waterMetrics {
    if (_liveWater == null && _waterLogs.isEmpty && _deltas.isEmpty) return null;

    final monthWaterMap = getMonthTotalEnergy(_deltas);

    final currentFlowLpm = _liveWater?.flowRate ?? 0.0;
    final tankLevel = _liveWater?.tankLevel ?? 1000.0;
    final motorStatus = _liveWater?.motorStatus ?? false;
    final outletOn = _liveWater?.outletOn ?? false;

    // Monthly total is accumulated drain sum from delta logs
    final currentMonthLiters = monthWaterMap['total'] ?? 0.0;

    double todayLiters = 0;
    double yesterdayLiters = 0;
    if (_daily.isNotEmpty) {
      todayLiters = _daily.last.total;
      if (_daily.length > 1) yesterdayLiters = _daily[_daily.length - 2].total;
    }

    final daysPassed = DateTime.now().day > 0 ? DateTime.now().day : 1;
    final dailyAvg = currentMonthLiters > 0 ? currentMonthLiters / daysPassed : 0.0;

    final peak = findPeakUsage(_deltas);
    final peakDay = findPeakUsageDay(_deltas);
    final now = DateTime.now();
    final totalDays = DateTime(now.year, now.month + 1, 0).day;
    final estimatedLiters = dailyAvg * totalDays;

    return WaterMetrics(
      currentFlowLpm: currentFlowLpm,
      tankLevel: tankLevel,
      tankCapacity: 1000.0,
      motorStatus: motorStatus,
      outletOn: outletOn,
      todayUsageL: todayLiters,
      yesterdayUsageL: yesterdayLiters,
      weeklyAverageL: dailyAvg * 7,
      monthlyTotalL: currentMonthLiters,
      lastMonthTotalL: currentMonthLiters * 0.9,
      dailyAverageL: dailyAvg,
      peakTime: peak?.hour ?? '',
      peakRoom: 'Tank',
      peakDay: peakDay,
      estimatedMonthlyLiters: estimatedLiters,
      tariff: null,
      rooms: RoomWaterMetrics(
        kitchenFlowLpm: _liveWater?.sections['kitchen'] ?? 0.0,
        bedroomFlowLpm: _liveWater?.sections['washroom1'] ?? 0.0,
        livingRoomFlowLpm: _liveWater?.sections['washroom2'] ?? 0.0,
      ),
      weeklyBuckets: _weekly,
      monthlyBuckets: _monthly,
      dailyBuckets: _hourlyLive,
      roomMonthlyWater: {
        'Tank': currentMonthLiters,
        'kitchen': monthWaterMap['kitchen'] ?? 0.0,
        'washroom1': monthWaterMap['bedroom'] ?? 0.0,
        'washroom2': monthWaterMap['livingRoom'] ?? 0.0,
      },
    );
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    _leakTimer?.cancel();
    super.dispose();
  }
}
