-- Per-day training times: a client can set a different session time for each
-- training day. `day_times` is a JSON map of dayKey -> "HH:mm"
-- (e.g. {"monday":"07:00","thursday":"18:30"}). The single `session_time`
-- stays as the default / fallback for days without a specific time.
ALTER TABLE client_schedules
  ADD COLUMN IF NOT EXISTS day_times jsonb NOT NULL DEFAULT '{}'::jsonb;
