-- Migration 053: track rest-overrun (idle) time per workout session
--
-- The active workout screen now runs a rest "overtime" alarm: when a rest
-- countdown ends and the client hasn't started the next set, time keeps counting
-- up (siren) until they focus a weight field. That overrun is banked as idle
-- time so we can report active vs idle (wasted) time for the session.

alter table workout_sessions
  add column if not exists idle_seconds int default 0;
