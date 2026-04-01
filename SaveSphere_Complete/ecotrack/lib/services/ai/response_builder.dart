import 'dart:math';
import '../../models/energy_models.dart';
import '../../models/water_models.dart';
import '../../models/assistant.dart';
import '../../config/assistant_config.dart';
import '../../utils/analytics.dart';
import '../billing_calculator.dart';

String trimToWordLimit(String text, int maxWords) {
  // We enforce a max of two sentences as requested by the user.
  final RegExp sentenceEnd = RegExp(r'[.!?]+');
  final matches = sentenceEnd.allMatches(text).toList();
  
  if (matches.length <= 2) return text;
  
  // Cut at the end of the second sentence
  final endIndex = matches[1].end;
  return text.substring(0, endIndex).trim();
}

String pickRandomVariant(List<String> variants) {
  final idx = Random().nextInt(variants.length);
  return variants[idx];
}

/// Formats a BucketData-like object's label+total for report listings.
String _formatBucketLine(dynamic bucket) {
  final label = (bucket as BucketData).label;
  final total = bucket.total.toStringAsFixed(2);
  return "$label: ${total} kWh";
}

String buildResponse(
    Intent intent,
    double confidence,
    Severity severity,
    EnergyMetrics data,
    String? timeReference,
    String? contextTopic
) {
  if (intent == Intent.unknown || confidence < AssistantConfig.confidenceThreshold) {
    return pickRandomVariant(AssistantConfig.variants['unknown']!);
  }

  String baseResponse = "";
  final currencySymbol = AssistantConfig.tone['currencySymbol'];

  switch (intent) {
    case Intent.realTime:
      // currentPowerKw is already in kW — display directly, no /1000 needed
      final w = data.currentPowerKw.toStringAsFixed(2);
      final currentBillAmount = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      baseResponse = "Right now, your real-time power usage is $w W. "
          "Your current bill stands at $currencySymbol${currentBillAmount.toStringAsFixed(2)} "
          "for ${data.monthlyTotalKwh.toStringAsFixed(1)} units this month.";
      break;

    case Intent.dailyUsage:
      // currentPowerKw is already in kW — no /1000
      baseResponse = "Total power consumed today is ${data.todayUsageKwh.toStringAsFixed(2)} kWh.";
      if (timeReference == "yesterday") {
        baseResponse += " Yesterday, you used ${data.yesterdayUsageKwh.toStringAsFixed(2)} kWh.";
      } else {
        baseResponse += " Your real-time active load is ${data.currentPowerKw.toStringAsFixed(2)} W.";
      }
      break;

    case Intent.weeklyUsage:
      if (data.weeklyBuckets.isNotEmpty) {
        final buckets = data.weeklyBuckets.cast<BucketData>();
        final lines = buckets.map((b) => "${b.label}: ${b.total.toStringAsFixed(2)} kWh").join(", ");
        baseResponse = "Weekly breakdown: $lines. "
            "Your daily average this month is ${data.dailyAverageKwh.toStringAsFixed(2)} kWh.";
      } else {
        baseResponse = "Your weekly average is about ${data.weeklyAverageKwh.toStringAsFixed(2)} kWh per day.";
      }
      break;

    case Intent.monthlyUsage:
      final currentBillAmount = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      baseResponse = "You've used ${data.monthlyTotalKwh.toStringAsFixed(1)} units this month. "
          "Your current bill is $currencySymbol${currentBillAmount.toStringAsFixed(2)}.";
      break;

    case Intent.currentBill:
      final currentBillAmount = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      baseResponse = "Your estimated bill so far this month is $currencySymbol${currentBillAmount.toStringAsFixed(2)}.";
      break;

    case Intent.billPrediction:
      final dt = DateTime.now();
      final prediction = predictMonthlyBill(data.monthlyTotalKwh, dt.day, getDaysInMonth(dt.year, dt.month), tariff: data.tariff);
      baseResponse = "Your estimated bill for this month is $currencySymbol${prediction.predictedBill.toStringAsFixed(2)}.";
      break;

    case Intent.comparison:
      if (contextTopic == "daily") {
        final diffDaily = data.todayUsageKwh - data.yesterdayUsageKwh;
        if (diffDaily > 0) {
          baseResponse = "Today vs Yesterday: you've used ${diffDaily.toStringAsFixed(2)} MORE kWh today. "
              "(Today: ${data.todayUsageKwh.toStringAsFixed(2)}, Yesterday: ${data.yesterdayUsageKwh.toStringAsFixed(2)} kWh).";
        } else if (diffDaily < 0) {
          baseResponse = "Great job! Today vs Yesterday: you've used ${diffDaily.abs().toStringAsFixed(2)} FEWER kWh today. "
              "(Today: ${data.todayUsageKwh.toStringAsFixed(2)}, Yesterday: ${data.yesterdayUsageKwh.toStringAsFixed(2)} kWh).";
        } else {
          baseResponse = "Your usage today is exactly the same as yesterday: ${data.todayUsageKwh.toStringAsFixed(2)} kWh.";
        }
      } else if (contextTopic == "weekly") {
        baseResponse = "Your daily average this week sits around ${data.dailyAverageKwh.toStringAsFixed(2)} kWh per day. "
            "Check the Analytics tab for detailed trends.";
      } else {
        final diff = data.monthlyTotalKwh - data.lastMonthTotalKwh;
        if (diff > 0) {
          baseResponse = "This month vs last month: you've used ${diff.toStringAsFixed(1)} MORE units this month.";
        } else if (diff < 0) {
          baseResponse = "Great job! You've used ${diff.abs().toStringAsFixed(1)} FEWER units compared to last month.";
        } else {
          baseResponse = "Your usage this month is exactly the same as last month: ${data.monthlyTotalKwh.toStringAsFixed(1)} units.";
        }
      }
      break;

    case Intent.roomComparison:
      final roomsList = [
        {'name': "Bedroom", 'power': data.rooms.bedroomPowerW},
        {'name': "Kitchen", 'power': data.rooms.kitchenPowerW},
        {'name': "Living Room", 'power': data.rooms.livingRoomPowerW}
      ];
      roomsList.sort((a, b) => (b['power'] as double).compareTo(a['power'] as double));
      final highestRoom = roomsList.first;
      final lowestRoom = roomsList.last;

      if (highestRoom['power'] == 0 && lowestRoom['power'] == 0) {
        baseResponse = "Currently, all monitored rooms are drawing zero power.";
      } else if (contextTopic == "least" || contextTopic == "less") {
        baseResponse = "The ${lowestRoom['name']} is consuming the least power: "
            "${(lowestRoom['power'] as double).toStringAsFixed(2)} W.";
      } else {
        baseResponse = "The ${highestRoom['name']} is consuming the most power: "
            "${(highestRoom['power'] as double).toStringAsFixed(2)} W.";
      }
      break;

    case Intent.peakHour:
      if (data.peakTime.isNotEmpty) {
        baseResponse = "Your peak usage is around ${data.peakTime}. "
            "The highest-consuming room is ${data.peakRoom}. "
            "Your busiest day overall is ${data.peakDay}.";
      } else {
        baseResponse = "Not enough data yet to determine your peak timing. "
            "Your busiest day so far has been ${data.peakDay}.";
      }
      break;

    case Intent.zoneDistribution:
      final total = data.roomMonthlyEnergy.values.reduce((a, b) => a + b);
      if (total == 0) {
        baseResponse = "Not enough data to show zone distribution for this month yet.";
      } else {
        final br = ((data.roomMonthlyEnergy['Bedroom'] ?? 0) / total * 100).toStringAsFixed(0);
        final lr = ((data.roomMonthlyEnergy['Living Room'] ?? 0) / total * 100).toStringAsFixed(0);
        final kt = ((data.roomMonthlyEnergy['Kitchen'] ?? 0) / total * 100).toStringAsFixed(0);
        baseResponse = "Zone distribution: Bedroom ($br%), Living Room ($lr%), Kitchen ($kt%). "
            "Total: ${total.toStringAsFixed(1)} units.";
      }
      break;

    case Intent.savingsTips:
      baseResponse = "Here are some energy tips: ";
      break;

    case Intent.themeChange:
      if (contextTopic == "dark") {
        baseResponse = "Switching to dark mode.";
      } else if (contextTopic == "light") {
        baseResponse = "Switching to light mode.";
      } else {
        baseResponse = "Changing display theme.";
      }
      break;
    
    case Intent.powerControl:
      if (contextTopic == "all_on") baseResponse = "Turning on all monitored rooms.";
      else if (contextTopic == "all_off") baseResponse = "Shutting down all monitored rooms.";
      else if (contextTopic == "bedroom_on") baseResponse = "Turning on the bedroom power.";
      else if (contextTopic == "bedroom_off") baseResponse = "Shutting down the bedroom power.";
      else if (contextTopic == "living_on") baseResponse = "Turning on the living room power.";
      else if (contextTopic == "living_off") baseResponse = "Shutting down the living room power.";
      else if (contextTopic == "kitchen_on") baseResponse = "Turning on the kitchen power.";
      else if (contextTopic == "kitchen_off") baseResponse = "Shutting down the kitchen power.";
      else baseResponse = "I've updated the power state for you.";
      break;

    // ── NEW REPORT INTENTS ─────────────────────────────────────────────────

    case Intent.dailyReport:
      final w = data.currentPowerKw.toStringAsFixed(2);
      final br = data.roomMonthlyEnergy['Bedroom'] ?? 0;
      final lr = data.roomMonthlyEnergy['Living Room'] ?? 0;
      final kt = data.roomMonthlyEnergy['Kitchen'] ?? 0;
      final monthBill = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      baseResponse = "Daily Report: "
          "Live load is $w W. "
          "Today's usage is ${data.todayUsageKwh.toStringAsFixed(2)} kWh. "
          "Peak hour is ${data.peakTime.isNotEmpty ? data.peakTime : 'N/A'}. "
          "Monthly total is ${data.monthlyTotalKwh.toStringAsFixed(1)} units "
          "($currencySymbol${monthBill.toStringAsFixed(2)}).";
      break;

    case Intent.weeklyReport:
      String weeklyLines = "";
      if (data.weeklyBuckets.isNotEmpty) {
        final buckets = data.weeklyBuckets.cast<BucketData>();
        weeklyLines = buckets.map((b) => "${b.label}: ${b.total.toStringAsFixed(2)} kWh").join(" | ");
      }
      final avgKwh = data.dailyAverageKwh.toStringAsFixed(2);
      baseResponse = "Weekly Report: $weeklyLines. "
          "Daily average is $avgKwh kWh/day. "
          "Monthly total so far is ${data.monthlyTotalKwh.toStringAsFixed(1)} units.";
      break;

    case Intent.monthlyReport:
      final monthBill = calculateSlabBill(data.monthlyTotalKwh, tariff: data.tariff);
      final dt = DateTime.now();
      final prediction = predictMonthlyBill(data.monthlyTotalKwh, dt.day, getDaysInMonth(dt.year, dt.month), tariff: data.tariff);
      String monthlyLines = "";
      if (data.monthlyBuckets.isNotEmpty) {
        final buckets = data.monthlyBuckets.cast<BucketData>();
        final withData = buckets.where((b) => b.total > 0).toList();
        monthlyLines = withData.map((b) => "${b.label}: ${b.total.toStringAsFixed(1)} kWh").join(" | ");
      }
      baseResponse = "Monthly Report: "
          "${monthlyLines.isNotEmpty ? '$monthlyLines. ' : ''}"
          "This month you used ${data.monthlyTotalKwh.toStringAsFixed(1)} units, "
          "bill is $currencySymbol${monthBill.toStringAsFixed(2)}. "
          "Projected end-of-month is $currencySymbol${prediction.predictedBill.toStringAsFixed(2)}.";
      break;

    case Intent.highestConsumption:
      if (data.monthlyBuckets.isNotEmpty) {
        final buckets = data.monthlyBuckets.cast<BucketData>();
        BucketData peak = buckets.reduce((a, b) => a.total > b.total ? a : b);
        baseResponse = "The highest consuming month is ${peak.label} with "
            "${peak.total.toStringAsFixed(1)} kWh. "
            "This month (current) you've used ${data.monthlyTotalKwh.toStringAsFixed(1)} units.";
      } else {
        baseResponse = "Not enough monthly data yet to compare. "
            "This month you've used ${data.monthlyTotalKwh.toStringAsFixed(1)} units.";
      }
      break;

    case Intent.averageConsumption:
      baseResponse = "Your average daily consumption this month is "
          "${data.dailyAverageKwh.toStringAsFixed(2)} kWh/day. "
          "Weekly average: ${data.weeklyAverageKwh.toStringAsFixed(2)} kWh. "
          "Monthly total: ${data.monthlyTotalKwh.toStringAsFixed(1)} units.";
      break;
    
    case Intent.greeting:
      baseResponse = pickRandomVariant(AssistantConfig.variants['greeting']!);
      break;

    case Intent.thanks:
      baseResponse = pickRandomVariant(AssistantConfig.variants['thanks']!);
      break;

    case Intent.bye:
      baseResponse = pickRandomVariant(AssistantConfig.variants['bye']!);
      break;

    default:
      baseResponse = pickRandomVariant(AssistantConfig.variants['unknown']!);
  }

  return trimToWordLimit(baseResponse, AssistantConfig.tone['maxWords']);
}

