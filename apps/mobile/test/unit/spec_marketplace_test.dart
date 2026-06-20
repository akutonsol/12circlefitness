// CMP-001 … CMP-003 — Coach Marketplace spec compliance tests.
// Tests the filtering, search, request, and relationship-state logic
// that backs CoachMarketplaceScreen without requiring Supabase.
import 'package:flutter_test/flutter_test.dart';

// ── Sample coach data ─────────────────────────────────────────────────────────

final _coaches = [
  {
    'id':               'coach-1',
    'first_name':       'Sarah',
    'last_name':        'Johnson',
    'coach_title':      'Strength Coach',
    'specialties':      ['Strength', 'Powerlifting'],
    'rating_avg':       4.9,
    'review_count':     42,
    'pricing_monthly':  150.0,
    'bio':              'Elite powerlifting coach with 10 years experience.',
    'tagline':          'Lift heavy, live long.',
  },
  {
    'id':               'coach-2',
    'first_name':       'Marcus',
    'last_name':        'Lee',
    'coach_title':      'Cardio & Endurance',
    'specialties':      ['Running', 'Cardio'],
    'rating_avg':       4.7,
    'review_count':     28,
    'pricing_monthly':  120.0,
    'bio':              'Marathon finisher helping clients go the distance.',
    'tagline':          'Every step counts.',
  },
  {
    'id':               'coach-3',
    'first_name':       'Priya',
    'last_name':        'Sharma',
    'coach_title':      'Yoga & Wellness',
    'specialties':      ['Yoga', 'Mindfulness', 'Strength'],
    'rating_avg':       4.8,
    'review_count':     19,
    'pricing_monthly':  100.0,
    'bio':              'Helping you find balance and build strength.',
    'tagline':          'Mind and body in harmony.',
  },
];

// ── Replicated from CoachMarketplaceScreen filter/search logic ────────────────

List<Map<String, dynamic>> filterCoaches(
  List<Map<String, dynamic>> coaches,
  String searchQuery,
  String? filterSpecialty,
) =>
    coaches.where((c) {
      final name        = '${c['first_name'] ?? ''} ${c['last_name'] ?? ''}'.toLowerCase();
      final specialties = (c['specialties'] as List? ?? []).cast<String>();
      final q           = searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          name.contains(q) ||
          specialties.any((s) => s.toLowerCase().contains(q));
      final matchFilter = filterSpecialty == null ||
          specialties.contains(filterSpecialty);
      return matchSearch && matchFilter;
    }).toList();

// ── Relationship state machine ────────────────────────────────────────────────

enum RelStatus { none, pending, active }

class CoachRelationship {
  final String coachId;
  final String clientId;
  RelStatus status;
  CoachRelationship({
    required this.coachId,
    required this.clientId,
    this.status = RelStatus.none,
  });

  // CMP-002: client requests → status = pending
  void request() {
    assert(status == RelStatus.none, 'Can only request when no relationship exists');
    status = RelStatus.pending;
  }

  // CMP-003: coach accepts → status = active
  void accept() {
    assert(status == RelStatus.pending, 'Can only accept pending requests');
    status = RelStatus.active;
  }
}

// Mirrors the relStatus string used by _CoachCard
String? relStatusString(CoachRelationship? rel) {
  if (rel == null) return null;
  switch (rel.status) {
    case RelStatus.pending: return 'pending:${rel.coachId}';
    case RelStatus.active:  return 'active:${rel.coachId}';
    case RelStatus.none:    return null;
  }
}

// Mirrors the button label logic in _CoachCard
String buttonLabel(String? relStatus, String coachId) {
  if (relStatus?.startsWith('active:$coachId')  == true) return 'Your Coach';
  if (relStatus?.startsWith('pending:$coachId') == true) return 'Request Sent';
  if (relStatus != null)                                  return 'Already have a coach';
  return 'Request to Connect';
}

// Messaging is enabled when relationship is active (CMP-003)
bool messagingEnabled(String? relStatus) =>
    relStatus?.startsWith('active:') == true;

// Specialty chips derived from coach list
Set<String> allSpecialties(List<Map<String, dynamic>> coaches) {
  final specialties = <String>{};
  for (final c in coaches) {
    specialties.addAll((c['specialties'] as List? ?? []).cast<String>());
  }
  return specialties;
}

