import dayjs from 'dayjs';
import { getDownloadURL, ref } from 'firebase/storage';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  fetchAttemptsForDate,
  isHttpUrl,
  type AttemptDoc,
} from '../attempts';
import { db, storage } from '../firebase';

function AudioCell({ attempt }: { attempt: AttemptDoc }) {
  const raw = attempt.cloud_audio_path?.trim() || '';
  const [url, setUrl] = useState<string | null>(() =>
    isHttpUrl(raw) ? raw : null,
  );
  const [phase, setPhase] = useState<'idle' | 'loading' | 'error'>(() =>
    !raw ? 'idle' : isHttpUrl(raw) ? 'idle' : 'loading',
  );

  useEffect(() => {
    if (!raw) {
      setUrl(null);
      setPhase('idle');
      return;
    }
    if (isHttpUrl(raw)) {
      setUrl(raw);
      setPhase('idle');
      return;
    }
    let cancelled = false;
    setPhase('loading');
    setUrl(null);
    getDownloadURL(ref(storage, raw))
      .then((u) => {
        if (!cancelled) {
          setUrl(u);
          setPhase('idle');
        }
      })
      .catch(() => {
        if (!cancelled) setPhase('error');
      });
    return () => {
      cancelled = true;
    };
  }, [raw]);

  if (!raw) {
    return <span className="muted">—</span>;
  }
  if (isHttpUrl(raw)) {
    return (
      <div className="audio-cell">
        <audio className="audio-mini" controls preload="metadata" src={raw} />
        <a className="link" href={raw} download>
          Download
        </a>
      </div>
    );
  }
  if (phase === 'loading') {
    return <span className="muted">Resolving URL…</span>;
  }
  if (phase === 'error' || !url) {
    return <span className="error-text">Could not resolve Storage path</span>;
  }
  return (
    <div className="audio-cell">
      <audio className="audio-mini" controls preload="metadata" src={url} />
      <a className="link" href={url} download>
        Download
      </a>
    </div>
  );
}

function buildChatGptFileList(dateYmd: string, attempts: AttemptDoc[]): string {
  const lines = [
    `Practice date: ${dateYmd}`,
    `Total attempts: ${attempts.length}`,
    '',
  ];
  attempts.forEach((a, i) => {
    const cap = a.cloud_audio_path?.trim() || '';
    lines.push(
      `${i + 1}. created_at=${a.created_at} session=${a.session_id} task=${JSON.stringify(a.task_text)} rep=${a.repetition_number} target=${a.target_sound} status=${a.upload_status} file=${cap || '(none)'}`,
    );
  });
  return lines.join('\n');
}

export function RecordingsPage() {
  const [dateYmd, setDateYmd] = useState(() => dayjs().format('YYYY-MM-DD'));
  const [attempts, setAttempts] = useState<AttemptDoc[] | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [copyMsg, setCopyMsg] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    setCopyMsg(null);
    try {
      const rows = await fetchAttemptsForDate(db, dateYmd);
      setAttempts(rows);
    } catch (e: unknown) {
      setAttempts(null);
      setError(e instanceof Error ? e.message : 'Failed to load attempts.');
    } finally {
      setLoading(false);
    }
  }, [dateYmd]);

  useEffect(() => {
    void load();
  }, [load]);

  const fileListText = useMemo(
    () => (attempts ? buildChatGptFileList(dateYmd, attempts) : ''),
    [attempts, dateYmd],
  );

  async function copyFileList() {
    if (!fileListText) return;
    try {
      await navigator.clipboard.writeText(fileListText);
      setCopyMsg('Copied to clipboard.');
    } catch {
      setCopyMsg('Clipboard failed — select and copy manually.');
    }
  }

  return (
    <div className="page stack-loose">
      <div className="page-header">
        <h1>Recordings</h1>
        <p className="muted">
          Attempts in <code>users/mohsin/attempts</code> for the selected date.
        </p>
      </div>
      <div className="toolbar">
        <label className="field inline">
          <span>Date</span>
          <input
            type="date"
            value={dateYmd}
            onChange={(e) => setDateYmd(e.target.value)}
          />
        </label>
        <button type="button" className="btn btn-secondary" onClick={() => void load()}>
          Refresh
        </button>
        <button
          type="button"
          className="btn btn-primary"
          onClick={() => void copyFileList()}
          disabled={!attempts?.length}
        >
          Copy ChatGPT file list
        </button>
      </div>
      {copyMsg ? <p className="success-text">{copyMsg}</p> : null}
      {loading ? <p className="muted">Loading…</p> : null}
      {error ? <p className="error-text">{error}</p> : null}
      {!loading && !error && attempts && (
        <div className="table-wrap">
          <table className="data-table">
            <thead>
              <tr>
                <th>created_at</th>
                <th>session_id</th>
                <th>task_text</th>
                <th>repetition_number</th>
                <th>target_sound</th>
                <th>upload_status</th>
                <th>cloud_audio_path</th>
                <th>Audio</th>
              </tr>
            </thead>
            <tbody>
              {attempts.length === 0 ? (
                <tr>
                  <td colSpan={8} className="muted">
                    No attempts for this date.
                  </td>
                </tr>
              ) : (
                attempts.map((a) => (
                  <tr key={a.id}>
                    <td>{a.created_at}</td>
                    <td>{a.session_id}</td>
                    <td className="cell-clip" title={a.task_text}>
                      {a.task_text}
                    </td>
                    <td>{a.repetition_number}</td>
                    <td>{a.target_sound}</td>
                    <td>{a.upload_status}</td>
                    <td className="cell-clip mono small" title={a.cloud_audio_path || ''}>
                      {a.cloud_audio_path || '—'}
                    </td>
                    <td>
                      <AudioCell attempt={a} />
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
