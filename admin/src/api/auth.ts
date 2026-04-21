import { api } from './client'

export interface UserMe {
  id: string
  username: string
  full_name: string
  email: string | null
  is_active: boolean
  roles: string[]
}

export interface LoginResponse {
  access_token: string
  refresh_token: string
  token_type: string
}

export const authApi = {
  login: (username: string, password: string) =>
    api.post<LoginResponse>('/auth/login', { username, password }),

  me: () => api.get<UserMe>('/auth/me'),
}
