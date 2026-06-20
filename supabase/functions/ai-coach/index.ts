import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const ANTHROPIC_API_KEY = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  try {
    const authHeader = req.headers.get('Authorization') ?? '';

    const userDb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await userDb.auth.getUser();
    if (!user) {
      console.error('Auth error:', authError);
      return json({ error: 'Unauthorized' }, 401);
    }

    const body = await req.json();
    const { message, mode } = body as {
      message: string;
      mode: 'nutrition' | 'workout' | 'checkin_analysis' | 'risk_detection' | 'general';
    };

    const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    const [profileRes, nutritionRes, habitsRes, checkinsRes, workoutsRes] = await Promise.all([
      db.from('user_profiles').select('*').eq('id', user.id).maybeSingle(),
      db.from('client_nutrition_plans').select('*').eq('client_id', user.id).eq('is_active', true).maybeSingle(),
      db.from('client_habits').select('*').eq('client_id', user.id).limit(10),
      db.from('weekly_checkins').select('*').eq('user_id', user.id).order('created_at', { ascending: false }).limit(4),
      db.from('workout_sessions').select('*').eq('user_id', user.id).order('started_at', { ascending: false }).limit(7),
    ]);

    const profile = profileRes.data;
    const nutrition = nutritionRes.data;
    const habits = habitsRes.data ?? [];
    const checkins = checkinsRes.data ?? [];
    const workouts = workoutsRes.data ?? [];

    let systemPrompt = `You are an expert AI fitness coach inside the 12 Circle Fitness app.
You are helpful, motivating, and evidence-based. Keep responses concise (2-4 sentences unless asking for detail).
Always be supportive and never shame the client.

Client Profile:
- Name: ${profile?.first_name ?? 'Client'} ${profile?.last_name ?? ''}
- Goal: ${profile?.fitness_goal ?? 'General fitness'}
- Experience: ${profile?.fitness_level ?? 'Intermediate'}`;

    if (nutrition) {
      systemPrompt += `\n\nCoach-Assigned Nutrition Plan:
- Daily Calories: ${nutrition.calories_target}
- Protein: ${nutrition.protein_g}g | Carbs: ${nutrition.carbs_g}g | Fat: ${nutrition.fat_g}g
- Notes: ${nutrition.notes ?? 'None'}`;
    }

    if (habits.length > 0) {
      systemPrompt += `\n\nAssigned Habits: ${habits.map((h: Record<string, unknown>) => h.name).join(', ')}`;
    }

    if (checkins.length > 0) {
      const latest = checkins[0] as Record<string, unknown>;
      systemPrompt += `\n\nLatest Check-In:
- Weight: ${latest.weight_kg ?? 'Not logged'}kg
- Energy: ${latest.energy_level}/5 | Stress: ${latest.stress_level}/5 | Sleep: ${latest.sleep_hours}hrs
- Compliance: ${latest.compliance_percent ?? '?'}%`;
    }

    const completedWorkouts = workouts.filter((w: Record<string, unknown>) => w.status === 'completed');
    systemPrompt += `\n\nWorkout Activity (last 7 days): ${completedWorkouts.length} completed sessions`;

    if (mode === 'nutrition') {
      systemPrompt += "\n\nYou are in NUTRITION COACH mode. Answer questions about food, macros, meal timing, and diet based on the client's plan.";
    } else if (mode === 'workout') {
      systemPrompt += '\n\nYou are in WORKOUT ASSISTANT mode. Help with exercise form, technique, substitutions, and programming questions.';
    } else if (mode === 'checkin_analysis') {
      systemPrompt += '\n\nAnalyze this client\'s recent check-ins. Format: WINS: ... | FOCUS: ... | RECOMMENDATION: ...';
    } else if (mode === 'risk_detection') {
      systemPrompt += '\n\nIdentify risk factors. Output JSON: { "risk_level": "low/medium/high", "flags": [...], "recommendation": "..." }';
    }

    console.log('Calling Anthropic, key present:', ANTHROPIC_API_KEY.length > 0);

    const anthropicRes = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001',
        max_tokens: 512,
        system: systemPrompt,
        messages: [{ role: 'user', content: message }],
      }),
    });

    if (!anthropicRes.ok) {
      const errText = await anthropicRes.text();
      console.error('Anthropic error:', anthropicRes.status, errText);
      return json({ error: 'AI service error', detail: errText }, 500);
    }

    const aiData = await anthropicRes.json() as { content?: Array<{ text: string }> };
    const reply = aiData.content?.[0]?.text ?? "I'm here to help! Could you rephrase your question?";

    db.from('ai_conversations').insert({
      user_id: user.id,
      mode,
      user_message: message,
      ai_response: reply,
    }).then(() => {}).catch(() => {});

    return json({ reply, mode });

  } catch (err) {
    console.error('ai-coach error:', err);
    return json({ error: String(err) }, 500);
  }
});
