import { useEffect } from 'react'
import { BrowserRouter, Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Layout, Menu, Button, Avatar, Typography, theme } from 'antd'
import {
  DashboardOutlined, AppstoreOutlined, LogoutOutlined, UserOutlined,
} from '@ant-design/icons'
import { ConfigProvider } from 'antd'
import ruRU from 'antd/locale/ru_RU'

import { useAuthStore } from './store/auth'
import LoginPage from './pages/LoginPage'
import AssetsPage from './pages/AssetsPage'

const { Header, Sider, Content } = Layout
const qc = new QueryClient()

function ProtectedLayout() {
  const user = useAuthStore((s) => s.user)
  const logout = useAuthStore((s) => s.logout)
  const navigate = useNavigate()
  const location = useLocation()
  const { token } = theme.useToken()

  if (!user) return <Navigate to="/login" replace />

  const menuItems = [
    { key: '/', icon: <DashboardOutlined />, label: 'Главная' },
    { key: '/assets', icon: <AppstoreOutlined />, label: 'Активы' },
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
          <Avatar icon={<UserOutlined />} size="small" />
          <Typography.Text>{user.full_name}</Typography.Text>
          <Button
            icon={<LogoutOutlined />}
            type="text"
            onClick={() => { logout(); navigate('/login') }}
          >
            Выйти
          </Button>
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
          </Routes>
        </Content>
      </Layout>
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
