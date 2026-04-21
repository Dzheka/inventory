import { useEffect, useState } from 'react'
import { BrowserRouter, Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Layout, Menu, Button, Avatar, Typography, theme, Dropdown, Modal, Form, Input, message } from 'antd'
import {
  DashboardOutlined, AppstoreOutlined, LogoutOutlined, UserOutlined, TeamOutlined, KeyOutlined,
} from '@ant-design/icons'
import { ConfigProvider } from 'antd'
import ruRU from 'antd/locale/ru_RU'

import { useAuthStore } from './store/auth'
import { usersApi } from './api/users'
import LoginPage from './pages/LoginPage'
import AssetsPage from './pages/AssetsPage'
import UsersPage from './pages/UsersPage'

const { Header, Sider, Content } = Layout
const qc = new QueryClient()

function ChangePasswordModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [form] = Form.useForm()
  const [loading, setLoading] = useState(false)

  const handleOk = async () => {
    const values = await form.validateFields()
    if (values.new_password !== values.confirm_password) {
      form.setFields([{ name: 'confirm_password', errors: ['Пароли не совпадают'] }])
      return
    }
    setLoading(true)
    try {
      await usersApi.changePassword({
        current_password: values.current_password,
        new_password: values.new_password,
      })
      message.success('Пароль изменён')
      form.resetFields()
      onClose()
    } catch (e: any) {
      message.error(e.response?.data?.detail ?? 'Ошибка изменения пароля')
    } finally {
      setLoading(false)
    }
  }

  return (
    <Modal
      title="Изменить пароль"
      open={open}
      onCancel={() => { form.resetFields(); onClose() }}
      onOk={handleOk}
      confirmLoading={loading}
      okText="Сохранить"
      cancelText="Отмена"
    >
      <Form form={form} layout="vertical">
        <Form.Item name="current_password" label="Текущий пароль" rules={[{ required: true }]}>
          <Input.Password />
        </Form.Item>
        <Form.Item name="new_password" label="Новый пароль" rules={[{ required: true, min: 6, message: 'Минимум 6 символов' }]}>
          <Input.Password />
        </Form.Item>
        <Form.Item name="confirm_password" label="Повторите пароль" rules={[{ required: true }]}>
          <Input.Password />
        </Form.Item>
      </Form>
    </Modal>
  )
}

function ProtectedLayout() {
  const user = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)
  const navigate = useNavigate()
  const location = useLocation()
  const { token } = theme.useToken()
  const [changePassOpen, setChangePassOpen] = useState(false)

  if (!user) return <Navigate to="/login" replace />

  const isAdmin = user.roles?.includes('admin')

  const menuItems = [
    { key: '/', icon: <DashboardOutlined />, label: 'Главная' },
    { key: '/assets', icon: <AppstoreOutlined />, label: 'Активы' },
    ...(isAdmin ? [{ key: '/users', icon: <TeamOutlined />, label: 'Пользователи' }] : []),
  ]

  const userMenuItems = [
    { key: 'change-password', icon: <KeyOutlined />, label: 'Изменить пароль' },
    { type: 'divider' as const },
    { key: 'logout', icon: <LogoutOutlined />, label: 'Выйти', danger: true },
  ]

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Sider width={220} theme="light" style={{ borderRight: `1px solid ${token.colorBorderSecondary}` }}>
        <div style={{ padding: '16px 20px', borderBottom: `1px solid ${token.colorBorderSecondary}` }}>
          <Typography.Text strong>Инвентаризация</Typography.Text>
          <br />
          <Typography.Text type="secondary" style={{ fontSize: 11 }}>
            Crowne Plaza
          </Typography.Text>
        </div>
        <Menu
          mode="inline"
          selectedKeys={[location.pathname]}
          items={menuItems}
          onClick={({ key }) => navigate(key)}
          style={{ borderRight: 0 }}
        />
      </Sider>
      <Layout>
        <Header
          style={{
            background: token.colorBgContainer,
            borderBottom: `1px solid ${token.colorBorderSecondary}`,
            padding: '0 24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'flex-end',
            gap: 12,
          }}
        >
          <Dropdown
            menu={{
              items: userMenuItems,
              onClick: ({ key }) => {
                if (key === 'logout') { logout(); navigate('/login') }
                if (key === 'change-password') setChangePassOpen(true)
              },
            }}
            trigger={['click']}
          >
            <Button type="text" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <Avatar icon={<UserOutlined />} size="small" />
              <Typography.Text>{user.full_name}</Typography.Text>
            </Button>
          </Dropdown>
        </Header>
        <Content style={{ padding: 24, background: token.colorBgLayout }}>
          <Routes>
            <Route path="/" element={
              <div>
                <Typography.Title level={4}>Добро пожаловать, {user.full_name}!</Typography.Title>
                <Typography.Text type="secondary">Выберите раздел в меню слева.</Typography.Text>
              </div>
            } />
            <Route path="/assets" element={<AssetsPage />} />
            {isAdmin && <Route path="/users" element={<UsersPage />} />}
          </Routes>
        </Content>
      </Layout>
      <ChangePasswordModal open={changePassOpen} onClose={() => setChangePassOpen(false)} />
    </Layout>
  )
}

function AppRoutes() {
  const fetchMe = useAuthStore((s) => s.fetchMe)

  useEffect(() => { fetchMe() }, [fetchMe])

  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/*" element={<ProtectedLayout />} />
    </Routes>
  )
}

export default function App() {
  return (
    <ConfigProvider locale={ruRU}>
      <QueryClientProvider client={qc}>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </QueryClientProvider>
    </ConfigProvider>
  )
}
