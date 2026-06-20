-- Coach can set a daily water target (oz) as part of a client's nutrition plan.
ALTER TABLE client_nutrition_plans ADD COLUMN IF NOT EXISTS water_target_oz int;