String buildWaterResponse(
    Intent intent,
    double confidence,
    Severity severity,
    WaterMetrics data,
    String? timeReference,
    String? contextTopic
) {
  if (intent == Intent.unknown || confidence < AssistantConfig.confidenceThreshold) {
    return pickRandomVariant(AssistantConfig.variants['unknown']!);
  }

  String baseResponse = "";

  switch (intent) {
    case Intent.realTime:
      if (data.outletOn) {
        final flow = data.currentFlowLpm.toStringAsFixed(2);
        baseResponse = "Water is currently draining at $flow L/min. "
            "Your tank level is at ${data.tankLevel.toStringAsFixed(0)} Liters.";
      } else if (data.motorStatus) {
        baseResponse = "The motor is refilling your tank. "
            "Current tank level is ${data.tankLevel.toStringAsFixed(0)} Liters.";
      } else {
        baseResponse = "No water flow right now. "
            "Your tank level is at ${data.tankLevel.toStringAsFixed(0)} Liters.";
      }
      break;

    case Intent.dailyUsage:
      baseResponse = "Total water consumed today is ${data.todayUsageL.toStringAsFixed(0)} Liters.";
      if (timeReference == "yesterday") {
        baseResponse += " Yesterday, you used ${data.yesterdayUsageL.toStringAsFixed(0)} Liters.";
      }
      break;

    case Intent.weeklyUsage:
      baseResponse = "Your weekly average is about ${data.weeklyAverageL.toStringAsFixed(0)} Liters per day.";
      break;

    case Intent.monthlyUsage:
      baseResponse = "You've used ${data.monthlyTotalL.toStringAsFixed(0)} Liters this month.";
      break;
      
    case Intent.comparison:
      if (contextTopic == "daily") {
        final diffDaily = data.todayUsageL - data.yesterdayUsageL;
        if (diffDaily > 0) {
          baseResponse = "Today vs Yesterday: you've used ${diffDaily.toStringAsFixed(0)} MORE Liters today.";
        } else if (diffDaily < 0) {
          baseResponse = "Great job! You've used ${diffDaily.abs().toStringAsFixed(0)} FEWER Liters today.";
        } else {
          baseResponse = "Your usage today is exactly the same as yesterday: ${data.todayUsageL.toStringAsFixed(0)} Liters.";
        }
      } else {
        final diff = data.monthlyTotalL - data.lastMonthTotalL;
        if (diff > 0) {
          baseResponse = "This month vs last month: you've used ${diff.toStringAsFixed(0)} MORE Liters this month.";
        } else if (diff < 0) {
          baseResponse = "Great job! You've used ${diff.abs().toStringAsFixed(0)} FEWER Liters compared to last month.";
        } else {
          baseResponse = "Your usage this month is exactly the same as last month: ${data.monthlyTotalL.toStringAsFixed(0)} Liters.";
        }
      }
      break;

    case Intent.roomComparison:
      final roomsList = [
        {'name': "Bedroom", 'flow': data.rooms.bedroomFlowLpm},
        {'name': "Kitchen", 'flow': data.rooms.kitchenFlowLpm},
        {'name': "Living Room", 'flow': data.rooms.livingRoomFlowLpm}
      ];
      roomsList.sort((a, b) => (b['flow'] as double).compareTo(a['flow'] as double));
      final highestRoom = roomsList.first;
      final lowestRoom = roomsList.last;

      if (highestRoom['flow'] == 0 && lowestRoom['flow'] == 0) {
        baseResponse = "Currently, all monitored sections have zero water flow.";
      } else if (contextTopic == "least" || contextTopic == "less") {
        baseResponse = "The ${lowestRoom['name']} is consuming the least water: "
            "${(lowestRoom['flow'] as double).toStringAsFixed(2)} L/min.";
      } else {
        baseResponse = "The ${highestRoom['name']} is consuming the most water: "
            "${(highestRoom['flow'] as double).toStringAsFixed(2)} L/min.";
      }
      break;

    case Intent.peakHour:
      if (data.peakTime.isNotEmpty) {
        baseResponse = "Your peak water usage is around ${data.peakTime}. "
            "The highest-consuming section is ${data.peakRoom}.";
      } else {
        baseResponse = "Not enough data yet to determine your peak water timing.";
      }
      break;

    case Intent.dailyReport:
      baseResponse = "Daily Water Report: "
          "Live flow is ${data.currentFlowLpm.toStringAsFixed(2)} L/min. "
          "Today's usage is ${data.todayUsageL.toStringAsFixed(0)} Liters. "
          "Monthly total to date is ${data.monthlyTotalL.toStringAsFixed(0)} Liters.";
      break;

    case Intent.weeklyReport:
      baseResponse = "Weekly Water Report: "
          "Daily average is ${data.dailyAverageL.toStringAsFixed(0)} Liters/day. "
          "Weekly average is ${data.weeklyAverageL.toStringAsFixed(0)} Liters.";
      break;

    case Intent.monthlyReport:
      baseResponse = "Monthly Water Report: "
          "This month you used ${data.monthlyTotalL.toStringAsFixed(0)} Liters, "
          "compared to ${data.lastMonthTotalL.toStringAsFixed(0)} Liters last month.";
      break;

    case Intent.averageConsumption:
      // Note: WaterMetrics has dailyAverageL, not dailyAverageKwh
      baseResponse = "Your average daily water consumption is "
          "${data.dailyAverageL.toStringAsFixed(0)} Liters/day.";
      break;

    case Intent.highestConsumption:
      if (data.monthlyBuckets.isNotEmpty) {
        final buckets = data.monthlyBuckets.cast<BucketData>();
        BucketData peak = buckets.reduce((a, b) => a.total > b.total ? a : b);
        baseResponse = "The highest consuming month is ${peak.label} with "
            "${peak.total.toStringAsFixed(1)} Liters. "
            "This month (current) you've used ${data.monthlyTotalL.toStringAsFixed(1)} Liters.";
      } else {
        baseResponse = "Not enough monthly data yet to compare. "
            "This month you've used ${data.monthlyTotalL.toStringAsFixed(1)} Liters.";
      }
      break;

    case Intent.greeting:
      baseResponse = pickRandomVariant(AssistantConfig.variants['greeting']!);
      break;

    case Intent.thanks:
      baseResponse = pickRandomVariant(AssistantConfig.variants['thanks']!);
      break;

    case Intent.bye:
      baseResponse = pickRandomVariant(AssistantConfig.variants['bye']!);
      break;

    case Intent.themeChange:
    case Intent.powerControl:
    case Intent.currentBill:
    case Intent.billPrediction:
    case Intent.zoneDistribution:
    case Intent.savingsTips:
      baseResponse = "I can only answer that related to your electricity usage. Please ask me about electricity for this query.";
      break;

    default:
      baseResponse = "Water analytics for that query are not fully available yet. Try asking about your daily or monthly water usage!";
  }

  return trimToWordLimit(baseResponse, AssistantConfig.tone['maxWords']);
}
