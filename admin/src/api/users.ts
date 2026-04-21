import { api } from './client'

export interface User {
  id: string
  username: string
  email: string | null
  full_name: string
  is_active: boolean
  roles: string[]
  created_at: string
  last_login_at: string | null
}

export interface UserCreate {
  username: string
  password: string
  full_name: string
  email?: string
  roles: string[]
}

export interface UserUpdate {
  full_name?: string
  email?: string
  is_active?: boolean
  roles?: string[]
}

export interface ChangePassword {
  current_password: string
  new_password: string
}

export const usersApi = {
  list: () => api.get<User[]>('/users'),
  create: (data: UserCreate) => api.post<User>('/users', data),
  update: (id: string, data: UserUpdate) => api.patch<User>(`/users/${id}`, data),
  delete: (id: string) => api.delete(`/users/${id}`),
  changePassword: (data: ChangePassword) =>
    api.post('/users/me/change-password', data),
}
