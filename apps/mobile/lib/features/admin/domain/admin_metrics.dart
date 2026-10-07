/// V5 §163 — models for the owner-approved Admin metric surfaces
/// (migrations 171–173).
///
/// THE ONE RULE THIS FILE EXISTS TO ENFORCE. Every numeric field is nullable, and
/// nothing in here ever writes `?? 0`. The SQL behind these views deliberately
/// distinguishes three states, and collapsing them in Dart would quietly undo a
/// security property and a governance rule:
///
///   * a **missing row** — the caller holds no capability for the area at all;
///   * a **null column** — the caller is not authorized for *that figure*, which is
///     how METRIC-02 keeps a `Users`-only role from reading the Security-owned
///     sign-in basis (ruling `B-1`);
///   * a **zero** — a real, measured zero.
///
/// `?? 0` turns "you may not see this" and "nothing was recorded" into "the answer
/// is none". For METRIC-02 that would be an indirect disclosure dressed as a
/// number; for METRIC-06 it would fabricate a monetary value the owner's
/// calculation forbids. So the UI asks `isAvailable` and renders the approved `A11`
/// empty state, rather than a confident zero.
library;

/// Why a figure has no value. The UI needs the distinction: one of these is an
/// authorization outcome and the other is an absence of data.
enum MetricAbsence {
  /// The caller lacks the capability that gates this particular figure.
  notAuthorized,

  /// The caller is authorized, but nothing has been recorded or measured.
  notRecorded,
}

/// METRIC-02 · activity on two bases, each gated independently.
class AdminActivityOverview {
  const AdminActivityOverview({
    required this.sessionUsersToday,
    required this.sessionUsersWeek,
    required this.sessionUsersMonth,
    required this.sessionUsersPrevMonth,
    required this.signInUsersToday,
    required this.signInUsersWeek,
    required this.signInUsersMonth,
    required this.signInUsersPrevMonth,
    required this.sessionsToday,
    required this.sessionsMonth,
    required this.dayStart,
    required this.weekStart,
    required this.monthStart,
    required this.windowTimezone,
  });

  final int? sessionUsersToday;
  final int? sessionUsersWeek;
  final int? sessionUsersMonth;
  final int? sessionUsersPrevMonth;

  final int? signInUsersToday;
  final int? signInUsersWeek;
  final int? signInUsersMonth;
  final int? signInUsersPrevMonth;

  /// SESSION COUNTS, not user counts. A member who trains twice in a day is ONE active
  /// user and TWO Sessions, and the approved design shows both — "947 Daily sessions"
  /// beside the DAU figure, which the data contract (:97) calls distinct required
  /// measures. Rendering one as the other would misreport engagement in whichever
  /// direction the population happens to lean.
  final int? sessionsToday;
  final int? sessionsMonth;

  /// The boundaries the figures above were actually computed over, and the timezone
  /// they were computed in. These exist because the data contract (:98) names the
  /// timezone as a sub-question the owner's definition must settle, and it is not
  /// settled. An undisclosed window is an assumption the reader cannot check; a
  /// disclosed one is a fact they can.
  final DateTime? dayStart;
  final DateTime? weekStart;
  final DateTime? monthStart;
  final String? windowTimezone;

  /// The Session basis is gated on `Users·view`.
  bool get hasSessionBasis => sessionUsersToday != null;

  /// The sign-in basis is gated on `Security·view`, because it reads
  /// `audit_events` category `authentication`. A role without it gets null here
  /// and MUST NOT be shown a zero.
  bool get hasSignInBasis => signInUsersToday != null;

  /// Month-on-month delta, or null when the basis is unavailable. Returns null
  /// rather than 0 when the previous month is unknown — an unknown delta and a
  /// flat month are different findings.
  int? get sessionMonthDelta =>
      (sessionUsersMonth == null || sessionUsersPrevMonth == null)
          ? null
          : sessionUsersMonth! - sessionUsersPrevMonth!;

