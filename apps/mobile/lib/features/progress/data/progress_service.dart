import 'models/progress_model.dart';

class ProgressService {
  List<WeightLog> getSampleWeightLogs() {
    final now = DateTime.now();
    return [
      WeightLog(id: '1', weight: 72.5, unit: 'kg', loggedAt: now.subtract(const Duration(days: 30))),
      WeightLog(id: '2', weight: 72.1, unit: 'kg', loggedAt: now.subtract(const Duration(days: 27))),
      WeightLog(id: '3', weight: 71.8, unit: 'kg', loggedAt: now.subtract(const Duration(days: 24))),
      WeightLog(id: '4', weight: 71.5, unit: 'kg', loggedAt: now.subtract(const Duration(days: 21))),
      WeightLog(id: '5', weight: 71.9, unit: 'kg', loggedAt: now.subtract(const Duration(days: 18))),
      WeightLog(id: '6', weight: 71.2, unit: 'kg', loggedAt: now.subtract(const Duration(days: 15))),
      WeightLog(id: '7', weight: 70.8, unit: 'kg', loggedAt: now.subtract(const Duration(days: 12))),
      WeightLog(id: '8', weight: 70.5, unit: 'kg', loggedAt: now.subtract(const Duration(days: 9))),
      WeightLog(id: '9', weight: 70.1, unit: 'kg', loggedAt: now.subtract(const Duration(days: 6))),
      WeightLog(id: '10', weight: 69.8, unit: 'kg', loggedAt: now.subtract(const Duration(days: 3))),
      WeightLog(id: '11', weight: 69.5, unit: 'kg', loggedAt: now),
    ];
  }

  List<BodyMeasurement> getSampleMeasurements() {
    final now = DateTime.now();
    return [
      BodyMeasurement(id: '1', loggedAt: now.subtract(const Duration(days: 30)), chest: 89.0, waist: 72.0, hips: 96.0, thighs: 58.0, arms: 30.0, shoulders: 102.0, calves: 36.0, unit: 'cm'),
      BodyMeasurement(id: '2', loggedAt: now.subtract(const Duration(days: 15)), chest: 88.0, waist: 70.5, hips: 94.5, thighs: 57.0, arms: 29.5, shoulders: 101.0, calves: 35.5, unit: 'cm'),
      BodyMeasurement(id: '3', loggedAt: now, chest: 87.0, waist: 69.0, hips: 93.0, thighs: 56.0, arms: 29.0, shoulders: 100.0, calves: 35.0, unit: 'cm'),
    ];
  }

  double getWeightChange(List<WeightLog> logs) {
    if (logs.length < 2) return 0;
    return logs.last.weight - logs.first.weight;
  }

  double getWeightChangePercent(List<WeightLog> logs) {
    if (logs.length < 2) return 0;
    return ((logs.last.weight - logs.first.weight) / logs.first.weight) * 100;
  }
}
