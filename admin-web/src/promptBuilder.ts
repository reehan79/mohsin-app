import type { AttemptDoc } from './attempts';
import { isHttpUrl } from './attempts';

export function buildChatGptPrompt(
  dateYmd: string,
  attempts: AttemptDoc[],
): string {
  const targetSummary = new Map<string, number>();
  for (const a of attempts) {
    const key = a.target_sound || '(none)';
    targetSummary.set(key, (targetSummary.get(key) || 0) + 1);
  }
  const targetLines = [...targetSummary.entries()]
    .map(([sound, count]) => `- ${sound}: ${count} attempt(s)`)
    .join('\n');

  const audioLines = attempts.map((a, i) => {
    const ref = a.cloud_audio_path?.trim() || '(no audio path yet)';
    const label = isHttpUrl(ref)
      ? ref
      : ref.startsWith('audio/')
        ? `Storage path: ${ref}`
        : ref;
    return `${i + 1}. session=${a.session_id} task="${a.task_text.slice(0, 80)}${a.task_text.length > 80 ? '…' : ''}" rep=${a.repetition_number} status=${a.upload_status} file=${label}`;
  });

  return `You are helping a speech therapist parent review practice data for Mohsin.

Practice date: ${dateYmd}

Target sounds / words (from attempt metadata — count of attempts per target_sound):
${targetLines || '- (no attempts)'}

Audio files available (filenames, storage paths, or download URLs as recorded in the app — parent can attach or fetch these separately):
${audioLines.join('\n')}

Please:
1. Analyze Mohsin's progress for this date based on the metadata above (and any notes the parent adds when pasting this into ChatGPT).
2. Identify weak or inconsistent targets that may need more focus.
3. Suggest a concrete plan for tomorrow (sessions, tasks, repetitions) consistent with the same JSON plan shape the app uses: date, user_id "mohsin", sessions[] with session_id, title, preferred_time, tasks[] with task_id, text, repetitions, instruction. Extra fields like type, language, target_sound are allowed if useful.

Output valid JSON only — no markdown fences, no commentary outside the JSON object.`;
}