  int? get signInMonthDelta =>
      (signInUsersMonth == null || signInUsersPrevMonth == null)
          ? null
          : signInUsersMonth! - signInUsersPrevMonth!;

  static AdminActivityOverview fromRow(Map<String, dynamic> r) =>
      AdminActivityOverview(
        sessionUsersToday: _int(r['session_users_today']),
        sessionUsersWeek: _int(r['session_users_week']),
        sessionUsersMonth: _int(r['session_users_month']),
        sessionUsersPrevMonth: _int(r['session_users_prev_month']),
        signInUsersToday: _int(r['signin_users_today']),
        signInUsersWeek: _int(r['signin_users_week']),
        signInUsersMonth: _int(r['signin_users_month']),
        signInUsersPrevMonth: _int(r['signin_users_prev_month']),
        sessionsToday: _int(r['sessions_today']),
        sessionsMonth: _int(r['sessions_month']),
        dayStart: _date(r['day_start']),
        weekStart: _date(r['week_start']),
        monthStart: _date(r['month_start']),
        windowTimezone: r['window_timezone'] as String?,
      );
}

/// METRIC-03 + METRIC-17, alongside the role counts from migration 166.
class AdminUserOverview {
  const AdminUserOverview({
    required this.usersTotal,
    required this.clientsTotal,
    required this.coachesTotal,
    required this.vendorsTotal,
    required this.coachesActiveThisMonth,
    required this.coachesNoClientThisMonth,
    required this.age18to30,
    required this.age30to45,
    required this.age45to60,
    required this.ageUnknown,
    required this.ageOutOfRange,
  });

  final int? usersTotal;
  final int? clientsTotal;
  final int? coachesTotal;

  /// METRIC-05 = Option 2: the total only. There is deliberately no
  /// "awaiting approval" sub-count — no approval state machine exists and none
  /// was invented.
  final int? vendorsTotal;

  final int? coachesActiveThisMonth;
  final int? coachesNoClientThisMonth;

  final int? age18to30;
  final int? age30to45;
  final int? age45to60;

  /// METRIC-17 = Option 2: the fourth bucket.
  final int? ageUnknown;

  /// NOT a fifth bucket, and must never be rendered as one. An age of 60 or above
  /// has no ruled bucket; this column carries those rows so the panel reconciles
  /// to [usersTotal] instead of silently dropping people.
  final int? ageOutOfRange;

  /// True when the four approved buckets plus the reconciliation column account
  /// for every user. A false here means the panel is lying about its own total.
  bool get bucketsReconcile {
    final parts = [age18to30, age30to45, age45to60, ageUnknown, ageOutOfRange];
    if (usersTotal == null || parts.any((p) => p == null)) return false;
    return parts.fold<int>(0, (a, p) => a + p!) == usersTotal;
  }

  static AdminUserOverview fromRow(Map<String, dynamic> r) => AdminUserOverview(
        usersTotal: _int(r['users_total']),
        clientsTotal: _int(r['clients_total']),
        coachesTotal: _int(r['coaches_total']),
        vendorsTotal: _int(r['vendors_total']),
        coachesActiveThisMonth: _int(r['coaches_active_this_month']),
        coachesNoClientThisMonth: _int(r['coaches_no_client_this_month']),
        age18to30: _int(r['age_18_30']),
        age30to45: _int(r['age_30_45']),
        age45to60: _int(r['age_45_60']),
        ageUnknown: _int(r['age_unknown']),
        ageOutOfRange: _int(r['age_out_of_range']),
      );
}

/// METRIC-14 · attendance, over the pre-existing `checked_in_at`.
class AdminEventsOverview {
  const AdminEventsOverview({
    required this.eventsTotal,
    required this.registrationsTotal,
    required this.registrationsAttended,
    required this.attendanceRatePct,
    required this.registrations30d,
  });

  final int? eventsTotal;
  final int? registrationsTotal;
  final int? registrationsAttended;

