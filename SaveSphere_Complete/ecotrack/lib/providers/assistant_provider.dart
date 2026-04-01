import 'package:flutter/material.dart' hide Intent;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/energy_models.dart';
import '../models/assistant.dart';
import '../services/ai/time_parser.dart';
import '../services/ai/intent_detector.dart';
import '../services/ai/anomaly_engine.dart';
import '../services/ai/suggestion_engine.dart';
import '../services/ai/response_builder.dart';
import '../services/ai/context_manager.dart';
import '../services/voice_service.dart';
import 'theme_provider.dart';
import 'energy_provider.dart';
import 'water_provider.dart';
import 'ai_insights_provider.dart';

class ChatMessage {
  final String id;
  final String sender; // 'user' | 'ai'
  final String text;
  final AssistantResponse? responseMeta;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.responseMeta,
  });
}

class AssistantProvider extends ChangeNotifier {
  final SpeechToText _speechToText = SpeechToText();
  final VoiceService _voiceService = VoiceService();
  
  bool _isSpeechSupported = false;
  bool get isSpeechSupported => _isSpeechSupported;

  String _state = 'idle'; // idle, listening, processing
  String get state => _state;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  String _lastTranscript = "";
  String get lastTranscript => _lastTranscript;

  ConversationContext _context = createInitialContext();

  // History for suggestion rotation
  final List<String> _recentSuggestions = [];

  AssistantProvider() {
    _initSpeech();
  }

  AssistantMode _currentMode = AssistantMode.balanced;
  AssistantMode get currentMode => _currentMode;

  void setMode(AssistantMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  // --- AI INSIGHTS EXTENSION ---
  AIInsightsProvider? _aiInsightsProvider;
  
  void setAIInsightsProvider(AIInsightsProvider aiInsightsProvider) {
    _aiInsightsProvider = aiInsightsProvider;
  }

  String handleUsagePatternQuery() {
    return _aiInsightsProvider?.getUsagePattern() ?? "Fetching usage pattern...";
  }

  String handleOptimizationQuery() {
    return _aiInsightsProvider?.getOptimizationSuggestion() ?? "Generating optimization tips...";
  }

  String handleSimulationQuery(String query) {
    double percentage = 10.0;
    if (query.contains("20")) percentage = 20.0;
    else if (query.contains("30")) percentage = 30.0;
    else if (query.contains("50")) percentage = 50.0;
    
    return _aiInsightsProvider?.runSimulation(percentage) ?? "Simulating your savings...";
  }

  String handlePredictionQuery() {
    return _aiInsightsProvider?.getPrediction() ?? "Analysing future usage...";
  }
  // -----------------------------

  void _initSpeech() async {
    // Request microphone permission first
    PermissionStatus status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint("Microphone permission denied");
      _isSpeechSupported = false;
      notifyListeners();
      return;
    }

    _isSpeechSupported = await _speechToText.initialize(
      onStatus: (status) {
        debugPrint("Speech status: $status");
        if (status == "done" || status == "notListening") {
            _state = 'idle';
            notifyListeners();
        }
      },
      onError: (error) {
        debugPrint("Speech error: $error");
        _state = 'idle';
        notifyListeners();
      },
    );
    
    if (!_isSpeechSupported) {
        debugPrint("Speech recognition not available on this device.");
    }

    if (!_isSpeechSupported) {
        debugPrint("Speech recognition not available on this device.");
    }

    notifyListeners();
  }

