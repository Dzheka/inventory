import { useState } from 'react'
import {
  Table, Button, Modal, Form, Input, Select, Switch, Tag, Space,
  Popconfirm, message, Typography,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { usersApi, type User, type UserCreate, type UserUpdate } from '../api/users'

const ROLES = [
  { value: 'admin', label: 'Администратор' },
  { value: 'user', label: 'Пользователь' },
]

export default function UsersPage() {
  const qc = useQueryClient()
  const [createOpen, setCreateOpen] = useState(false)
  const [editUser, setEditUser] = useState<User | null>(null)
  const [createForm] = Form.useForm()
  const [editForm] = Form.useForm()

  const { data, isLoading } = useQuery({
    queryKey: ['users'],
    queryFn: () => usersApi.list().then((r) => r.data),
  })

  const createMutation = useMutation({
    mutationFn: (values: UserCreate) => usersApi.create(values),
    onSuccess: () => {
      message.success('Пользователь создан')
      qc.invalidateQueries({ queryKey: ['users'] })
      setCreateOpen(false)
      createForm.resetFields()
    },
    onError: (e: any) => {
      message.error(e.response?.data?.detail ?? 'Ошибка создания')
    },
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: UserUpdate }) =>
      usersApi.update(id, data),
    onSuccess: () => {
      message.success('Сохранено')
      qc.invalidateQueries({ queryKey: ['users'] })
      setEditUser(null)
    },
    onError: (e: any) => {
      message.error(e.response?.data?.detail ?? 'Ошибка сохранения')
    },
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => usersApi.delete(id),
    onSuccess: () => {
      message.success('Пользователь удалён')
      qc.invalidateQueries({ queryKey: ['users'] })
    },
    onError: (e: any) => {
      message.error(e.response?.data?.detail ?? 'Ошибка удаления')
    },
  })

  const columns = [
    {
      title: 'Имя пользователя',
      dataIndex: 'username',
      key: 'username',
      render: (v: string) => <Typography.Text strong>{v}</Typography.Text>,
    },
    { title: 'Полное имя', dataIndex: 'full_name', key: 'full_name' },
    { title: 'Email', dataIndex: 'email', key: 'email', render: (v: string | null) => v ?? '—' },
    {
      title: 'Роль',
      dataIndex: 'roles',
      key: 'roles',
      render: (roles: string[]) =>
        roles.map((r) => (
          <Tag color={r === 'admin' ? 'red' : 'blue'} key={r}>
            {r === 'admin' ? 'Администратор' : 'Пользователь'}
          </Tag>
        )),
    },
    {
      title: 'Активен',
      dataIndex: 'is_active',
      key: 'is_active',
      render: (v: boolean) => <Tag color={v ? 'green' : 'default'}>{v ? 'Да' : 'Нет'}</Tag>,
    },
    {
      title: 'Последний вход',
      dataIndex: 'last_login_at',
      key: 'last_login_at',
      render: (v: string | null) =>
        v ? new Date(v).toLocaleString('ru-RU') : '—',
    },
    {
      title: '',
      key: 'actions',
      render: (_: any, record: User) => (
        <Space>
          <Button
            icon={<EditOutlined />}
            size="small"
            onClick={() => {
              setEditUser(record)
              editForm.setFieldsValue({
                full_name: record.full_name,
                email: record.email ?? '',
                is_active: record.is_active,
                roles: record.roles,
              })
            }}
          />
          <Popconfirm
            title="Удалить пользователя?"
            onConfirm={() => deleteMutation.mutate(record.id)}
            okText="Удалить"
            cancelText="Отмена"
            okButtonProps={{ danger: true }}
          >
            <Button icon={<DeleteOutlined />} size="small" danger />
          </Popconfirm>
        </Space>
      ),
    },
  ]

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16 }}>
        <Typography.Title level={4} style={{ margin: 0 }}>Пользователи</Typography.Title>
        <Button type="primary" icon={<PlusOutlined />} onClick={() => setCreateOpen(true)}>
          Добавить
        </Button>
      </div>

      <Table
        dataSource={data}
        columns={columns}
        rowKey="id"
        loading={isLoading}
        pagination={{ pageSize: 20 }}
      />

      {/* Create modal */}
      <Modal
        title="Новый пользователь"
        open={createOpen}
        onCancel={() => { setCreateOpen(false); createForm.resetFields() }}
        onOk={() => createForm.submit()}
        confirmLoading={createMutation.isPending}
        okText="Создать"
        cancelText="Отмена"
      >
        <Form
          form={createForm}
          layout="vertical"
          onFinish={(values) => createMutation.mutate(values)}
          initialValues={{ roles: ['user'] }}
        >
          <Form.Item name="username" label="Имя пользователя" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="full_name" label="Полное имя" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="email" label="Email">
            <Input />
          </Form.Item>
          <Form.Item name="password" label="Пароль" rules={[{ required: true, min: 6, message: 'Минимум 6 символов' }]}>
            <Input.Password />
          </Form.Item>
          <Form.Item name="roles" label="Роль" rules={[{ required: true }]}>
            <Select options={ROLES} />
          </Form.Item>
        </Form>
      </Modal>

      {/* Edit modal */}
      <Modal
        title="Редактировать пользователя"
        open={!!editUser}
        onCancel={() => setEditUser(null)}
        onOk={() => editForm.submit()}
        confirmLoading={updateMutation.isPending}
        okText="Сохранить"
        cancelText="Отмена"
      >
        <Form
          form={editForm}
          layout="vertical"
          onFinish={(values) =>
            updateMutation.mutate({ id: editUser!.id, data: values })
          }
        >
          <Form.Item name="full_name" label="Полное имя" rules={[{ required: true }]}>
            <Input />
          </Form.Item>
          <Form.Item name="email" label="Email">
            <Input />
          </Form.Item>
          <Form.Item name="roles" label="Роль" rules={[{ required: true }]}>
            <Select options={ROLES} />
          </Form.Item>
          <Form.Item name="is_active" label="Активен" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  )
}
