export type PlanValidationResult =
  | { ok: true; data: Record<string, unknown> }
  | { ok: false; errors: string[] };

const dateRe = /^\d{4}-\d{2}-\d{2}$/;

export function validatePlanPayload(
  raw: unknown,
  expectedDateYmd: string,
): PlanValidationResult {
  const errors: string[] = [];
  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) {
    return { ok: false, errors: ['Root must be a JSON object.'] };
  }
  const o = raw as Record<string, unknown>;

  if (typeof o.date !== 'string' || !dateRe.test(o.date)) {
    errors.push('Field "date" must be a string YYYY-MM-DD.');
  } else if (o.date !== expectedDateYmd) {
    errors.push(
      `Field "date" (${o.date}) must match selected plan date (${expectedDateYmd}).`,
    );
  }

  if (typeof o.user_id !== 'string' || o.user_id !== 'mohsin') {
    errors.push('Field "user_id" must be the string "mohsin".');
  }

  if (!Array.isArray(o.sessions)) {
    errors.push('Field "sessions" must be an array.');
  } else {
    o.sessions.forEach((sess, si) => {
      const prefix = `sessions[${si}]`;
      if (sess === null || typeof sess !== 'object' || Array.isArray(sess)) {
        errors.push(`${prefix} must be an object.`);
        return;
      }
      const s = sess as Record<string, unknown>;
      for (const key of ['session_id', 'title', 'preferred_time'] as const) {
        if (typeof s[key] !== 'string' || !(s[key] as string).trim()) {
          errors.push(`${prefix}.${key} must be a non-empty string.`);
        }
      }
      if (!Array.isArray(s.tasks)) {
        errors.push(`${prefix}.tasks must be an array.`);
      } else {
        s.tasks.forEach((task, ti) => {
          const tp = `${prefix}.tasks[${ti}]`;
          if (task === null || typeof task !== 'object' || Array.isArray(task)) {
            errors.push(`${tp} must be an object.`);
            return;
          }
          const t = task as Record<string, unknown>;
          if (typeof t.task_id !== 'string' || !t.task_id.trim()) {
            errors.push(`${tp}.task_id must be a non-empty string.`);
          }
          if (typeof t.text !== 'string' || !t.text.trim()) {
            errors.push(`${tp}.text must be a non-empty string.`);
          }
          if (typeof t.instruction !== 'string' || !t.instruction.trim()) {
            errors.push(`${tp}.instruction must be a non-empty string.`);
          }
          const rep = t.repetitions;
          if (typeof rep !== 'number' || !Number.isFinite(rep) || rep < 1) {
            errors.push(`${tp}.repetitions must be a number >= 1.`);
          }
        });
      }
    });
  }

  if (errors.length > 0) return { ok: false, errors };
  return { ok: true, data: o };
}