  /// Null when there is nothing to divide. The card renders `A11`, never `0%` —
  /// "no registrations" and "nobody turned up" are different statements.
  final double? attendanceRatePct;

  final int? registrations30d;

  static AdminEventsOverview fromRow(Map<String, dynamic> r) =>
      AdminEventsOverview(
        eventsTotal: _int(r['events_total']),
        registrationsTotal: _int(r['event_registrations_total']),
        registrationsAttended: _int(r['event_registrations_attended']),
        attendanceRatePct: _double(r['event_attendance_rate_pct']),
        registrations30d: _int(r['event_registrations_30d']),
      );
}

/// METRIC-13 · "pods" means `accountability_pods`.
class AdminCommunityOverview {
  const AdminCommunityOverview({
    required this.podsTotal,
    required this.podsActive,
    required this.communityGroupsTotal,
    required this.postsTotal,
    required this.postsVisible,
    required this.reportsOpen,
  });

  final int? podsTotal;
  final int? podsActive;

  /// Reported beside the pod count and never merged into it — they are different
  /// units and the design names them separately.
  final int? communityGroupsTotal;

  final int? postsTotal;
  final int? postsVisible;
  final int? reportsOpen;

  static AdminCommunityOverview fromRow(Map<String, dynamic> r) =>
      AdminCommunityOverview(
        podsTotal: _int(r['pods_total']),
        podsActive: _int(r['pods_active']),
        communityGroupsTotal: _int(r['community_groups_total']),
        postsTotal: _int(r['posts_total']),
        postsVisible: _int(r['posts_visible']),
        reportsOpen: _int(r['reports_open']),
      );
}

/// METRIC-06a + METRIC-06b · revenue, in the SOURCE currency.
class AdminRevenueOverview {
  const AdminRevenueOverview({
    required this.grossCoachingCents,
    required this.platformCommissionCents,
    required this.netPlatformCents,
    required this.sourceCurrency,
    required this.commissionRateMissing,
    required this.amountMissing,
    required this.excludedNonCoaching,
    required this.fxUsdGbpRate,
    required this.fxAsOf,
    required this.fxSource,
    required this.streams,
    required this.streamOtherCents,
    required this.streamOtherCount,
    required this.paidTotalCents,
    required this.coachPayoutCents,
    required this.platformFeeCents,
    required this.payoutMissing,
  });

  final int? grossCoachingCents;
  final int? platformCommissionCents;
  final int? netPlatformCents;

  /// The currency the three figures above are actually denominated in.
  final String? sourceCurrency;

  /// Qualifying coaching payments whose `commission_rate` was never recorded.
  /// They ARE in gross and are NOT in commission, because no rate was
  /// substituted onto them. A non-zero value here means the commission figure is
  /// a floor, not a total — the UI must say so rather than imply precision.
  final int? commissionRateMissing;

  final int? amountMissing;
  final int? excludedNonCoaching;

  final double? fxUsdGbpRate;
  final DateTime? fxAsOf;
  final String? fxSource;

  /// Revenue BY STREAM, which the approved design requires on the Dashboard, keyed by
  /// the `create-checkout:52` vocabulary. Kept as a map rather than six fields so the
  /// UI iterates the vocabulary instead of hard-coding it — a seventh stream would
  /// otherwise need a code change in two places to become visible.
  final Map<String, int?> streams;

  /// Revenue whose `kind` is outside that vocabulary. `payments.kind` carries no CHECK
  /// constraint, so this is reachable — and it exists so the named streams plus this
  /// reconcile to [paidTotalCents]. Understating revenue by silently dropping a stream
  /// is the one direction a money figure must never be wrong in by accident.
  final int? streamOtherCents;
  final int? streamOtherCount;
  final int? paidTotalCents;

  /// The money split AS RECORDED (`038:24-25` — "cents to the coach", "cents to
  /// 12 Circle"). Never derived from `amount x commission_rate`: that would invent a
  /// second authority for a figure Stripe already settled.
  final int? coachPayoutCents;
  final int? platformFeeCents;

