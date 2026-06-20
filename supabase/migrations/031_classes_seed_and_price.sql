-- Classes = group sessions (online group calls OR in-person group classes).
-- Additive only: a nullable `price` (the app's FitnessClass model already has it).
ALTER TABLE classes ADD COLUMN IF NOT EXISTS price numeric;

-- Seed the sample group classes as real rows, split across the two coaches
-- (Truck & Julia). Idempotent: skips a row that already exists for that coach.
WITH coaches AS (
  SELECT
    (SELECT id FROM user_profiles
       WHERE lower(trim(first_name)) LIKE 'truck%' OR lower(trim(last_name)) LIKE 'truck%'
       LIMIT 1) AS truck,
    (SELECT id FROM user_profiles
       WHERE lower(trim(first_name)) LIKE 'julia%' OR lower(trim(last_name)) LIKE 'julia%'
       LIMIT 1) AS julia
),
seed (coach_key, title, description, type, location, is_online, meeting_link, mins, cap, hrs, price) AS (
  VALUES
    ('truck','HIIT Cardio Blast','High intensity interval training to torch calories and build endurance. Bring water and a towel!','hiit','Studio A · 120 Market St', false, NULL::text, 45, 20,  26, NULL::numeric),
    ('truck','Full Body Strength','Build lean muscle and strength with compound movements. All levels welcome.','strength','Weight Room · 120 Market St', false, NULL, 60, 15, 42, NULL),
    ('truck','Boxing Fundamentals','Learn boxing basics while getting an amazing full body workout. Gloves provided.','boxing','Boxing Ring · 120 Market St', false, NULL, 60, 10, 50, NULL),
    ('truck','Dance Cardio','Fun high energy dance workout. No experience needed — just good vibes!','dance','Studio A · 120 Market St', false, NULL, 45, 20, 74, NULL),
    ('julia','Morning Yoga Flow','Start your day with intention. Gentle yoga flow focusing on flexibility and mindfulness.','yoga','Online', true, 'https://zoom.us/j/123', 50, 12, 31, NULL),
    ('julia','Pilates Core','Strengthen and tone your core with this challenging pilates session. Mat required.','pilates','Studio B · 120 Market St', false, NULL, 45, 15, 57, NULL),
    ('julia','Nutrition Workshop','Interactive workshop on meal planning, macros and sustainable eating habits with Q&A.','meditation','Online', true, 'https://zoom.us/j/456', 90, 30, 83, NULL)
)
INSERT INTO classes (coach_id, title, description, type, location, is_online, meeting_link,
                     scheduled_at, duration_minutes, max_capacity, current_enrolled, status, price)
SELECT
  CASE s.coach_key WHEN 'truck' THEN c.truck ELSE c.julia END,
  s.title, s.description, s.type, s.location, s.is_online, s.meeting_link,
  now() + (s.hrs || ' hours')::interval,
  s.mins, s.cap, 0, 'scheduled', s.price
FROM seed s CROSS JOIN coaches c
WHERE (CASE s.coach_key WHEN 'truck' THEN c.truck ELSE c.julia END) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM classes x
    WHERE x.title = s.title
      AND x.coach_id = CASE s.coach_key WHEN 'truck' THEN c.truck ELSE c.julia END
  );
