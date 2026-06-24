/// Curated form guidance per exercise — steps, coaching cues, and common
/// mistakes — keyed by a substring of the exercise name. [youtubeId], when set,
/// is embedded in-app; otherwise the guide offers a "Watch form video" search.
class ExerciseGuide {
  final String? youtubeId;
  final List<String> steps;
  final List<String> cues;
  final List<String> mistakes;
  const ExerciseGuide({
    this.youtubeId,
    this.steps = const [],
    this.cues = const [],
    this.mistakes = const [],
  });
}

/// Returns the best-matching guide for an exercise name, or null.
ExerciseGuide? guideFor(String exerciseName) {
  final n = exerciseName.toLowerCase().trim();
  // Most specific keys first (longer keys win on overlap).
  final keys = _guides.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final k in keys) {
    if (n.contains(k)) return _guides[k];
  }
  return null;
}

const _guides = <String, ExerciseGuide>{
  'barbell squat': ExerciseGuide(
    steps: [
      'Set the bar on your upper traps, hands just outside shoulders.',
      'Unrack, step back, feet shoulder-width, toes slightly out.',
      'Brace your core, break at hips and knees together, sit down between your heels.',
      'Descend until hips are below knee crease, then drive up through mid-foot.',
    ],
    cues: ['Big breath + brace before each rep', 'Knees track over toes', 'Chest up, neutral spine'],
    mistakes: ['Knees caving in', 'Heels lifting', 'Rounding the lower back'],
  ),
  'goblet squat': ExerciseGuide(
    steps: [
      'Hold a dumbbell/kettlebell at chest height, elbows tucked.',
      'Feet shoulder-width, toes slightly out.',
      'Sit straight down between your heels, elbows brushing inside knees.',
      'Drive up through mid-foot to stand tall.',
    ],
    cues: ['Elbows inside knees at the bottom', 'Chest tall', 'Weight on mid-foot'],
    mistakes: ['Leaning forward', 'Rising onto toes', 'Shallow depth'],
  ),
  'bench press': ExerciseGuide(
    steps: [
      'Lie back, eyes under the bar, feet flat, slight arch.',
      'Grip just outside shoulder width, wrists stacked over elbows.',
      'Unrack, lower the bar to mid-chest with elbows ~45°.',
      'Press up and slightly back to lockout.',
    ],
    cues: ['Retract shoulder blades', 'Elbows ~45°, not flared', 'Drive feet into the floor'],
    mistakes: ['Bouncing off the chest', 'Flaring elbows to 90°', 'Lifting hips off the bench'],
  ),
  'overhead press': ExerciseGuide(
    steps: [
      'Bar on front delts, grip just outside shoulders, elbows under the bar.',
      'Brace core and glutes, tuck chin.',
      'Press the bar straight up, moving your head "through the window".',
      'Lock out overhead with biceps by ears, then lower under control.',
    ],
    cues: ['Squeeze glutes — no leaning back', 'Bar travels in a straight line', 'Full lockout overhead'],
    mistakes: ['Over-arching the lower back', 'Pressing the bar forward', 'Half lockouts'],
  ),
  'bent-over row': ExerciseGuide(
    steps: [
      'Hinge at the hips to ~45°, neutral spine, bar hanging at arms length.',
      'Pull the bar to your lower ribs / upper stomach.',
      'Squeeze the shoulder blades, then lower under control.',
    ],
    cues: ['Lead with the elbows', 'Keep the torso angle fixed', 'Squeeze at the top'],
    mistakes: ['Using momentum / jerking', 'Rounding the back', 'Standing up as you pull'],
  ),
  'inverted row': ExerciseGuide(
    steps: [
      'Set a bar at hip height; hang underneath, body straight, heels on the floor.',
      'Pull your chest to the bar, elbows driving back.',
      'Lower slowly to full arm extension.',
    ],
    cues: ['Squeeze glutes — body stays a plank', 'Chest to bar', 'Control the descent'],
    mistakes: ['Sagging hips', 'Partial range of motion', 'Shrugging the shoulders'],
  ),
  'deadlift': ExerciseGuide(
    steps: [
      'Bar over mid-foot, shins ~1 inch away, grip just outside the knees.',
      'Hips back, flat back, chest up, take the slack out of the bar.',
      'Push the floor away, keep the bar against your legs.',
      'Stand tall, then hinge back down under control.',
    ],
    cues: ['Bar stays close to the body', 'Neutral spine throughout', 'Drive through the heels'],
    mistakes: ['Rounding the back', 'Bar drifting forward', 'Hips shooting up first'],
  ),
  'romanian deadlift': ExerciseGuide(
    steps: [
      'Stand tall holding the bar, slight knee bend.',
      'Push hips back, sliding the bar down your thighs.',
      'Feel the hamstring stretch, then drive hips forward to stand.',
    ],
    cues: ['Hips back, not down', 'Soft knees, fixed angle', 'Bar close to the legs'],
    mistakes: ['Bending the knees too much', 'Rounding the back', 'Going too low'],
  ),
  'pull-up': ExerciseGuide(
    steps: [
      'Hang from the bar, hands just outside shoulders.',
      'Pull your chest toward the bar, driving elbows down.',
      'Chin over the bar, then lower to a full hang.',
    ],
    cues: ['Start each rep from a dead hang', 'Drive elbows to the hips', 'Control the way down'],
    mistakes: ['Kipping / swinging', 'Partial range', 'Shrugging at the top'],
  ),
  'push-up': ExerciseGuide(
    steps: [
      'Hands under shoulders, body in a straight line head-to-heels.',
      'Lower until your chest is just above the floor, elbows ~45°.',
      'Press back up, keeping the core braced.',
    ],
    cues: ['Glutes + core tight — no sag', 'Elbows ~45°', 'Full lockout at the top'],
    mistakes: ['Hips sagging or piking', 'Flaring elbows', 'Half reps'],
  ),
  'plank': ExerciseGuide(
    steps: [
      'Forearms under shoulders, body in a straight line.',
      'Brace your abs and squeeze your glutes.',
      'Hold, breathing steadily, without letting the hips drop or rise.',
    ],
    cues: ['Ribs down, glutes squeezed', 'Neutral neck', 'Push the floor away'],
    mistakes: ['Hips sagging', 'Butt too high', 'Holding your breath'],
  ),
  'lat pulldown': ExerciseGuide(
    steps: [
      'Grip just outside shoulders, slight lean back, chest up.',
      'Pull the bar to your upper chest, driving elbows down.',
      'Control the bar back up to a full stretch.',
    ],
    cues: ['Lead with the elbows', 'Squeeze the lats at the bottom', 'No big swinging'],
    mistakes: ['Using momentum', 'Pulling behind the neck', 'Half range'],
  ),
  'leg press': ExerciseGuide(
    steps: [
      'Feet shoulder-width on the platform, back and hips flat against the pad.',
      'Lower until knees reach ~90°.',
      'Press through mid-foot without locking the knees hard.',
    ],
    cues: ['Knees track over toes', 'Lower back stays on the pad', 'Controlled tempo'],
    mistakes: ['Lower back rounding off the pad', 'Knees caving in', 'Locking out aggressively'],
  ),
  'lunge': ExerciseGuide(
    steps: [
      'Step forward into a split stance.',
      'Lower until both knees are ~90°, front shin vertical.',
      'Drive through the front heel back to standing.',
    ],
    cues: ['Torso tall', 'Front knee over mid-foot', 'Control the descent'],
    mistakes: ['Front knee caving in', 'Leaning too far forward', 'Short steps'],
  ),
  'glute bridge': ExerciseGuide(
    steps: [
      'Lie on your back, knees bent, feet flat near your glutes.',
      'Drive through your heels and lift your hips until your body is straight.',
      'Squeeze the glutes hard at the top, then lower under control.',
    ],
    cues: ['Squeeze glutes at the top', 'Ribs down — don\'t over-arch', 'Push through the heels'],
    mistakes: ['Over-arching the lower back', 'Pushing through the toes', 'Not reaching full extension'],
  ),
  'calf raise': ExerciseGuide(
    steps: [
      'Balls of the feet on an edge, heels free.',
      'Rise as high as possible onto the toes.',
      'Lower slowly for a full stretch at the bottom.',
    ],
    cues: ['Full range — big stretch + big squeeze', 'Pause at the top', 'Slow negatives'],
    mistakes: ['Bouncing', 'Short range of motion', 'Rushing the reps'],
  ),
};
