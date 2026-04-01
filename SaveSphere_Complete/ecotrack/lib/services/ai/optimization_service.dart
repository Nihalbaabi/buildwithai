/// OptimizationService
/// Generates actionable saving suggestions based on energy/water usage and cost data.

class OptimizationService {
  /// Returns a human-readable saving suggestion.
  ///
  /// [monthlyKwh]     — current month's total energy (kWh)
  /// [lastMonthKwh]   — last month's total energy (kWh)
  /// [currentBillRs]  — estimated bill so far this month (₹)
  /// [monthlyLiters]  — current month's total water usage (L)
  /// [lastMonthLiters]— last month's total water usage (L)
  /// [peakTime]       — detected peak usage time string (e.g. "6 PM to 9 PM")
  String suggest({
    required double monthlyKwh,
    required double lastMonthKwh,
    double currentBillRs = 0,
    double monthlyLiters = 0,
    double lastMonthLiters = 0,
    String peakTime = '',
  }) {
    final energyDelta = monthlyKwh - lastMonthKwh;
    final waterDelta = monthlyLiters - lastMonthLiters;

    // -- Energy increase scenario
    if (energyDelta > 0) {
      final percentIncrease = lastMonthKwh > 0
          ? ((energyDelta / lastMonthKwh) * 100).round()
          : 0;

      // Estimate potential monthly savings at 10% reduction
      final potentialSavings = (currentBillRs * 0.10).round();

      if (peakTime.isNotEmpty) {
        return 'Your energy use is up ${percentIncrease}% from last month. '
            'Shifting heavy appliances away from peak hours ($peakTime) '
            'could save you around ₹$potentialSavings/month.';
      }
      return 'Energy usage rose ${percentIncrease}% compared to last month. '
          'Reducing usage by 10% could save approximately ₹$potentialSavings/month.';
    }

    // -- Water increase scenario
    if (waterDelta > 10) {
      final percentIncrease = lastMonthLiters > 0
          ? ((waterDelta / lastMonthLiters) * 100).round()
          : 0;
      return 'Water usage increased by ${percentIncrease}% compared to last month. '
          'Check for slow leaks or reduce tap-open durations to conserve water.';
    }

    // -- Usage within normal range
    if (monthlyKwh < 50 && monthlyLiters < 500) {
      return 'Great job! Your energy and water usage is well within efficient limits this month. '
          'Keep it up to maintain low bills.';
    }

    // -- High energy but no increase
    if (monthlyKwh > 200) {
      final potentialSavings = (currentBillRs * 0.15).round();
      return 'Your monthly energy consumption is ${monthlyKwh.toStringAsFixed(1)} kWh. '
          'Switching to energy-saving appliances could save around ₹$potentialSavings/month.';
    }

    return 'Your usage looks stable. '
        'Consider setting a monthly budget alert to stay on top of any spikes.';
  }
}
