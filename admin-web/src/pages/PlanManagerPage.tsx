import dayjs from 'dayjs';
import { doc, setDoc } from 'firebase/firestore';
import { useState } from 'react';
import { db } from '../firebase';
import { validatePlanPayload } from '../planValidation';

export function PlanManagerPage() {
  const [dateYmd, setDateYmd] = useState(() => dayjs().format('YYYY-MM-DD'));
  const [jsonText, setJsonText] = useState('');
  const [validationErrors, setValidationErrors] = useState<string[] | null>(null);
  const [uploadError, setUploadError] = useState<string | null>(null);
  const [uploadOk, setUploadOk] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);

  function onValidate() {
    setUploadError(null);
    setUploadOk(null);
    let parsed: unknown;
    try {
      parsed = JSON.parse(jsonText) as unknown;
    } catch {
      setValidationErrors(['Invalid JSON — check syntax.']);
      return;
    }
    const result = validatePlanPayload(parsed, dateYmd);
    if (!result.ok) {
      setValidationErrors(result.errors);
      return;
    }
    setValidationErrors([]);
  }

  async function onUpload() {
    setUploadError(null);
    setUploadOk(null);
    let parsed: unknown;
    try {
      parsed = JSON.parse(jsonText) as unknown;
    } catch {
      setValidationErrors(['Invalid JSON — check syntax.']);
      return;
    }
    const result = validatePlanPayload(parsed, dateYmd);
    if (!result.ok) {
      setValidationErrors(result.errors);
      return;
    }
    setValidationErrors(null);

    const ok = window.confirm(
      `This will overwrite the plan for ${dateYmd}.`,
    );
    if (!ok) return;

    setUploading(true);
    try {
      const payload = result.data as Record<string, unknown>;
      payload.date = dateYmd;
      payload.user_id = 'mohsin';
      await setDoc(doc(db, 'users', 'mohsin', 'plans', dateYmd), payload);
      setUploadOk(`Plan saved to users/mohsin/plans/${dateYmd}`);
    } catch (e: unknown) {
      setUploadError(e instanceof Error ? e.message : 'Upload failed.');
    } finally {
      setUploading(false);
    }
  }

  return (
    <div className="page stack-loose">
      <div className="page-header">
        <h1>Plan manager</h1>
        <p className="muted">
          Upload tomorrow’s (or any) daily plan JSON to{' '}
          <code>users/mohsin/plans/YYYY-MM-DD</code>.
        </p>
      </div>
      <div className="toolbar">
        <label className="field inline">
          <span>Plan date</span>
          <input
            type="date"
            value={dateYmd}
            onChange={(e) => setDateYmd(e.target.value)}
          />
        </label>
      </div>
      <label className="field">
        <span>Plan JSON</span>
        <textarea
          className="json-area"
          value={jsonText}
          onChange={(e) => {
            setJsonText(e.target.value);
            setValidationErrors(null);
          }}
          spellCheck={false}
          placeholder='{"date":"2026-05-02","user_id":"mohsin","sessions":[...]}'
        />
      </label>
      <div className="toolbar">
        <button type="button" className="btn btn-secondary btn-large" onClick={onValidate}>
          Validate JSON
        </button>
        <button
          type="button"
          className="btn btn-primary btn-large"
          onClick={() => void onUpload()}
          disabled={uploading || !jsonText.trim()}
        >
          {uploading ? 'Uploading…' : 'Upload plan'}
        </button>
      </div>
      {validationErrors && validationErrors.length > 0 ? (
        <div className="card error-card">
          <strong>Validation</strong>
          <ul>
            {validationErrors.map((err) => (
              <li key={err}>{err}</li>
            ))}
          </ul>
        </div>
      ) : null}
      {validationErrors && validationErrors.length === 0 ? (
        <p className="success-text">JSON is valid for the selected date and user_id.</p>
      ) : null}
      {validationErrors === null && jsonText.trim() && !uploadError && !uploadOk ? (
        <p className="muted small">
          Click Validate JSON to check structure before upload.
        </p>
      ) : null}
      {uploadError ? <p className="error-text">{uploadError}</p> : null}
      {uploadOk ? <p className="success-text">{uploadOk}</p> : null}
    </div>
  );
}
