-- ============================================================
-- 12 Circle Fitness — Test Accounts Seed
-- Run in Supabase SQL Editor AFTER running 001_full_ecosystem.sql
--
-- TEST CLIENT:  test@12circle.app  / Test1234!
-- TEST COACH:   coach@12circle.app / Coach1234!
-- ============================================================

-- NOTE: Auth users must be created via Supabase Dashboard → Authentication → Users
-- or via the app's sign-up flow. This script seeds the PROFILE and RELATIONSHIP data
-- once those auth users exist.
--
-- Step 1: Create the two auth users in Supabase Dashboard or via sign-up, note their UUIDs
-- Step 2: Replace the UUIDs below with the actual ones
-- Step 3: Run this script

DO $$
DECLARE
  v_coach_id  uuid := 'f626acd9-f76c-43ca-be4c-54d028ae09db';
  v_client_id uuid := '5470a95f-bcae-4e01-b2be-7c16964fa432';
  v_rel_id    uuid;
  v_program_id uuid;
BEGIN

-- ── Coach Profile ──────────────────────────────────────────────────────────────
INSERT INTO user_profiles (
  id, email, first_name, last_name, role,
  bio, specialties, certifications,
  pricing_monthly, years_experience, rating_avg, review_count,
  onboarding_complete
) VALUES (
  v_coach_id,
  'coach@12circle.app',
  'Alex', 'Coach',
  'coach',
  'NASM-certified trainer with 8 years helping clients build lean muscle and burn fat. Specializing in body recomposition and mindset coaching.',
  ARRAY['Fat Loss', 'Muscle Building', 'Strength Training', 'Nutrition Coaching'],
  ARRAY['NASM-CPT', 'Precision Nutrition Level 1', 'Functional Movement Screen'],
  149.00, 8, 4.9, 47,
  true
) ON CONFLICT (id) DO UPDATE SET
  bio = EXCLUDED.bio,
  specialties = EXCLUDED.specialties,
  certifications = EXCLUDED.certifications;

-- ── Client Profile ─────────────────────────────────────────────────────────────
INSERT INTO user_profiles (
  id, email, first_name, last_name, role,
  age, height_cm, current_weight_kg, goal_weight_kg,
  fitness_goal, fitness_level, activity_level,
  training_days_per_week, dietary_restrictions,
  onboarding_complete
) VALUES (
  v_client_id,
  'test@12circle.app',
  'Jordan', 'Test',
  'client',
  28, 175, 82.5, 75.0,
  'fat_loss', 'intermediate', 'moderately_active',
  4, ARRAY[]::text[],
  true
) ON CONFLICT (id) DO UPDATE SET
  fitness_goal = EXCLUDED.fitness_goal,
  current_weight_kg = EXCLUDED.current_weight_kg;

-- ── Active Coach-Client Relationship ──────────────────────────────────────────
INSERT INTO coach_client_relationships (
  coach_id, client_id, status, activated_at, request_message
) VALUES (
  v_coach_id, v_client_id, 'active', NOW(),
  'Test account — pre-approved relationship'
) ON CONFLICT (coach_id, client_id) DO UPDATE SET status = 'active'
RETURNING id INTO v_rel_id;

-- ── Workout Program ────────────────────────────────────────────────────────────
INSERT INTO workout_programs (id, coach_id, name, description, duration_weeks, difficulty)
VALUES (
  gen_random_uuid(), v_coach_id,
  'Summer Shred 8-Week', '4-day split focused on fat loss while preserving muscle', 8, 'intermediate'
) RETURNING id INTO v_program_id;

-- Week 1 workouts
INSERT INTO program_workouts (program_id, week_number, day_of_week, title, exercises) VALUES
  (v_program_id, 1, 1, 'Monday — Upper Push', '[
    {"name":"Bench Press","sets":4,"reps":8,"weight_kg":60,"rest_seconds":90},
    {"name":"Overhead Press","sets":3,"reps":10,"weight_kg":40,"rest_seconds":75},
    {"name":"Incline Dumbbell Press","sets":3,"reps":12,"weight_kg":20,"rest_seconds":60},
    {"name":"Tricep Pushdown","sets":3,"reps":15,"weight_kg":25,"rest_seconds":45},
    {"name":"Lateral Raises","sets":3,"reps":15,"weight_kg":10,"rest_seconds":45}
  ]'::jsonb),
  (v_program_id, 1, 2, 'Tuesday — Lower Pull', '[
    {"name":"Romanian Deadlift","sets":4,"reps":8,"weight_kg":80,"rest_seconds":120},
    {"name":"Leg Curl","sets":3,"reps":12,"weight_kg":40,"rest_seconds":60},
    {"name":"Walking Lunges","sets":3,"reps":20,"weight_kg":20,"rest_seconds":60},
    {"name":"Calf Raises","sets":4,"reps":20,"weight_kg":60,"rest_seconds":45},
    {"name":"Plank","sets":3,"reps":1,"weight_kg":0,"rest_seconds":60}
  ]'::jsonb),
  (v_program_id, 1, 4, 'Thursday — Upper Pull', '[
    {"name":"Pull-Ups","sets":4,"reps":8,"weight_kg":0,"rest_seconds":90},
    {"name":"Barbell Row","sets":4,"reps":8,"weight_kg":60,"rest_seconds":90},
    {"name":"Cable Row","sets":3,"reps":12,"weight_kg":50,"rest_seconds":60},
    {"name":"Face Pulls","sets":3,"reps":15,"weight_kg":20,"rest_seconds":45},
    {"name":"Dumbbell Curl","sets":3,"reps":12,"weight_kg":15,"rest_seconds":45}
  ]'::jsonb),
  (v_program_id, 1, 5, 'Friday — Lower Quad', '[
    {"name":"Back Squat","sets":4,"reps":8,"weight_kg":80,"rest_seconds":120},
    {"name":"Leg Press","sets":3,"reps":12,"weight_kg":120,"rest_seconds":90},
    {"name":"Leg Extension","sets":3,"reps":15,"weight_kg":40,"rest_seconds":60},
    {"name":"Hip Thrust","sets":3,"reps":12,"weight_kg":80,"rest_seconds":75},
    {"name":"Ab Wheel","sets":3,"reps":12,"weight_kg":0,"rest_seconds":45}
  ]'::jsonb);

