class WeightLog {
  final String id;
  final double weight;
  final String unit;
  final DateTime loggedAt;
  final String? notes;

  WeightLog({
    required this.id,
    required this.weight,
    required this.unit,
    required this.loggedAt,
    this.notes,
  });
}

class BodyMeasurement {
  final String id;
  final DateTime loggedAt;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? thighs;
  final double? arms;
  final double? shoulders;
  final double? calves;
  final String unit;

  BodyMeasurement({
    required this.id,
    required this.loggedAt,
    this.chest,
    this.waist,
    this.hips,
    this.thighs,
    this.arms,
    this.shoulders,
    this.calves,
    required this.unit,
  });
}

class ProgressPhoto {
  final String id;
  final String url;
  final String type;
  final DateTime takenAt;
  final String? notes;

  ProgressPhoto({
    required this.id,
    required this.url,
    required this.type,
    required this.takenAt,
    this.notes,
  });
}
