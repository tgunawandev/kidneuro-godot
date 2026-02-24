import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { User, TokenResponse } from './types';

interface AuthState {
  token: string | null;
  refreshToken: string | null;
  user: User | null;
  setAuth: (tokens: TokenResponse) => void;
  setUser: (user: User) => void;
  logout: () => void;
  isAuthenticated: () => boolean;
}

export const useAuth = create<AuthState>()(
  persist(
    (set, get) => ({
      token: null,
      refreshToken: null,
      user: null,
      setAuth: (tokens) =>
        set({ token: tokens.access_token, refreshToken: tokens.refresh_token }),
      setUser: (user) => set({ user }),
      logout: () => set({ token: null, refreshToken: null, user: null }),
      isAuthenticated: () => !!get().token,
    }),
    { name: 'kidneuro-auth' }
  )
);