-- Assign program to client
INSERT INTO workout_program_assignments (
  program_id, client_id, coach_id, status, current_week, start_date
) VALUES (
  v_program_id, v_client_id, v_coach_id, 'active', 1, CURRENT_DATE
) ON CONFLICT DO NOTHING;

-- ── Nutrition Plan ─────────────────────────────────────────────────────────────
INSERT INTO client_nutrition_plans (
  client_id, coach_id, calories_target, protein_g, carbs_g, fat_g,
  notes, is_active
) VALUES (
  v_client_id, v_coach_id,
  2000, 175, 190, 67,
  'High protein to preserve muscle during cut. Carbs around workouts. Track everything.',
  true
) ON CONFLICT DO NOTHING;

-- ── Assigned Habits ────────────────────────────────────────────────────────────
INSERT INTO client_habits (client_id, coach_id, name, emoji, category, target_value, unit) VALUES
  (v_client_id, v_coach_id, '10k Steps', '👟', 'fitness', 10000, 'steps'),
  (v_client_id, v_coach_id, 'Drink 3L Water', '💧', 'health', 3, 'litres'),
  (v_client_id, v_coach_id, 'Sleep 8 Hours', '😴', 'sleep', 8, 'hours'),
  (v_client_id, v_coach_id, '10min Meditation', '🧘', 'mindfulness', 10, 'minutes'),
  (v_client_id, v_coach_id, 'Mobility Routine', '🤸', 'fitness', 1, 'session')
ON CONFLICT DO NOTHING;

-- ── Sample Check-Ins ───────────────────────────────────────────────────────────
INSERT INTO weekly_checkins (
  user_id, coach_id, week_number, week_start_date,
  weight_kg, energy_level, stress_level, sleep_hours,
  hunger_level, compliance_percent, notes, created_at
) VALUES
  (v_client_id, v_coach_id, 1, CURRENT_DATE - 14, 82.5, 4, 2, 7.5, 3, 90, 'Feeling great, energy is up. Workouts feel strong.', NOW() - INTERVAL '14 days'),
  (v_client_id, v_coach_id, 2, CURRENT_DATE - 7,  81.8, 3, 3, 7.0, 4, 85, 'Had a stressful week at work but stayed consistent.', NOW() - INTERVAL '7 days'),
  (v_client_id, v_coach_id, 3, CURRENT_DATE,      81.2, 4, 2, 8.0, 3, 92, 'Down 1.3kg this week! Sleep improved a lot.', NOW());

-- ── Sample Daily Scores ────────────────────────────────────────────────────────
INSERT INTO daily_scores (
  user_id, score_date, workout_points, nutrition_points, habits_points, checkin_points, community_points, total_score
) VALUES
  (v_client_id, CURRENT_DATE - 6, 30, 25, 16, 0, 0, 71),
  (v_client_id, CURRENT_DATE - 5, 30, 28, 20, 0, 10, 88),
  (v_client_id, CURRENT_DATE - 4, 0,  24, 12, 0, 0,  36),
  (v_client_id, CURRENT_DATE - 3, 30, 30, 20, 0, 0,  80),
  (v_client_id, CURRENT_DATE - 2, 30, 27, 18, 10, 0, 85),
  (v_client_id, CURRENT_DATE - 1, 30, 30, 20, 0, 10, 90),
  (v_client_id, CURRENT_DATE,     30, 25, 16, 0, 0,  71)
ON CONFLICT (user_id, score_date) DO NOTHING;

-- ── Active Challenge ───────────────────────────────────────────────────────────
WITH ch AS (
  INSERT INTO challenges (coach_id, title, description, type, target_value, unit, status, start_date, end_date, emoji)
  VALUES (v_coach_id, '30-Day Body Recomp', 'Track your daily compliance and build the streak', 'workout', 30, 'workouts', 'active', CURRENT_DATE, CURRENT_DATE + 30, '🔥')
  RETURNING id
)
INSERT INTO challenge_participants (challenge_id, user_id, current_progress)
SELECT id, v_client_id, 6 FROM ch;

RAISE NOTICE 'Test accounts seeded successfully!';
RAISE NOTICE 'Coach UUID: %', v_coach_id;
RAISE NOTICE 'Client UUID: %', v_client_id;
RAISE NOTICE '';
RAISE NOTICE 'IMPORTANT: Replace the UUIDs at the top of this script with real Supabase auth user UUIDs';

END $$;
