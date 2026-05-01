import { getApp, getApps, initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const placeholder = 'TODO_REPLACE_FROM_FIREBASE_CONSOLE';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || placeholder,
  authDomain:
    import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || `${placeholder}.firebaseapp.com`,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || 'mohsin-speech-practice-reehan',
  storageBucket:
    import.meta.env.VITE_FIREBASE_STORAGE_BUCKET ||
    `${placeholder}.appspot.com`,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || placeholder,
  appId: import.meta.env.VITE_FIREBASE_APP_ID || placeholder,
};

// TODO: Replace placeholder values via Firebase Console → Project settings → Your apps → Web app config,
// or set VITE_FIREBASE_* env vars at build time. Never commit service account keys.

const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
export { app };
