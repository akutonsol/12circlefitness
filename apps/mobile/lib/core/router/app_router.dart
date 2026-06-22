import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/dashboard/presentation/directory_screen.dart';
import '../../features/dashboard/presentation/coach_dashboard_screen.dart';
import '../../features/dashboard/presentation/coach_directory_screen.dart';
import '../../features/checkins/presentation/coach_checkin_review_screen.dart';
import '../../features/workout/presentation/train_hub_screen.dart';
import '../../features/workout/presentation/workout_list_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/intake_flow_screen.dart';
import '../../features/activity/presentation/activity_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/workout/presentation/workout_detail_screen.dart';
import '../../features/workout/presentation/active_workout_screen.dart';
import '../../features/workout/presentation/workout_history_screen.dart';
import '../../features/workout/presentation/exercise_library_screen.dart';
import '../../features/exercise_database/presentation/exercise_database_screen.dart';
import '../../features/exercise_database/presentation/exercise_detail_screen.dart';
import '../../features/nutrition/presentation/nutrition_screen.dart';
import '../../features/nutrition/presentation/nutrition_splash_screen.dart';
import '../../features/nutrition/presentation/meals_dashboard_screen.dart';
import '../../features/nutrition/presentation/food_search_screen.dart';
import '../../features/nutrition/presentation/log_meal_screen.dart';
import '../../features/ai_nutrition/presentation/ai_nutrition_screen.dart';
import '../../features/ai_nutrition/presentation/meal_plan_screen.dart';
import '../../features/ai_nutrition/presentation/grocery_list_screen.dart';
import '../../features/habits/presentation/habit_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/checkins/presentation/checkin_screen.dart';
import '../../features/checkins/presentation/daily_checkin_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/checkins/presentation/checkin_form_screen.dart';
import '../../features/checkins/presentation/checkin_detail_screen.dart';
import '../../features/messaging/presentation/messaging_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/challenges/presentation/challenges_screen.dart';
import '../../features/challenges/presentation/challenge_detail_screen.dart';
import '../../features/action_items/presentation/action_center_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/compliance/presentation/compliance_dashboard_screen.dart';
import '../../features/coach/presentation/program_builder_screen.dart';
import '../../features/coach/presentation/coach_packages_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/exercise_review_screen.dart';
import '../../features/vendor/presentation/vendor_portal_screen.dart';
import '../../features/payments/presentation/upgrade_screen.dart';
import '../../features/payments/presentation/coach_plan_screen.dart';
import '../../features/payments/presentation/coach_payments_screen.dart';
import '../../features/payments/presentation/paywall_gate.dart';
import '../../features/payments/presentation/payment_result_screen.dart';
import '../../features/payments/domain/entitlements.dart';
import '../../features/ai_coach/presentation/ai_coach_screen.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/booking/presentation/booking_handoff_screen.dart';
import '../../features/womens_health/presentation/womens_health_screen.dart';
import '../../features/scoring/presentation/score_screen.dart';
import '../../features/classes/presentation/classes_screen.dart';
import '../../features/classes/presentation/class_detail_screen.dart';
import '../../features/classes/presentation/coach_classes_screen.dart';
import '../../features/classes/presentation/events_screen.dart';
import '../../features/community/presentation/pods/pods_screen.dart';
import '../../features/coach/presentation/coach_business_screen.dart';
import '../../features/coach/presentation/coach_marketplace_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/exercise_database/presentation/create_exercise_screen.dart';
import '../../features/workout/presentation/strength_progression_screen.dart';
import '../../features/workout/presentation/coach_client_workout_screen.dart';
import '../../features/profile/presentation/personal_info_screen.dart';
import '../../features/profile/presentation/notification_preferences_screen.dart';
import '../../features/payments/presentation/manage_subscription_screen.dart';
import '../../features/profile/presentation/integrations_screen.dart';
import '../../features/settings/presentation/privacy_policy_screen.dart';
import '../../features/settings/presentation/terms_of_service_screen.dart';
import '../../features/settings/presentation/help_center_screen.dart';
import 'app_shell.dart';
import '../../features/auth/presentation/reset_password_screen.dart';

