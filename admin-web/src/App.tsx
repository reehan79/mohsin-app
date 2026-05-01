import { onAuthStateChanged, type User } from 'firebase/auth';
import { useEffect, useState } from 'react';
import { Layout, type AdminView } from './components/Layout';
import { auth } from './firebase';
import { LoginPage } from './pages/LoginPage';
import { PlanManagerPage } from './pages/PlanManagerPage';
import { PromptBuilderPage } from './pages/PromptBuilderPage';
import { RecordingsPage } from './pages/RecordingsPage';

export default function App() {
  const [user, setUser] = useState<User | null | undefined>(undefined);
  const [view, setView] = useState<AdminView>('recordings');

  useEffect(() => {
    return onAuthStateChanged(auth, (u) => setUser(u));
  }, []);

  if (user === undefined) {
    return (
      <div className="app-loading">
        <p className="muted">Loading…</p>
      </div>
    );
  }

  if (!user) {
    return <LoginPage />;
  }

  return (
    <Layout user={user} view={view} onViewChange={setView}>
      {view === 'recordings' ? <RecordingsPage /> : null}
      {view === 'plan' ? <PlanManagerPage /> : null}
      {view === 'prompt' ? <PromptBuilderPage /> : null}
    </Layout>
  );
}
