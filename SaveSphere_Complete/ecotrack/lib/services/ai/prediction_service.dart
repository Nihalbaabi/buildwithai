class PredictionService {
  /// Generate a short prediction string based on current and historical usage
  String predict({
    required double lastMonthKwh,
    required double currentMonthKwh,
    required int daysPassed,
    required int totalDays,
  }) {
    if (daysPassed < 3) {
      return "Need a few more days of data to make an accurate prediction for this month.";
    }

    final dailyAvg = currentMonthKwh / daysPassed;
    final predictedTotal = dailyAvg * totalDays;

    if (lastMonthKwh <= 0) {
      return "Based on your current usage, you're expected to use ${predictedTotal.toStringAsFixed(1)} kWh this month.";
    }

    if (predictedTotal > lastMonthKwh) {
      final increase = ((predictedTotal - lastMonthKwh) / lastMonthKwh) * 100;
      return "Your usage is tracking higher this month. Expect a ${increase.toStringAsFixed(1)}% increase compared to last month.";
    } else {
      final decrease = ((lastMonthKwh - predictedTotal) / lastMonthKwh) * 100;
      return "Great job! You are tracking towards a ${decrease.toStringAsFixed(1)}% decrease in usage compared to last month.";
    }
  }
}
