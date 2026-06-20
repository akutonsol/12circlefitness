import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/coach_note_service.dart';

final coachNoteServiceProvider =
    Provider<CoachNoteService>((ref) => CoachNoteService());

final clientNotesProvider =
    FutureProvider.family<List<CoachNote>, String>((ref, clientId) async {
  return ref.watch(coachNoteServiceProvider).getNotes(clientId);
});