  /// Coaching payments carrying no recorded split, so the totals above are a floor.
  final int? payoutMissing;

  /// True when every named stream plus `other` accounts for the paid total.
  bool get streamsReconcile {
    if (paidTotalCents == null || streamOtherCents == null) return false;
    var sum = streamOtherCents!;
    for (final v in streams.values) {
      if (v == null) return false;
      sum += v;
    }
    return sum == paidTotalCents;
  }

  /// True when the commission figure accounts for every qualifying payment.
  bool get commissionIsComplete => commissionRateMissing == 0;

  /// An explicitly recorded conversion, or null. THERE IS NO FALLBACK RATE AND
  /// THERE MUST NEVER BE ONE: the owner's calculation says "never fabricate a
  /// monetary value where the underlying source amount is unavailable", and a
  /// hardcoded or remembered rate is exactly that fabrication. Null means the UI
  /// shows the USD source figure, or the `A11` state — not a guess in pounds.
  int? gbpFrom(int? sourceCents) {
    if (sourceCents == null || fxUsdGbpRate == null) return null;
    return (sourceCents * fxUsdGbpRate!).round();
  }

  bool get hasRecordedFx =>
      fxUsdGbpRate != null && fxAsOf != null && fxSource != null;

  static AdminRevenueOverview fromRow(Map<String, dynamic> r) =>
      AdminRevenueOverview(
        grossCoachingCents: _int(r['gross_coaching_cents']),
        platformCommissionCents: _int(r['platform_commission_cents']),
        netPlatformCents: _int(r['net_platform_cents']),
        sourceCurrency: r['source_currency'] as String?,
        commissionRateMissing: _int(r['commission_rate_missing']),
        amountMissing: _int(r['amount_missing']),
        excludedNonCoaching: _int(r['excluded_non_coaching']),
        fxUsdGbpRate: _double(r['fx_usd_gbp_rate']),
        fxAsOf: _date(r['fx_as_of']),
        fxSource: r['fx_source'] as String?,
        streams: {
          for (final k in const [
            'coach', 'coach_plan', 'self_guided', 'ai_guided', 'event_ticket', 'package',
          ])
            k: _int(r['stream_${k}_cents']),
        },
        streamOtherCents: _int(r['stream_other_cents']),
        streamOtherCount: _int(r['stream_other_count']),
        paidTotalCents: _int(r['paid_total_cents']),
        coachPayoutCents: _int(r['coach_payout_cents']),
        platformFeeCents: _int(r['platform_fee_cents']),
        payoutMissing: _int(r['payout_missing']),
      );
}

/// METRIC-11 · the CI verdict and the V5 gate verdict, as two states.
///
/// There is deliberately no combined getter. The owner ruled these "must not be
/// collapsed", and they currently disagree — CI green while the gate ledger
/// records failures. A convenience `bool get isReleasable` would assert a verdict
/// neither authority gave, so none exists.
class AdminReleaseStatus {
  const AdminReleaseStatus({
    required this.releaseVersion,
    required this.environment,
    required this.ciStatus,
    required this.ciChecksPassed,
    required this.ciChecksTotal,
    required this.ciSource,
    required this.ciRecordedAt,
    required this.gateVerdict,
    required this.gatesPass,
    required this.gatesPartial,
    required this.gatesFail,
    required this.gatesTotal,
    required this.gateSource,
    required this.gateRecordedAt,
  });

  final String? releaseVersion;
  final String? environment;

  final String? ciStatus;
  final int? ciChecksPassed;
  final int? ciChecksTotal;
  final String? ciSource;
  final DateTime? ciRecordedAt;

  final String? gateVerdict;
  final int? gatesPass;
  final int? gatesPartial;
  final int? gatesFail;
  final int? gatesTotal;
  final String? gateSource;
  final DateTime? gateRecordedAt;