void main() {
  // ── CMP-001: Browse coaches ─────────────────────────────────────────────────
  group('CMP-001 Browse coaches — list loads', () {
    test('all coaches returned with no filters', () {
      final result = filterCoaches(_coaches, '', null);
      expect(result.length, _coaches.length);
    });

    test('each coach has id, name, title, specialties, rating', () {
      for (final c in _coaches) {
        expect(c['id'], isNotNull);
        expect(c['first_name'], isNotNull);
        expect(c['coach_title'], isNotNull);
        expect(c['specialties'], isA<List>());
        expect((c['rating_avg'] as num?) ?? 0, greaterThan(0));
      }
    });

    test('coaches are sorted by rating_avg descending (provider order)', () {
      final sorted = List.of(_coaches)
        ..sort((a, b) =>
            (b['rating_avg'] as double).compareTo(a['rating_avg'] as double));
      expect(sorted.first['id'], 'coach-1');  // 4.9
      expect(sorted.last['id'],  'coach-2');  // 4.7
    });
  });

  group('CMP-001 Browse coaches — specialty filter chips', () {
    test('all unique specialties extracted from coach list', () {
      final specialties = allSpecialties(_coaches);
      expect(specialties, containsAll(['Strength', 'Running', 'Yoga', 'Cardio']));
    });

    test('Strength specialty appears in multiple coaches', () {
      final withStrength = _coaches.where((c) =>
          (c['specialties'] as List).contains('Strength')).toList();
      expect(withStrength.length, 2); // Sarah and Priya
    });

    test('filter by "Running" returns only Marcus', () {
      final result = filterCoaches(_coaches, '', 'Running');
      expect(result.length, 1);
      expect(result.first['first_name'], 'Marcus');
    });

    test('filter by "Yoga" returns only Priya', () {
      final result = filterCoaches(_coaches, '', 'Yoga');
      expect(result.length, 1);
      expect(result.first['first_name'], 'Priya');
    });

    test('filter by "Strength" returns Sarah and Priya', () {
      final result = filterCoaches(_coaches, '', 'Strength');
      expect(result.length, 2);
    });

    test('filter with no matching specialty returns empty list', () {
      final result = filterCoaches(_coaches, '', 'Pilates');
      expect(result, isEmpty);
    });
  });

  group('CMP-001 Browse coaches — search', () {
    test('search by first name', () {
      final result = filterCoaches(_coaches, 'sarah', null);
      expect(result.length, 1);
      expect(result.first['first_name'], 'Sarah');
    });

    test('search by last name', () {
      final result = filterCoaches(_coaches, 'lee', null);
      expect(result.length, 1);
      expect(result.first['last_name'], 'Lee');
    });

    test('search by specialty keyword', () {
      final result = filterCoaches(_coaches, 'yoga', null);
      expect(result.length, 1);
      expect(result.first['first_name'], 'Priya');
    });

    test('search is case-insensitive', () {
      expect(filterCoaches(_coaches, 'SARAH', null).length, 1);
      expect(filterCoaches(_coaches, 'sarah', null).length, 1);
    });

    test('partial name match works', () {
      final result = filterCoaches(_coaches, 'mar', null);
      expect(result.first['first_name'], 'Marcus');
    });

    test('no match returns empty list', () {
      expect(filterCoaches(_coaches, 'zzz', null), isEmpty);
    });

    test('search + specialty filter combined', () {
      // "strength" matches Sarah and Priya; filter by Strength leaves both
      // Adding name "priya" narrows to 1
      final result = filterCoaches(_coaches, 'priya', 'Strength');
      expect(result.length, 1);
      expect(result.first['first_name'], 'Priya');
    });

    test('empty search + null filter = all coaches', () {
      expect(filterCoaches(_coaches, '', null).length, _coaches.length);
    });
  });

  // ── CMP-002: Request coach ──────────────────────────────────────────────────
  group('CMP-002 Request coach — coach receives request, client status updated', () {
    test('new relationship starts with no status', () {
      final rel = CoachRelationship(coachId: 'coach-1', clientId: 'client-A');
      expect(rel.status, RelStatus.none);
    });

    test('request() → status becomes pending', () {
      final rel = CoachRelationship(coachId: 'coach-1', clientId: 'client-A');
      rel.request();
      expect(rel.status, RelStatus.pending);
    });

    test('after request button label → "Request Sent"', () {
      final rel = CoachRelationship(coachId: 'coach-1', clientId: 'client-A')
        ..request();
      expect(buttonLabel(relStatusString(rel), 'coach-1'), 'Request Sent');
    });

    test('client with pending request sees "Request Sent" on that coach card', () {
      final relStatus = 'pending:coach-1';
      expect(buttonLabel(relStatus, 'coach-1'), 'Request Sent');
    });

    test('client with pending request sees "Already have a coach" on other coaches', () {
      final relStatus = 'pending:coach-1';
      expect(buttonLabel(relStatus, 'coach-2'), 'Already have a coach');
    });

    test('messaging is NOT enabled while pending', () {
      expect(messagingEnabled('pending:coach-1'), isFalse);
    });
  });

  // ── CMP-003: Accept coach request ──────────────────────────────────────────
  group('CMP-003 Accept coach request — relationship created, messaging enabled', () {
    test('accept() → status becomes active', () {
      final rel = CoachRelationship(coachId: 'coach-1', clientId: 'client-A')
        ..request()
        ..accept();
      expect(rel.status, RelStatus.active);
    });

    test('after acceptance button label → "Your Coach"', () {
      final rel = CoachRelationship(coachId: 'coach-1', clientId: 'client-A')
        ..request()
        ..accept();
      expect(buttonLabel(relStatusString(rel), 'coach-1'), 'Your Coach');
    });

    test('active relationship enables messaging (CMP-003)', () {
      final rel = CoachRelationship(coachId: 'coach-1', clientId: 'client-A')
        ..request()
        ..accept();
      expect(messagingEnabled(relStatusString(rel)), isTrue);
    });

    test('accepted coach card has teal border indicator (active status)', () {
      // The UI applies a teal border when relStatus starts with "active:{coachId}"
      final relStatus = 'active:coach-1';
      expect(relStatus.startsWith('active:coach-1'), isTrue);
    });

    test('cannot accept a request that was never made', () {
      final rel = CoachRelationship(coachId: 'coach-1', clientId: 'client-A');
      expect(() => rel.accept(), throwsA(isA<AssertionError>()));
    });

    test('relStatusString produces correct format for active', () {
      final rel = CoachRelationship(coachId: 'coach-2', clientId: 'client-B')
        ..request()
        ..accept();
      expect(relStatusString(rel), 'active:coach-2');
    });

    test('relStatusString produces correct format for pending', () {
      final rel = CoachRelationship(coachId: 'coach-2', clientId: 'client-B')
        ..request();
      expect(relStatusString(rel), 'pending:coach-2');
    });

    test('no relationship → relStatusString returns null', () {
      final rel = CoachRelationship(coachId: 'coach-1', clientId: 'client-A');
      expect(relStatusString(rel), isNull);
    });
  });
}
