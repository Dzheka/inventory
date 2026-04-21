import { useState } from 'react'
import {
  Table, Button, Input, Tag, Space, Modal, Form,
  Select, Popconfirm, message, Typography, Row, Col,
} from 'antd'
import {
  PlusOutlined, SearchOutlined, EditOutlined, DeleteOutlined,
} from '@ant-design/icons'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { assetsApi, type Asset, type AssetCreate, type AssetUpdate } from '../api/assets'

const STATUS_COLORS: Record<string, string> = {
  active: 'green',
  written_off: 'default',
  under_repair: 'orange',
  transferred: 'blue',
  missing: 'red',
}

const STATUS_LABELS: Record<string, string> = {
  active: 'Активен',
  written_off: 'Списан',
  under_repair: 'Ремонт',
  transferred: 'Передан',
  missing: 'Утерян',
}

const INV_STATUS_LABELS: Record<string, string> = {
  not_scanned: 'Не сканирован',
  found: 'Найден',
  not_found: 'Не найден',
  surplus: 'Излишек',
  discrepancy: 'Расхождение',
}

const INV_STATUS_COLORS: Record<string, string> = {
  not_scanned: 'default',
  found: 'green',
  not_found: 'red',
  surplus: 'orange',
  discrepancy: 'orange',
}

export default function AssetsPage() {
  const qc = useQueryClient()
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState<string | undefined>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editing, setEditing] = useState<Asset | null>(null)
  const [form] = Form.useForm()

  const { data: assets = [], isLoading } = useQuery({
    queryKey: ['assets', search, statusFilter],
    queryFn: () =>
      assetsApi
        .list({ search: search || undefined, status: statusFilter, limit: 200 })
        .then((r) => r.data),
  })

  const createMutation = useMutation({
    mutationFn: (data: AssetCreate) => assetsApi.create(data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['assets'] })
      message.success('Актив создан')
      setModalOpen(false)
      form.resetFields()
    },
    onError: () => message.error('Ошибка создания'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: AssetUpdate }) =>
      assetsApi.update(id, data),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['assets'] })
      message.success('Сохранено')
      setModalOpen(false)
      setEditing(null)
      form.resetFields()
    },
    onError: () => message.error('Ошибка сохранения'),
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => assetsApi.delete(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['assets'] })
      message.success('Удалено')
    },
    onError: () => message.error('Ошибка удаления'),
  })

  const openCreate = () => {
    setEditing(null)
    form.resetFields()
    setModalOpen(true)
  }

  const openEdit = (asset: Asset) => {
    setEditing(asset)
    form.setFieldsValue({
      name: asset.name,
      inventory_number: asset.inventory_number,
      barcode: asset.barcode,
      description: asset.description,
      status: asset.status,
    })
    setModalOpen(true)
  }

  const onSubmit = async (values: AssetCreate & AssetUpdate) => {
    if (editing) {
      updateMutation.mutate({ id: editing.id, data: values })
    } else {
      createMutation.mutate(values as AssetCreate)
    }
  }

  const columns = [
    {
      title: 'Инв. номер',
      dataIndex: 'inventory_number',
      key: 'inv',
      width: 140,
      render: (v: string) => <Typography.Text code>{v}</Typography.Text>,
    },
    {
      title: 'Название',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Баркод',
      dataIndex: 'barcode',
      key: 'barcode',
      width: 130,
      render: (v: string | null) => v ?? '—',
    },
    {
      title: 'Статус',
      dataIndex: 'status',
      key: 'status',
      width: 110,
      render: (v: string) => (
        <Tag color={STATUS_COLORS[v]}>{STATUS_LABELS[v] ?? v}</Tag>
      ),
    },
    {
      title: 'Инвентаризация',
      dataIndex: 'inventory_status',
      key: 'inv_status',
      width: 140,
      render: (v: string) => (
        <Tag color={INV_STATUS_COLORS[v]}>{INV_STATUS_LABELS[v] ?? v}</Tag>
      ),
    },
    {
      title: '',
      key: 'actions',
      width: 90,
      render: (_: unknown, record: Asset) => (
        <Space>
          <Button
            icon={<EditOutlined />}
            size="small"
            onClick={() => openEdit(record)}
          />
          <Popconfirm
            title="Удалить актив?"
            onConfirm={() => deleteMutation.mutate(record.id)}
            okText="Да"
            cancelText="Нет"
          >
            <Button icon={<DeleteOutlined />} size="small" danger />
          </Popconfirm>
        </Space>
      ),
    },
  ]

  return (
    <div>
      <Row justify="space-between" align="middle" style={{ marginBottom: 16 }}>
        <Col>
          <Typography.Title level={4} style={{ margin: 0 }}>
            Активы ({assets.length})
          </Typography.Title>
        </Col>
        <Col>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Добавить
          </Button>
        </Col>
      </Row>

      <Row gutter={8} style={{ marginBottom: 16 }}>
        <Col flex="auto">
          <Input
            placeholder="Поиск по названию, инв. номеру, баркоду..."
            prefix={<SearchOutlined />}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            allowClear
          />
        </Col>
        <Col>
          <Select
            placeholder="Статус"
            allowClear
            style={{ width: 140 }}
            value={statusFilter}
            onChange={setStatusFilter}
            options={Object.entries(STATUS_LABELS).map(([v, l]) => ({
              value: v,
              label: l,
            }))}
          />
        </Col>
      </Row>

      <Table
        rowKey="id"
        columns={columns}
        dataSource={assets}
        loading={isLoading}
        size="small"
        pagination={{ pageSize: 50, showSizeChanger: false }}
        scroll={{ x: 800 }}
      />

      <Modal
        title={editing ? 'Редактировать актив' : 'Новый актив'}
        open={modalOpen}
        onCancel={() => { setModalOpen(false); setEditing(null); form.resetFields() }}
        onOk={() => form.submit()}
        okText="Сохранить"
        cancelText="Отмена"
        confirmLoading={createMutation.isPending || updateMutation.isPending}
        width={520}
      >
        <Form form={form} layout="vertical" onFinish={onSubmit}>
          {!editing && (
            <Form.Item
              name="inventory_number"
              label="Инв. номер"
              rules={[{ required: true, message: 'Обязательное поле' }]}
            >
              <Input placeholder="INV-001" />
            </Form.Item>
          )}
          <Form.Item
            name="name"
            label="Название"
            rules={[{ required: true, message: 'Обязательное поле' }]}
          >
            <Input placeholder="Название актива" />
          </Form.Item>
          <Form.Item name="barcode" label="Баркод">
            <Input placeholder="1234567890" />
          </Form.Item>
          <Form.Item name="description" label="Описание">
            <Input.TextArea rows={2} />
          </Form.Item>
          {editing && (
            <Form.Item name="status" label="Статус">
              <Select
                options={Object.entries(STATUS_LABELS).map(([v, l]) => ({
                  value: v,
                  label: l,
                }))}
              />
            </Form.Item>
          )}
        </Form>
      </Modal>
    </div>
  )
}
