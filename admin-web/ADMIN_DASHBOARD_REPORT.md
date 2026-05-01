# Parent admin dashboard — implementation report

## 1. What was implemented

- **Vite + React + TypeScript** app under `admin-web/` with plain CSS (`src/styles.css`).
- **Firebase Web SDK** initialization in `src/firebase.ts` (Auth, Firestore, Storage). Config supports `VITE_FIREBASE_*` environment variables with placeholder fallbacks and TODO comments until the real web app config is added.
- **Email / password authentication** (`LoginPage`, `signInWithEmailAndPassword`), **logout**, and **route-style navigation** via in-app view state (no anonymous auth).
- **Recordings** (`RecordingsPage`): date picker (default today), query `users/mohsin/attempts` where `date == selected`, client-side sort by `created_at` descending, table of metadata, **play/download** when `cloud_audio_path` is an HTTPS URL or a **Storage object path** resolved with `getDownloadURL`, **Copy ChatGPT file list** to clipboard, loading and error states.
- **Plan manager** (`PlanManagerPage`): date picker, JSON textarea, **Validate JSON** (required shape for `date`, `user_id`, `sessions`, tasks), confirmation **“This will overwrite the plan for YYYY-MM-DD.”**, **`setDoc`** to `users/mohsin/plans/YYYY-MM-DD` (full document replace). Upload normalizes `date` and `user_id` to the picker value and `mohsin`.
- **Prompt builder** (`PromptBuilderPage`): loads attempts for a date, generates a **ChatGPT analysis prompt** (targets, repetitions metadata, audio paths/URLs, instructions for progress / weak targets / tomorrow’s plan as **valid JSON only**). **Copy prompt** — no OpenAI API calls and no API keys in the frontend.
- **No** mobile app changes, **no** charts, **no** AI API integration.

## 2. How to run locally

```bash
cd admin-web
npm install
npm run dev
```

Open the URL Vite prints (usually `http://localhost:5173`).

Production build:

```bash
npm run build
npm run preview   # optional: serve dist/
```

## 3. Required Firebase setup

**Project:** `mohsin-speech-practice-reehan` (see repo root `.firebaserc`).

1. **Register a web app** in Firebase Console → Project settings → Your apps → Web. Copy the config into either:
   - Environment variables (recommended for CI): create `admin-web/.env.local` (not committed) with:
     - `VITE_FIREBASE_API_KEY`
     - `VITE_FIREBASE_AUTH_DOMAIN`
     - `VITE_FIREBASE_PROJECT_ID`
     - `VITE_FIREBASE_STORAGE_BUCKET`
     - `VITE_FIREBASE_MESSAGING_SENDER_ID`
     - `VITE_FIREBASE_APP_ID`
   - Or edit the fallback values in `src/firebase.ts` (web config is public; **never** commit service account JSON).

2. **Authentication:** Enable **Email/Password** sign-in. Create a **parent/therapist** user in Authentication (or invite via your normal process).

3. **Firestore rules:** The signed-in parent user must be allowed to:
   - **Read** `users/mohsin/attempts/*`
   - **Read/write** `users/mohsin/plans/{date}`  
   Tighten with an email allowlist or custom claims in production.

4. **Storage rules:** Allow the same authenticated user to **read** objects under paths such as `audio/mohsin/**` so `getDownloadURL` succeeds for stored relative paths.

5. **Indexes:** This dashboard queries attempts with `where('date', '==', …)` only (no `orderBy`), so **no composite index** is required for that query. If you later add `orderBy('created_at')` in the same query, create the composite index Firebase suggests.

## 4. Firestore paths used

| Path | Usage |
|------|--------|
| `users/mohsin/attempts` | Collection: list attempts filtered by field `date` (`YYYY-MM-DD`). |
| `users/mohsin/plans/{YYYY-MM-DD}` | Document: daily plan JSON (overwrite on upload). |

Field names align with the Flutter app (snake_case), e.g. `created_at`, `session_id`, `task_text`, `repetition_number`, `target_sound`, `upload_status`, `cloud_audio_path`.

## 5. Storage paths used

| Pattern | Usage |
|---------|--------|
| `audio/mohsin/{YYYY-MM-DD}/{session_id}/{task_id}_rep_{NN}.m4a` | Written by the mobile app; `cloud_audio_path` may store this path or a download URL. |

## 6. How to upload a plan

1. Open **Plan manager**.
2. Set **Plan date** to the document id you want (e.g. tomorrow’s `YYYY-MM-DD`).
3. Paste JSON that includes at least: `date` (must match picker), `user_id` (`mohsin`), `sessions` with `session_id`, `title`, `preferred_time`, `tasks` with `task_id`, `text`, `repetitions`, `instruction`. Extra keys (e.g. `type`, `language`, `target_sound`) are allowed.
4. Click **Validate JSON** and fix any reported errors.
5. Click **Upload plan**, confirm overwrite, then check Firestore for `users/mohsin/plans/{date}`.

## 7. How to download recordings

1. Open **Recordings**, pick the date, wait for the table.
2. If upload completed, **Audio** shows a player and **Download** link. If `cloud_audio_path` is a full URL, it is used directly; if it is a Storage path, the app resolves a temporary download URL.

## 8. Next steps

- Replace Firebase web config placeholders or use `.env.local` for real deployments.
- Harden **Security rules** (allowlist parents, limit writes to `plans` only if desired).
- Optional: lazy-load Firebase modules to reduce main bundle size (Vite may warn about chunk size).
- Optional: add `orderBy('created_at')` server-side after creating the Firestore composite index.
- When you are ready for in-dashboard AI, call a **backend** or Cloud Function — do not put OpenAI keys in the frontend.
