import dayjs from 'dayjs';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { fetchAttemptsForDate } from '../attempts';
import { db } from '../firebase';
import { buildChatGptPrompt } from '../promptBuilder';

export function PromptBuilderPage() {
  const [dateYmd, setDateYmd] = useState(() => dayjs().format('YYYY-MM-DD'));
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [copyMsg, setCopyMsg] = useState<string | null>(null);
  const [attempts, setAttempts] = useState<Awaited<
    ReturnType<typeof fetchAttemptsForDate>
  > | null>(null);

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

  const promptText = useMemo(
    () => (attempts ? buildChatGptPrompt(dateYmd, attempts) : ''),
    [attempts, dateYmd],
  );

  async function copyPrompt() {
    if (!promptText) return;
    try {
      await navigator.clipboard.writeText(promptText);
      setCopyMsg('Prompt copied to clipboard.');
    } catch {
      setCopyMsg('Clipboard failed — select text below and copy.');
    }
  }

  return (
    <div className="page stack-loose">
      <div className="page-header">
        <h1>Prompt builder</h1>
        <p className="muted">
          Build a ChatGPT prompt from attempts for a date. No audio is sent from this
          app — paste into ChatGPT yourself.
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
          Reload attempts
        </button>
        <button
          type="button"
          className="btn btn-primary btn-large"
          onClick={() => void copyPrompt()}
          disabled={!promptText}
        >
          Copy prompt to clipboard
        </button>
      </div>
      {copyMsg ? <p className="success-text">{copyMsg}</p> : null}
      {loading ? <p className="muted">Loading…</p> : null}
      {error ? <p className="error-text">{error}</p> : null}
      {!loading && attempts ? (
        <label className="field">
          <span>Generated prompt ({attempts.length} attempt(s))</span>
          <textarea
            className="json-area prompt-area"
            readOnly
            value={promptText}
            spellCheck={false}
          />
        </label>
      ) : null}
    </div>
  );
}
