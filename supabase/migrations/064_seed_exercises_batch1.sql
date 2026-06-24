-- Migration 064: seed exercises — batch 1 (10 exercises)
--
-- Platform-wide (global/approved) via seed_exercise() from 063. Idempotent by
-- slug, so re-running updates rather than duplicating. Requires 063.

select public.seed_exercise($j${
  "exercise_name": "Dumbbell Bench Press", "slug": "dumbbell-bench-press",
  "category": "upper_body", "movement_pattern": "horizontal_push",
  "difficulty": "beginner", "exercise_type": "compound",
  "primary_muscles": ["chest"], "secondary_muscles": ["shoulders", "triceps"],
  "equipment_required": ["dumbbells", "bench"],
  "goal_tags": ["muscle_gain", "strength"], "supports_pr_tracking": true
}$j$::jsonb);

select public.seed_exercise($j${
  "exercise_name": "Lat Pulldown", "slug": "lat-pulldown",
  "category": "upper_body", "movement_pattern": "vertical_pull",
  "difficulty": "beginner", "exercise_type": "compound",
  "primary_muscles": ["lats"], "secondary_muscles": ["biceps", "rear_delts"],
  "equipment_required": ["cable_machine"],
  "goal_tags": ["muscle_gain", "strength"], "supports_pr_tracking": true
}$j$::jsonb);

select public.seed_exercise($j${
  "exercise_name": "Seated Cable Row", "slug": "seated-cable-row",
  "category": "upper_body", "movement_pattern": "horizontal_pull",
  "difficulty": "beginner", "exercise_type": "compound",
  "primary_muscles": ["mid_back"], "secondary_muscles": ["biceps", "rear_delts"],
  "equipment_required": ["cable_machine"],
  "goal_tags": ["muscle_gain", "posture"], "supports_pr_tracking": true
}$j$::jsonb);

select public.seed_exercise($j${
  "exercise_name": "Romanian Deadlift", "slug": "romanian-deadlift",
  "category": "lower_body", "movement_pattern": "hinge",
  "difficulty": "intermediate", "exercise_type": "compound",
  "primary_muscles": ["hamstrings", "glutes"], "secondary_muscles": ["lower_back"],
  "equipment_required": ["barbell"],
  "goal_tags": ["strength", "muscle_gain"], "supports_pr_tracking": true
}$j$::jsonb);

select public.seed_exercise($j${
  "exercise_name": "Hip Thrust", "slug": "hip-thrust",
  "category": "lower_body", "movement_pattern": "hip_extension",
  "difficulty": "beginner", "exercise_type": "compound",
  "primary_muscles": ["glutes"], "secondary_muscles": ["hamstrings"],
  "equipment_required": ["barbell", "bench"],
  "goal_tags": ["glute_growth", "strength"], "supports_pr_tracking": true
}$j$::jsonb);

select public.seed_exercise($j${
  "exercise_name": "Walking Lunge", "slug": "walking-lunge",
  "category": "lower_body", "movement_pattern": "unilateral",
  "difficulty": "beginner", "exercise_type": "compound",
  "primary_muscles": ["quadriceps", "glutes"], "secondary_muscles": ["hamstrings"],
  "equipment_required": ["dumbbells"],
  "goal_tags": ["fat_loss", "muscle_gain"], "supports_pr_tracking": true
}$j$::jsonb);

select public.seed_exercise($j${
  "exercise_name": "Shoulder Press", "slug": "shoulder-press",
  "category": "upper_body", "movement_pattern": "vertical_push",
  "difficulty": "beginner", "exercise_type": "compound",
  "primary_muscles": ["shoulders"], "secondary_muscles": ["triceps"],
  "equipment_required": ["dumbbells"],
  "goal_tags": ["strength", "muscle_gain"], "supports_pr_tracking": true
}$j$::jsonb);

select public.seed_exercise($j${
  "exercise_name": "Face Pull", "slug": "face-pull",
  "category": "upper_body", "movement_pattern": "rear_delt",
  "difficulty": "beginner", "exercise_type": "isolation",
  "primary_muscles": ["rear_delts"], "secondary_muscles": ["upper_back"],
  "equipment_required": ["cable_machine"],
  "goal_tags": ["posture", "injury_prevention"], "supports_pr_tracking": false
}$j$::jsonb);

select public.seed_exercise($j${
  "exercise_name": "Plank", "slug": "plank",
  "category": "core", "movement_pattern": "anti_extension",
  "difficulty": "beginner", "exercise_type": "isometric",
  "primary_muscles": ["core"], "secondary_muscles": ["shoulders"],
  "equipment_required": [],
  "goal_tags": ["core_strength"], "supports_pr_tracking": false
}$j$::jsonb);

select public.seed_exercise($j${
  "exercise_name": "Farmers Carry", "slug": "farmers-carry",
  "category": "functional", "movement_pattern": "carry",
  "difficulty": "intermediate", "exercise_type": "functional",
  "primary_muscles": ["grip", "core"], "secondary_muscles": ["traps", "shoulders"],
  "equipment_required": ["dumbbells"],
  "goal_tags": ["hyrox", "functional_fitness"], "supports_pr_tracking": true
}$j$::jsonb);
