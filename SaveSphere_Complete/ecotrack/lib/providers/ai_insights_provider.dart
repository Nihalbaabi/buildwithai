import 'package:flutter/material.dart';

import 'energy_provider.dart';
import 'water_provider.dart';
import '../services/ai/usage_pattern_service.dart';
import '../services/ai/optimization_service.dart';
import '../services/ai/simulation_service.dart';
import '../services/ai/prediction_service.dart';
import '../services/billing_calculator.dart';

class AIInsightsProvider extends ChangeNotifier {
  final EnergyDataProvider energyProvider;
  final WaterDataProvider waterProvider;

  final UsagePatternService _patternService = UsagePatternService();
  final OptimizationService _optService = OptimizationService();
  final SimulationService _simService = SimulationService();
  final PredictionService _predService = PredictionService();

  AIInsightsProvider({
    required this.energyProvider,
    required this.waterProvider,
  });

  String getUsagePattern() {
    final eMetrics = energyProvider.energyMetrics;
    final wMetrics = waterProvider.waterMetrics;

    if (eMetrics == null || wMetrics == null) {
      return "I need more data to analyze your usage patterns right now.";
    }

    // Extract last 24 values to form daily list or use hourly buckets
    List<double> energyVals = List.filled(24, 0.0);
    List<double> waterVals = List.filled(24, 0.0);

    for (var bucket in eMetrics.dailyBuckets) {
      final parts = bucket.label.split('-');
      if (parts.length > 2) {
        final hour = int.tryParse(parts[2].split(' ')[0]) ?? 0;
        if (hour >= 0 && hour < 24) energyVals[hour] += bucket.total;
      }
    }

    for (var bucket in wMetrics.dailyBuckets) {
      final parts = bucket.label.split('-');
      if (parts.length > 2) {
        final hour = int.tryParse(parts[2].split(' ')[0]) ?? 0;
        if (hour >= 0 && hour < 24) waterVals[hour] += bucket.total;
      }
    }

    final analysis = _patternService.analyse(
      energyValues: energyVals,
      waterValues: waterVals,
    );

    return "Your peak usage is between ${analysis.peakHours}. "
           "You follow an ${analysis.pattern} usage pattern. "
           "${analysis.weeklyTrend}";
  }

  String getOptimizationSuggestion() {
    final eMetrics = energyProvider.energyMetrics;
    final wMetrics = waterProvider.waterMetrics;

    if (eMetrics == null || wMetrics == null) {
      return "I don't have enough data to give optimization suggestions yet.";
    }

    final currentBill = calculateSlabBill(
      eMetrics.monthlyTotalKwh,
      tariff: eMetrics.tariff ?? defaultTariff,
    );

    return _optService.suggest(
      monthlyKwh: eMetrics.monthlyTotalKwh,
      lastMonthKwh: eMetrics.lastMonthTotalKwh,
      currentBillRs: currentBill,
      monthlyLiters: wMetrics.monthlyTotalL,
      lastMonthLiters: wMetrics.lastMonthTotalL,
      peakTime: eMetrics.peakTime,
    );
  }

  String runSimulation(double reductionPercentage) {
    final eMetrics = energyProvider.energyMetrics;
    final wMetrics = waterProvider.waterMetrics;

    if (eMetrics == null || wMetrics == null) {
      return "Simulation requires more active consumption data.";
    }

    final currentBill = calculateSlabBill(
      eMetrics.monthlyTotalKwh,
      tariff: eMetrics.tariff ?? defaultTariff,
    );

    final result = _simService.simulate(
      reductionPercentage: reductionPercentage,
      currentBillRs: currentBill,
      currentWaterLiters: wMetrics.monthlyTotalL,
    );

    return "Reducing usage by ${reductionPercentage.toInt()}% can save you "
           "₹${result.savings.toStringAsFixed(0)}/month, leading to an estimated bill of "
           "₹${result.newBill.toStringAsFixed(0)}. You could also save "
           "${result.waterSaved.toStringAsFixed(0)} liters of water.";
  }

  String getPrediction() {
    final eMetrics = energyProvider.energyMetrics;
    if (eMetrics == null) {
      return "I cannot predict future usage without historical data.";
    }

    final now = DateTime.now();
    final daysPassed = now.day > 0 ? now.day : 1;
    final totalDays = DateTime(now.year, now.month + 1, 0).day;

    return _predService.predict(
      lastMonthKwh: eMetrics.lastMonthTotalKwh,
      currentMonthKwh: eMetrics.monthlyTotalKwh,
      daysPassed: daysPassed,
      totalDays: totalDays,
    );
  }
}