/// True while the user is in a password-recovery session (arrived via the email
/// reset link). The router forces them to /reset-password until they set a new
/// password. The reset screen clears it.
final passwordRecoveryNotifier = ValueNotifier<bool>(false);

/// Holds a user-facing message when an OAuth redirect returns an error
/// (e.g. flow_state_already_used, access_denied). Set in main() from the launch
/// URL; the login screen shows it once and clears it. Null = no pending error.
final authErrorNotifier = ValueNotifier<String?>(null);

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _disposed = false;
  late final ProviderSubscription<AsyncValue<AuthState>> _sub;
  _RouterNotifier(this._ref) {
    _sub = _ref.listen(authStateProvider, (prev, next) {
      final hadSession = prev?.valueOrNull?.session != null;
      final hasSession = next.valueOrNull?.session != null;
      // Password-reset link tapped → drive the user to the reset screen.
      if (next.valueOrNull?.event == AuthChangeEvent.passwordRecovery) {
        passwordRecoveryNotifier.value = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) notifyListeners();
        });
        return;
      }
      // Only trigger the router redirect on login — logout is handled
      // by reloadForLogout() (web) or context.go (mobile) in the UI layer,
      // avoiding the ShellRoute nested-navigator disposal assertion.
      if (!hadSession && hasSession) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) notifyListeners();
        });
      }
    });
  }
  @override
  void dispose() { _disposed = true; _sub.close(); super.dispose(); }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: Listenable.merge([notifier, passwordRecoveryNotifier]),
    redirect: (context, state) async {
      final isAuthenticated = Supabase.instance.client.auth.currentSession != null;
      final path = state.matchedLocation;

      // Password recovery takes priority: keep the user on /reset-password
      // until they set a new password (or it's cleared).
      if (passwordRecoveryNotifier.value) {
        return path == '/reset-password' ? null : '/reset-password';
      }

      final isAuthRoute = path == '/login' ||
          path == '/signup' ||
          path == '/forgot-password' ||
          path == '/onboarding' ||
          path == '/intake';

      if (!isAuthenticated && !isAuthRoute) return '/login';

      if (isAuthenticated && isAuthRoute) {
        if (path == '/intake') return null;
        try {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            final profile = await Supabase.instance.client
                .from('user_profiles')
                .select('role, onboarding_complete')
                .eq('id', userId)
                .maybeSingle();
            final role = profile?['role'] as String? ?? 'client';
            // Only send to intake when flag is explicitly false (new account mid-onboarding).
            // null means the field was never set → treat as complete and go to /home.
            final needsOnboarding = profile?['onboarding_complete'] == false;
            if (role == 'coach') return '/coach-dashboard';
            if (role == 'admin') return '/admin-dashboard';
            if (role == 'vendor') return '/vendor-portal';
            return needsOnboarding ? '/intake' : '/home';
          }
        } catch (_) {}
        return '/home';
      }
      return null;
    },
    routes: [
      // ── Auth / onboarding (no shell) ──────────────────────────────────────
      GoRoute(path: '/onboarding',     builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login',          builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup',         builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password',builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(path: '/intake',         builder: (_, __) => const IntakeFlowScreen()),
      GoRoute(path: '/admin-dashboard',builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin-exercise-review', builder: (_, __) => const ExerciseReviewScreen()),
      GoRoute(path: '/vendor-portal',  builder: (_, __) => const VendorPortalScreen()),
      GoRoute(path: '/payment-success',builder: (_, __) => const PaymentResultScreen(success: true)),
      GoRoute(path: '/payment-cancel', builder: (_, __) => const PaymentResultScreen(success: false)),

      // ── App screens (persistent shell with bottom nav) ────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(path: '/home',               builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/activity',           builder: (_, __) => const ActivityScreen()),
          GoRoute(path: '/directory',          builder: (_, __) => const DirectoryScreen()),
          GoRoute(path: '/coach-dashboard',    builder: (_, __) => const CoachDashboardScreen()),
          GoRoute(path: '/coach-directory',    builder: (_, __) => const CoachDirectoryScreen()),
          GoRoute(path: '/coach-checkin-review', builder: (_, __) => const CoachCheckinReviewScreen()),
          GoRoute(path: '/settings',           builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/profile',            builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/train',              builder: (_, __) => const TrainHubScreen()),
          GoRoute(path: '/workouts',           builder: (_, __) => const WorkoutListScreen()),
          GoRoute(path: '/workout-detail',     builder: (_, __) => const WorkoutDetailScreen()),
          GoRoute(path: '/active-workout',     builder: (_, __) => const ActiveWorkoutScreen()),
          GoRoute(path: '/workout-history',    builder: (_, __) => const WorkoutHistoryScreen()),
          GoRoute(path: '/exercise-library',   builder: (_, __) => const ExerciseLibraryScreen()),
          GoRoute(path: '/exercise-database',  builder: (_, __) => const ExerciseDatabaseScreen()),
          GoRoute(path: '/exercise-detail',    builder: (_, __) => const ExerciseDetailScreen()),
          GoRoute(path: '/nutrition',          builder: (_, __) => const PaywallGate(
            required: ClientPlan.selfGuided, featureName: 'Nutrition Tracking', child: NutritionSplashScreen())),
          GoRoute(path: '/meals-dashboard',    builder: (_, __) => const PaywallGate(
            required: ClientPlan.selfGuided, featureName: 'Nutrition Tracking', child: MealsDashboardScreen())),
          GoRoute(path: '/nutrition-overview', builder: (_, __) => const PaywallGate(
            required: ClientPlan.selfGuided, featureName: 'Nutrition Tracking', child: NutritionScreen())),
          GoRoute(path: '/food-search',        builder: (_, __) => const PaywallGate(
            required: ClientPlan.selfGuided, featureName: 'Nutrition Tracking', child: FoodSearchScreen())),
          GoRoute(path: '/log-meal',           builder: (_, __) => const PaywallGate(
            required: ClientPlan.selfGuided, featureName: 'Nutrition Tracking', child: LogMealScreen())),
          GoRoute(path: '/ai-nutrition',       builder: (_, __) => const PaywallGate(
            required: ClientPlan.aiGuided, featureName: 'AI Nutrition', child: AiNutritionScreen())),
          GoRoute(path: '/meal-plan',          builder: (_, __) => const MealPlanScreen()),
          GoRoute(path: '/grocery-list',       builder: (_, __) => const GroceryListScreen()),
          GoRoute(path: '/habits',             builder: (_, __) => const HabitScreen()),
          GoRoute(path: '/progress',           builder: (_, __) => const ProgressScreen()),
          GoRoute(path: '/checkins',           builder: (_, __) => const CheckinScreen()),
          GoRoute(path: '/daily-checkin',      builder: (_, __) => const DailyCheckinScreen()),
          GoRoute(path: '/insights',           builder: (_, __) => const PaywallGate(
            required: ClientPlan.selfGuided, featureName: 'Advanced Analytics', child: InsightsScreen())),
          GoRoute(path: '/appointments',       builder: (_, __) => const PaywallGate(
            required: ClientPlan.coachGuided, featureName: 'Coach Bookings', child: BookingScreen())),
          GoRoute(path: '/checkin-form',       builder: (_, __) => const CheckinFormScreen()),
          GoRoute(path: '/checkin-detail',     builder: (_, __) => const CheckinDetailScreen()),
          GoRoute(path: '/messages',           builder: (_, __) => const PaywallGate(
            required: ClientPlan.coachGuided, featureName: 'Coach Messaging', child: MessagingScreen())),
          GoRoute(path: '/chat',               builder: (_, __) => const PaywallGate(
            required: ClientPlan.coachGuided, featureName: 'Coach Messaging', child: ChatScreen())),
          GoRoute(path: '/community',          builder: (_, __) => const CommunityScreen()),
          GoRoute(path: '/challenges',         builder: (_, __) => const ChallengesScreen()),
          GoRoute(path: '/action-items',       builder: (_, __) => const PaywallGate(
            required: ClientPlan.coachGuided, featureName: 'Action Items', child: ActionCenterScreen())),
          GoRoute(path: '/goals',              builder: (_, __) => const GoalsScreen()),
          GoRoute(path: '/compliance',         builder: (_, __) => const ComplianceDashboardScreen()),
          GoRoute(path: '/program-builder',    builder: (_, __) => const ProgramLibraryScreen()),
          GoRoute(path: '/upgrade',            builder: (_, __) => const UpgradeScreen()),
          GoRoute(path: '/coach-plan',         builder: (_, __) => const CoachPlanScreen()),
          GoRoute(path: '/coach-packages',     builder: (_, __) => const CoachPackagesScreen()),
          GoRoute(path: '/challenge-detail',   builder: (_, __) => const ChallengeDetailScreen()),
          GoRoute(path: '/ai-coach',           builder: (_, __) => const PaywallGate(
            required: ClientPlan.aiGuided, featureName: 'AI Coach', child: AICoachScreen())),
          GoRoute(path: '/book-call',          builder: (_, __) => const PaywallGate(
            required: ClientPlan.coachGuided, featureName: 'Coach Bookings', child: BookingScreen())),
          GoRoute(path: '/booking-handoff',    builder: (_, __) => const BookingHandoffScreen()),
          GoRoute(path: '/womens-health',      builder: (_, __) => const WomensHealthScreen()),
          GoRoute(path: '/score',              builder: (_, __) => const ScoreScreen()),
          GoRoute(path: '/classes',            builder: (_, __) => const ClassesScreen()),
          GoRoute(path: '/coach-classes',      builder: (_, __) => const CoachClassesScreen()),
          GoRoute(path: '/coach-payments',     builder: (_, __) => const CoachPaymentsScreen()),
          GoRoute(path: '/class-detail',       builder: (_, __) => const ClassDetailScreen()),
          GoRoute(path: '/coach',              builder: (_, __) => const TrainHubScreen()),
          GoRoute(path: '/events',             builder: (_, __) => const EventsScreen()),
          GoRoute(path: '/pods',               builder: (_, __) => const PodsScreen()),
          GoRoute(path: '/coach-business',     builder: (_, __) => const CoachBusinessScreen()),
          GoRoute(path: '/coach-marketplace',       builder: (_, __) => const CoachMarketplaceScreen()),
          GoRoute(path: '/notifications',           builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/create-exercise',         builder: (_, __) => const CreateExerciseScreen()),
          GoRoute(path: '/strength-progression',       builder: (_, __) => const StrengthProgressionScreen()),
          GoRoute(path: '/coach-client-workouts',       builder: (_, __) => const CoachClientWorkoutScreen()),
          GoRoute(path: '/personal-info',               builder: (_, __) => const PersonalInfoScreen()),
          GoRoute(path: '/notification-preferences',    builder: (_, __) => const NotificationPreferencesScreen()),
          GoRoute(path: '/subscription',                builder: (_, __) => const ManageSubscriptionScreen()),
          GoRoute(path: '/integrations',                builder: (_, __) => const IntegrationsScreen()),
          GoRoute(path: '/privacy-policy',              builder: (_, __) => const PrivacyPolicyScreen()),
          GoRoute(path: '/terms-of-service',            builder: (_, __) => const TermsOfServiceScreen()),
          GoRoute(path: '/help-center',                 builder: (_, __) => const HelpCenterScreen()),
        ],
      ),
    ],
  );
});
