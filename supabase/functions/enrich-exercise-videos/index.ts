// Bulk exercise-video enrichment. For each exercise name, resolves a real,
// embeddable form-tutorial from the YouTube Data API (ids are NEVER AI-invented)
// and caches {name → youtube_id} in the exercise_videos table. Coach/admin only.
//
// Required secrets:  supabase secrets set YOUTUBE_API_KEY=...
// Invoke:  functions.invoke('enrich-exercise-videos',
//            body: { names: ['Romanian Deadlift', ...], force: false })
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const YOUTUBE_API_KEY   = Deno.env.get('YOUTUBE_API_KEY') ?? '';
const SUPABASE_URL      = Deno.env.get('SUPABASE_URL') ?? '';
const SUPABASE_ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
const SERVICE_ROLE_KEY  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

const nameKey = (s: string) => s.trim().toLowerCase();

// Pick the most likely "good form demo" from a few candidates: prefer titles that
// mention the exercise words plus a tutorial signal, else the top relevance hit.
function pickBest(name: string, items: any[]): any | null {
  if (!items.length) return null;
  const words = name.toLowerCase().split(/\s+/).filter((w) => w.length > 2);
  const signal = ['form', 'how to', 'tutorial', 'technique', 'proper'];
  let best: any = null;
  let bestScore = -1;
  for (const it of items) {
    const title = (it?.snippet?.title ?? '').toLowerCase();
    if (!it?.id?.videoId) continue;
    let score = 0;
    for (const w of words) if (title.includes(w)) score += 2;
    for (const s of signal) if (title.includes(s)) score += 1;
    if (score > bestScore) { bestScore = score; best = it; }
  }
  return best ?? items.find((i) => i?.id?.videoId) ?? null;
}

async function resolveVideo(name: string): Promise<
  { youtube_id: string; title: string; channel: string } | null
> {
  const q = encodeURIComponent(`${name} proper form tutorial`);
  const url =
    'https://www.googleapis.com/youtube/v3/search' +
    `?part=snippet&type=video&videoEmbeddable=true&maxResults=3&safeSearch=strict` +
    `&q=${q}&key=${YOUTUBE_API_KEY}`;
  const res = await fetch(url);
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`youtube ${res.status}: ${body.slice(0, 160)}`);
  }
  const data = await res.json();
  const best = pickBest(name, data.items ?? []);
  if (!best?.id?.videoId) return null;
  return {
    youtube_id: best.id.videoId as string,
    title: (best.snippet?.title ?? '') as string,
    channel: (best.snippet?.channelTitle ?? '') as string,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  try {
    // ── Auth: coach/admin only (mirrors enrich-exercise) ──
    const authHeader = req.headers.get('Authorization') ?? '';
    const userDb = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user } } = await userDb.auth.getUser();
    if (!user) return json({ error: 'Unauthorized' }, 401);
    if (!YOUTUBE_API_KEY) return json({ error: 'YouTube not configured (set YOUTUBE_API_KEY)' }, 500);
    if (!SERVICE_ROLE_KEY) return json({ error: 'Server not configured' }, 500);

    const { data: profile } = await userDb
      .from('user_profiles').select('role').eq('id', user.id).single();
    if (!profile || !['coach', 'admin'].includes(profile.role as string)) {
      return json({ error: 'Forbidden' }, 403);
    }

    const body = await req.json() as { names?: string[]; name?: string; force?: boolean };
    const raw = body.names ?? (body.name ? [body.name] : []);
    const force = body.force === true;
    // De-dupe + cap per call to stay well inside the daily YouTube quota
    // (100 units/search, ~10k/day default → ~100 searches).
    const names = [...new Set(raw.map((n) => (n ?? '').trim()).filter(Boolean))].slice(0, 60);
    if (names.length === 0) return json({ error: 'Provide names[]' }, 400);

    const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // Which of these already have a video (so a re-run is cheap unless forced).
    const keys = names.map(nameKey);
    const { data: existing } = await admin
      .from('exercise_videos').select('name_key, youtube_id').in('name_key', keys);
    const have = new Set(
      (existing ?? []).filter((r: any) => r.youtube_id).map((r: any) => r.name_key));

    const results: any[] = [];
    let updated = 0, skipped = 0, failed = 0;

    for (const name of names) {
      const key = nameKey(name);
      if (!force && have.has(key)) { skipped++; results.push({ name, skipped: true }); continue; }
      try {
        const vid = await resolveVideo(name);
        if (!vid) { failed++; results.push({ name, youtube_id: null, error: 'no result' }); continue; }
        const { error } = await admin.from('exercise_videos').upsert({
          name_key: key, name, youtube_id: vid.youtube_id,
          title: vid.title, channel: vid.channel,
          source: 'youtube_search', updated_at: new Date().toISOString(),
        }, { onConflict: 'name_key' });
        if (error) { failed++; results.push({ name, error: error.message }); continue; }
        updated++; results.push({ name, youtube_id: vid.youtube_id, title: vid.title });
      } catch (e) {
        failed++; results.push({ name, error: String(e).slice(0, 160) });
      }
    }

    return json({ processed: names.length, updated, skipped, failed, results });
  } catch (e) {
    console.error('enrich-exercise-videos error:', e);
    return json({ error: String(e).slice(0, 200) }, 500);
  }
});
