import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/progress_service.dart';
import '../data/models/progress_model.dart';

final progressServiceProvider = Provider<ProgressService>((ref) => ProgressService());

final weightLogsProvider = StateProvider<List<WeightLog>>((ref) {
  return ref.watch(progressServiceProvider).getSampleWeightLogs();
});

final measurementsProvider = StateProvider<List<BodyMeasurement>>((ref) {
  return ref.watch(progressServiceProvider).getSampleMeasurements();
});

final selectedProgressTabProvider = StateProvider<int>((ref) => 0);

class WeightLogNotifier extends StateNotifier<List<WeightLog>> {
  WeightLogNotifier(List<WeightLog> initial) : super(initial);

  void addLog(WeightLog log) {
    state = [...state, log]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  void removeLog(String id) {
    state = state.where((l) => l.id != id).toList();
  }
}

final weightLogNotifierProvider = StateNotifierProvider<WeightLogNotifier, List<WeightLog>>((ref) {
  final logs = ref.watch(progressServiceProvider).getSampleWeightLogs();
  return WeightLogNotifier(logs);
});

class MeasurementNotifier extends StateNotifier<List<BodyMeasurement>> {
  MeasurementNotifier(List<BodyMeasurement> initial) : super(initial);

  void addMeasurement(BodyMeasurement measurement) {
    state = [...state, measurement]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }
}

final measurementNotifierProvider = StateNotifierProvider<MeasurementNotifier, List<BodyMeasurement>>((ref) {
  final measurements = ref.watch(progressServiceProvider).getSampleMeasurements();
  return MeasurementNotifier(measurements);
});
