import {
  collection,
  getDocs,
  query,
  where,
  type Firestore,
} from 'firebase/firestore';

export type AttemptDoc = {
  id: string;
  created_at: string;
  session_id: string;
  task_text: string;
  repetition_number: number;
  target_sound: string;
  upload_status: string;
  cloud_audio_path: string | null;
};

function pickString(data: Record<string, unknown>, ...keys: string[]): string {
  for (const k of keys) {
    const v = data[k];
    if (v != null && String(v).length > 0) return String(v);
  }
  return '';
}

function pickNum(data: Record<string, unknown>, ...keys: string[]): number {
  for (const k of keys) {
    const v = data[k];
    if (typeof v === 'number' && !Number.isNaN(v)) return v;
    if (typeof v === 'string' && v.trim() !== '') {
      const n = Number(v);
      if (!Number.isNaN(n)) return n;
    }
  }
  return 0;
}

export async function fetchAttemptsForDate(
  db: Firestore,
  dateYmd: string,
): Promise<AttemptDoc[]> {
  const ref = collection(db, 'users', 'mohsin', 'attempts');
  const q = query(ref, where('date', '==', dateYmd));
  const snap = await getDocs(q);
  const rows: AttemptDoc[] = [];
  snap.forEach((docSnap) => {
    const data = docSnap.data() as Record<string, unknown>;
    const cap = data.cloud_audio_path ?? data.cloudAudioPath;
    rows.push({
      id: docSnap.id,
      created_at: pickString(data, 'created_at', 'createdAt'),
      session_id: pickString(data, 'session_id', 'sessionId'),
      task_text: pickString(data, 'task_text', 'taskText'),
      repetition_number: pickNum(data, 'repetition_number', 'repetitionNumber'),
      target_sound: pickString(data, 'target_sound', 'targetSound'),
      upload_status: pickString(data, 'upload_status', 'uploadStatus'),
      cloud_audio_path:
        cap === null || cap === undefined ? null : String(cap),
    });
  });
  rows.sort((a, b) => {
    const ta = Date.parse(a.created_at) || 0;
    const tb = Date.parse(b.created_at) || 0;
    return tb - ta;
  });
  return rows;
}

export function isHttpUrl(pathOrUrl: string | null | undefined): boolean {
  if (!pathOrUrl) return false;
  return /^https?:\/\//i.test(pathOrUrl.trim());
}
