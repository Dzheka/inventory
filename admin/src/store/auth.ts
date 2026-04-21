import { create } from 'zustand'
import { authApi, type UserMe } from '../api/auth'

interface AuthState {
  user: UserMe | null
  loading: boolean
  login: (username: string, password: string) => Promise<void>
  logout: () => void
  fetchMe: () => Promise<void>
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  loading: false,

  login: async (username, password) => {
    set({ loading: true })
    try {
      const { data } = await authApi.login(username, password)
      localStorage.setItem('access_token', data.access_token)
      localStorage.setItem('refresh_token', data.refresh_token)
      const me = await authApi.me()
      set({ user: me.data, loading: false })
    } catch (e) {
      set({ loading: false })
      throw e
    }
  },

  logout: () => {
    localStorage.clear()
    set({ user: null })
  },

  fetchMe: async () => {
    const token = localStorage.getItem('access_token')
    if (!token) return
    try {
      const { data } = await authApi.me()
      set({ user: data })
    } catch {
      localStorage.clear()
    }
  },
}))
