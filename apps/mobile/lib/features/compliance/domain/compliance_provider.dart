import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/compliance_service.dart';

final complianceServiceProvider =
    Provider<ComplianceService>((ref) => ComplianceService());

/// Coach's active-client adherence roster, worst-first.
final complianceRosterProvider =
    FutureProvider<List<ComplianceSummary>>((ref) async {
  return ref.watch(complianceServiceProvider).getRoster();
});
