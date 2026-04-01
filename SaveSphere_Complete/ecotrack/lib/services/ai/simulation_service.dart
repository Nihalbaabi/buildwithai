class SimulationResult {
  final double newBill;
  final double savings;
  final double waterSaved;

  const SimulationResult({
    required this.newBill,
    required this.savings,
    required this.waterSaved,
  });
}

class SimulationService {
  /// Simulate reduction in usage
  /// [reductionPercentage] - e.g. 10 for 10%
  /// [currentBillRs] - Current estimated bill 
  /// [currentWaterLiters] - Current water usage
  SimulationResult simulate({
    required double reductionPercentage,
    required double currentBillRs,
    required double currentWaterLiters,
  }) {
    final reductionFraction = reductionPercentage / 100.0;
    
    final savings = currentBillRs * reductionFraction;
    final newBill = currentBillRs - savings;
    final waterSaved = currentWaterLiters * reductionFraction;

    return SimulationResult(
      newBill: newBill,
      savings: savings,
      waterSaved: waterSaved,
    );
  }
}
