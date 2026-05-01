import { signOut, type User } from 'firebase/auth';
import type { ReactNode } from 'react';
import { auth } from '../firebase';

export type AdminView = 'recordings' | 'plan' | 'prompt';

type Props = {
  user: User;
  view: AdminView;
  onViewChange: (v: AdminView) => void;
  children: ReactNode;
};

export function Layout({ user, view, onViewChange, children }: Props) {
  return (
    <div className="layout">
      <header className="top-bar">
        <div className="brand">
          <span className="brand-title">Mohsin — Admin</span>
          <span className="muted small">{user.email}</span>
        </div>
        <nav className="nav-tabs" aria-label="Main">
          <button
            type="button"
            className={view === 'recordings' ? 'tab active' : 'tab'}
            onClick={() => onViewChange('recordings')}
          >
            Recordings
          </button>
          <button
            type="button"
            className={view === 'plan' ? 'tab active' : 'tab'}
            onClick={() => onViewChange('plan')}
          >
            Plan manager
          </button>
          <button
            type="button"
            className={view === 'prompt' ? 'tab active' : 'tab'}
            onClick={() => onViewChange('prompt')}
          >
            Prompt builder
          </button>
        </nav>
        <button
          type="button"
          className="btn btn-secondary"
          onClick={() => signOut(auth)}
        >
          Log out
        </button>
      </header>
      <main className="main-content">{children}</main>
    </div>
  );
}
