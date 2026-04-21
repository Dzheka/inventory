import { api } from './client'

export interface Asset {
  id: string
  inventory_number: string
  barcode: string | null
  name: string
  description: string | null
  category_id: number | null
  department_id: number | null
  room_id: number | null
  initial_cost: string | null
  residual_value: string | null
  commissioning_date: string | null
  useful_life_months: number | null
  status: string
  inventory_status: string
  one_c_id: string | null
  created_at: string
  updated_at: string
  last_scanned_at: string | null
  photos: { id: string; s3_key: string; is_primary: boolean }[]
}

export interface AssetCreate {
  inventory_number: string
  name: string
  barcode?: string
  description?: string
  category_id?: number
  department_id?: number
  room_id?: number
  initial_cost?: number
  one_c_id?: string
}

export interface AssetUpdate {
  name?: string
  description?: string
  barcode?: string
  status?: string
  category_id?: number
  department_id?: number
  room_id?: number
}

export const assetsApi = {
  list: (params?: { page?: number; limit?: number; search?: string; status?: string }) =>
    api.get<Asset[]>('/assets', { params }),

  get: (id: string) => api.get<Asset>(`/assets/${id}`),

  create: (data: AssetCreate) => api.post<Asset>('/assets', data),

  update: (id: string, data: AssetUpdate) => api.patch<Asset>(`/assets/${id}`, data),

  delete: (id: string) => api.delete(`/assets/${id}`),
}