  void startListening(EnergyDataProvider energyProvider, WaterDataProvider waterProvider, ThemeProvider themeProvider) async {
    final data = energyProvider.energyMetrics;
    if (data == null) return;
    
    if (!_isSpeechSupported) {
        debugPrint("Microphone not supported or permission denied.");
        return;
    }

    // Stop TTS if speaking
    await _voiceService.stop();

    _state = 'listening';
    _lastTranscript = "";
    notifyListeners();
    
    await _speechToText.listen(
      onResult: (result) async {
        _lastTranscript = result.recognizedWords;
        notifyListeners();

        if (result.finalResult && _lastTranscript.isNotEmpty) {
          _state = 'processing';
          notifyListeners();
          
          await _speechToText.stop();
          // Process the recognized query
          await processQuery(_lastTranscript, energyProvider, waterProvider, themeProvider);
        }
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  void stopListening(EnergyDataProvider energyProvider, WaterDataProvider waterProvider, ThemeProvider themeProvider) async {
    await _speechToText.stop();
    
    // If we have words, trigger processing manually if the onResult didn't already
    if (_lastTranscript.isNotEmpty && _state == 'listening') {
       final transcript = _lastTranscript;
       _state = 'processing';
       notifyListeners();
       await processQuery(transcript, energyProvider, waterProvider, themeProvider);
    } else {
      _state = 'idle';
      _lastTranscript = "";
      notifyListeners();
    }
  }

  Future<void> processQuery(String query, EnergyDataProvider energyProvider, WaterDataProvider waterProvider, ThemeProvider themeProvider) async {
    final data = energyProvider.energyMetrics;
    if (data == null) return;

    _state = 'processing';
    notifyListeners();

    // 1. Time Parsing
    final timeRef = parseTimeReference(query);

    // 2. Intent Detection
    final intentRes = detectIntent(query);
    final intent = intentRes.intent;
    final confidence = intentRes.confidence;

    // 3. Merging with Context (Checking Expiry FIRST)
    final isExpired = isContextExpired(_context);
    Intent activeIntent = intent;
    if (intent == Intent.unknown && _context.lastIntent != null && confidence < 0.3 && !isExpired) {
        activeIntent = _context.lastIntent!;
    }

    // 4 & 5. Data & Anomaly Engine
    final severity = detectAnomaly(data);

    // Topic Modifier detection (e.g. least vs most, dark vs light, daily vs monthly)
    String? topicModifier;
    final lowerMsg = query.toLowerCase();
    if (lowerMsg.contains("least") || lowerMsg.contains("less")) {
        topicModifier = "least";
    } else if (activeIntent == Intent.comparison) {
        if (lowerMsg.contains("yesterday") || lowerMsg.contains("today") || lowerMsg.contains("daily") || lowerMsg.contains("day")) {
            topicModifier = "daily";
        } else if (lowerMsg.contains("week")) {
            topicModifier = "weekly";
        } else {
            topicModifier = "monthly";
        }
    } else if (activeIntent == Intent.themeChange) {
        if (lowerMsg.contains("dark")) topicModifier = "dark";
        else if (lowerMsg.contains("light")) topicModifier = "light";
        else topicModifier = "system";
    } else if (activeIntent == Intent.powerControl) {
        final isOff = lowerMsg.contains("off") || lowerMsg.contains("shutdown") || lowerMsg.contains("disable");
        final isOn = lowerMsg.contains("on") || lowerMsg.contains("enable");
        final state = !isOff; // Default to on if not explicitly off

        bool targetAll = lowerMsg.contains("all") || lowerMsg.contains("everything") ||
            (!lowerMsg.contains("bedroom") && !lowerMsg.contains("living") && !lowerMsg.contains("kitchen"));

        if (targetAll) {
            await energyProvider.toggleRoom('bedroom', state);
            await energyProvider.toggleRoom('living', state);
            await energyProvider.toggleRoom('kitchen', state);
            topicModifier = state ? "all_on" : "all_off";
        } else if (lowerMsg.contains("bedroom")) {
            await energyProvider.toggleRoom('bedroom', state);
            topicModifier = state ? "bedroom_on" : "bedroom_off";
        } else if (lowerMsg.contains("living")) {
            await energyProvider.toggleRoom('living', state);
            topicModifier = state ? "living_on" : "living_off";
        } else if (lowerMsg.contains("kitchen")) {
            await energyProvider.toggleRoom('kitchen', state);
            topicModifier = state ? "kitchen_on" : "kitchen_off";
        }
    }

    // 6. Response Construction & enforce wording limits
    bool hasDomainWord = RegExp(r'(energy|water|power|electricity|electric|bill|usage|consume|unit|kwh|appliance|light|ac|cost|charge|room|kitchen|bedroom|living room)', caseSensitive: false).hasMatch(lowerMsg);

    bool isPattern = lowerMsg.contains("pattern") || lowerMsg.contains("behaviour") || lowerMsg.contains("behavior");
    bool isOptimization = (lowerMsg.contains("reduce") || lowerMsg.contains("save") || lowerMsg.contains("tips") || lowerMsg.contains("optimize") || lowerMsg.contains("optimization")) && hasDomainWord;
    bool isSimulation = (lowerMsg.contains("what if") || lowerMsg.contains("reduce by") || lowerMsg.contains("simulate")) && hasDomainWord;
    bool isPrediction = (lowerMsg.contains("predict") || lowerMsg.contains("future"));

    String? currentTopic;

    // CONTEXT AWARENESS: Checking previous queries
    if (!isPattern && !isOptimization && !isSimulation && !isPrediction && !isExpired) {
      if (_context.lastTopic == "simulation" && (lowerMsg.contains("%") || lowerMsg.contains("percent") || RegExp(r'\d+').hasMatch(lowerMsg))) {
         isSimulation = true;
      } else if (_context.lastTopic == "pattern" && (lowerMsg.contains("what about") || lowerMsg.contains("and"))) {
         isPattern = true;
      }
    }

    String text;
    bool isWaterQuery = lowerMsg.contains("water") || lowerMsg.contains("liters") || lowerMsg.contains("lpm") || lowerMsg.contains("tank") || lowerMsg.contains("drain");

    if (activeIntent == Intent.unknown && !hasDomainWord && !isPattern && !isOptimization && !isSimulation && !isPrediction) {
        text = "I only answer questions related to your electricity and water usage. How can I help you manage your consumption today?";
    } else if (isPattern) {
        text = handleUsagePatternQuery();
        currentTopic = "pattern";
    } else if (isOptimization) {
        text = handleOptimizationQuery();
        currentTopic = "optimization";
    } else if (isSimulation) {
        text = handleSimulationQuery(lowerMsg);
        currentTopic = "simulation";
    } else if (isPrediction) {
        text = handlePredictionQuery();
        currentTopic = "prediction";
    } else {
        if (isWaterQuery) {
            final wData = waterProvider.waterMetrics;
            if (wData != null) {
                text = buildWaterResponse(
                  activeIntent,
                  confidence,
                  severity,
                  wData,
                  timeRef ?? _context.lastTimeReference,
                  topicModifier,
                );
            } else {
                text = "Water analytics are currently unavailable.";
            }
        } else {
            text = buildResponse(
              activeIntent,
              confidence,
              severity,
              data,
              timeRef ?? _context.lastTimeReference,
              topicModifier,
            );
        }
    }

    text = trimToWordLimit(text, 75);

    // 7. Suggestions
    final suggestions = generateSuggestions(
      intent: activeIntent,
      severity: severity,
      data: data,
    );

    // 8. Update context
    _context = updateContext(_context, activeIntent, timeRef);
    if (currentTopic != null) {
      _context.lastTopic = currentTopic;
    }

    String? action;
    if (activeIntent == Intent.themeChange) {
      if (topicModifier == "dark") action = "set_dark_mode";
      else if (topicModifier == "light") action = "set_light_mode";
      else action = "set_system_theme";
    }

    // 9. Structured output (and App Logic side-effects)
    final response = AssistantResponse(
      text: text,
      intent: activeIntent,
      confidence: confidence,
      severity: severity,
      suggestions: suggestions,
      action: action,
    );

    // Messages array updating
    final userMsg = ChatMessage(id: DateTime.now().millisecondsSinceEpoch.toString(), sender: 'user', text: query);
    final aiMsg = ChatMessage(id: (DateTime.now().millisecondsSinceEpoch + 1).toString(), sender: 'ai', text: text, responseMeta: response);

    _messages.add(userMsg);
    _messages.add(aiMsg);

    // Trigger App Side effects
    if (action == "set_dark_mode") themeProvider.setTheme(ThemeMode.dark);
    if (action == "set_light_mode") themeProvider.setTheme(ThemeMode.light);
    if (action == "set_system_theme") themeProvider.setTheme(ThemeMode.system);

    _state = 'idle';
    notifyListeners();

    // Use VoiceService to speak the response
    await _voiceService.speak(text);
  }
}