  /// A verdict is only shown when its source and timestamp came with it — the
  /// same provenance rule the table enforces as a CHECK constraint.
  bool get hasCiVerdict =>
      ciStatus != null && ciSource != null && ciRecordedAt != null;

  bool get hasGateVerdict =>
      gateVerdict != null && gateSource != null && gateRecordedAt != null;

  /// True for the all-NULL row migration 174 returns to an AUTHORIZED caller when
  /// no release has been recorded. It is how a client tells "nothing is recorded"
  /// from "you may not see this" — the latter is no row at all, i.e. a null model.
  /// Without the distinction the card must either claim a permission failure that
  /// did not happen, or report an absence of data to someone who simply lacks the
  /// capability. Both are confident falsehoods.
  bool get isUnrecorded => releaseVersion == null && environment == null;

  static AdminReleaseStatus fromRow(Map<String, dynamic> r) =>
      AdminReleaseStatus(
        releaseVersion: r['release_version'] as String?,
        environment: r['environment'] as String?,
        ciStatus: r['ci_status'] as String?,
        ciChecksPassed: _int(r['ci_checks_passed']),
        ciChecksTotal: _int(r['ci_checks_total']),
        ciSource: r['ci_source'] as String?,
        ciRecordedAt: _date(r['ci_recorded_at']),
        gateVerdict: r['gate_verdict'] as String?,
        gatesPass: _int(r['gates_pass']),
        gatesPartial: _int(r['gates_partial']),
        gatesFail: _int(r['gates_fail']),
        gatesTotal: _int(r['gates_total']),
        gateSource: r['gate_source'] as String?,
        gateRecordedAt: _date(r['gate_recorded_at']),
      );
}

/// `DESIGN-01` §1 — an incident as the Admin layer may see it, from
/// `admin_incidents` (migration 160).
///
/// WHAT THIS MODEL CANNOT CARRY, BY DESIGN. Owner decision `B-4` withholds `evidence`
/// (unbounded free-form, which cannot be shown safe in advance) and `actor_identity`
/// (a DIRECT identity rather than a pseudonym, so an `A12` surface). The view does not
/// project them and this model has no field for them, so no UI can accidentally
/// request one.
class AdminIncident {
  const AdminIncident({
    required this.id,
    required this.summary,
    required this.occurredAt,
    required this.scope,
    required this.severity,
    required this.suspectedCause,
    required this.recommendedAction,
    required this.actionTaken,
    required this.resolution,
  });

  final String? id;
  final String? summary;
  final DateTime? occurredAt;
  final String? scope;

  /// The shipped `A2` scale — `Critical` · `High` · `Warning` · `Informational`,
  /// title case (`143:70`). METRIC-12 confirmed by evidence that an uppercase
  /// `CRITICAL` appears nowhere, so nothing here upper-cases it.
  final String? severity;

  final String? suspectedCause;
  final String? recommendedAction;
  final String? actionTaken;
  final String? resolution;

  bool get isCritical => severity == 'Critical';

  /// True when the item has something to show on open. `DESIGN-01` specifies a single
  /// primary action per item that OPENS it and changes nothing.
  bool get hasDetail =>
      (suspectedCause ?? recommendedAction ?? actionTaken ?? resolution) != null;

  static AdminIncident fromRow(Map<String, dynamic> r) => AdminIncident(
        id: r['id'] as String?,
        summary: r['summary'] as String?,
        occurredAt: _date(r['occurred_at']),
        scope: r['scope'] as String?,
        severity: r['severity'] as String?,
        suspectedCause: r['suspected_cause'] as String?,
        recommendedAction: r['recommended_action'] as String?,
        actionTaken: r['action_taken'] as String?,
        resolution: r['resolution'] as String?,
      );
}

// ── parsing ────────────────────────────────────────────────────────────────
// PostgREST returns bigint and numeric as JSON numbers or strings depending on
// magnitude and type. Each of these returns null for a null or unparseable
// input; none of them defaults to zero.
int? _int(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString());
}

double? _double(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _date(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
