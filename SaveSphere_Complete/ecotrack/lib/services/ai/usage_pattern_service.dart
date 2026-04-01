/// UsagePatternService
/// Analyses energy and water usage values to produce human-readable insights.
/// Operates purely on the data it receives — no external calls.

class UsagePatternAnalysis {
  final String peakHours;
  final String pattern;
  final String weeklyTrend;

  const UsagePatternAnalysis({
    required this.peakHours,
    required this.pattern,
    required this.weeklyTrend,
  });
}

class UsagePatternService {
  /// [energyValues] — ordered list of energy readings (kWh) by hour (index 0–23)
  /// [waterValues]  — ordered list of water readings (L) by hour (index 0–23)
  UsagePatternAnalysis analyse({
    required List<double> energyValues,
    required List<double> waterValues,
  }) {
    final peakHours = _detectPeakHours(energyValues);
    final pattern = _detectPattern(energyValues);
    final weeklyTrend = _detectWeeklyTrend(energyValues, waterValues);

    return UsagePatternAnalysis(
      peakHours: peakHours,
      pattern: pattern,
      weeklyTrend: weeklyTrend,
    );
  }

  // ── Peak Hour Detection ──────────────────────────────────────────────────────
  String _detectPeakHours(List<double> values) {
    if (values.isEmpty) return 'No data available to detect peak hours.';

    double maxVal = 0;
    int peakIndex = 0;
    for (int i = 0; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        peakIndex = i;
      }
    }

    final startHour = peakIndex;
    final endHour = (peakIndex + 2) % 24;
    return '${_formatHour(startHour)} to ${_formatHour(endHour)}';
  }

  // ── Pattern Detection ────────────────────────────────────────────────────────
  String _detectPattern(List<double> values) {
    if (values.isEmpty) return 'Insufficient data to determine usage pattern.';

    // Morning: hours 5–11, Afternoon: 12–17, Evening: 18–23
    double morning = 0, afternoon = 0, evening = 0;

    for (int i = 0; i < values.length && i < 24; i++) {
      if (i >= 5 && i <= 11) morning += values[i];
      if (i >= 12 && i <= 17) afternoon += values[i];
      if (i >= 18 && i <= 23) evening += values[i];
    }

    final max = [morning, afternoon, evening].reduce((a, b) => a > b ? a : b);

    if (max == morning) return 'morning-heavy';
    if (max == afternoon) return 'afternoon-heavy';
    return 'evening-heavy';
  }

  // ── Weekly Trend Detection ───────────────────────────────────────────────────
  String _detectWeeklyTrend(List<double> energy, List<double> water) {
    if (energy.length < 2 && water.length < 2) {
      return 'Not enough data to determine a weekly trend.';
    }

    final energyTotal = energy.fold(0.0, (a, b) => a + b);
    final waterTotal = water.fold(0.0, (a, b) => a + b);

    // Split into two halves — early vs late week
    final energyMid = energy.length ~/ 2;
    final waterMid = water.length ~/ 2;

    final earlyEnergy = energy
        .take(energyMid)
        .fold(0.0, (a, b) => a + b);
    final lateEnergy = energy
        .skip(energyMid)
        .fold(0.0, (a, b) => a + b);

    final earlyWater = water
        .take(waterMid)
        .fold(0.0, (a, b) => a + b);
    final lateWater = water
        .skip(waterMid)
        .fold(0.0, (a, b) => a + b);

    final energyTrend = lateEnergy > earlyEnergy ? 'increasing' : 'decreasing';
    final waterTrend = lateWater > earlyWater ? 'increasing' : 'decreasing';

    if (energyTrend == waterTrend) {
      return 'Both energy and water usage are $energyTrend as the week progresses.';
    }
    return 'Energy usage is $energyTrend while water usage is $waterTrend over the week.';
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}
