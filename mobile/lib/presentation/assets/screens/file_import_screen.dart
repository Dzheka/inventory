import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/asset_models.dart';
import '../../providers/asset_provider.dart';

class FileImportScreen extends ConsumerStatefulWidget {
  const FileImportScreen({super.key});

  @override
  ConsumerState<FileImportScreen> createState() => _FileImportScreenState();
}

class _FileImportScreenState extends ConsumerState<FileImportScreen> {
  PlatformFile? _pickedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
      ref.read(fileImportProvider.notifier).reset();
    }
  }

  Future<void> _upload() async {
    final file = _pickedFile;
    if (file == null || file.bytes == null) return;
    await ref
        .read(fileImportProvider.notifier)
        .importFile(file.bytes!, file.name);
    if (mounted) {
      ref.read(assetListProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(fileImportProvider);
    final isLoading = importState.status == ImportStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Импорт данных')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoCard(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Выбрать файл'),
              onPressed: isLoading ? null : _pickFile,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (_pickedFile != null) ...[
              const SizedBox(height: 12),
              _FileChip(file: _pickedFile!),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_rounded),
              label: Text(isLoading ? 'Загружаем...' : 'Загрузить'),
              onPressed: (_pickedFile != null && !isLoading) ? _upload : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (importState.status == ImportStatus.success &&
                importState.result != null) ...[
              const SizedBox(height: 24),
              _ResultCard(result: importState.result!),
            ],
            if (importState.status == ImportStatus.error) ...[
              const SizedBox(height: 24),
              _ErrorCard(message: importState.error ?? 'Ошибка импорта'),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      color: color.withValues(alpha: 0.08),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, size: 18, color: color),
              const SizedBox(width: 8),
              Text('Формат файла',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: color)),
            ]),
            const SizedBox(height: 10),
            const Text('Поддерживаемые форматы: .xlsx, .xls, .csv'),
            const SizedBox(height: 6),
            const Text('Обязательные колонки:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            const Text('• Инв. номер'),
            const Text('• Название'),
            const SizedBox(height: 4),
            const Text(
                'Дополнительно: Баркод, Описание,\nПервоначальная стоимость, 1C ID',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  final PlatformFile file;
  const _FileChip({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_outlined,
              size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          if (file.size > 0) ...[
            const SizedBox(width: 8),
            Text(
              _formatSize(file.size),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }
}

class _ResultCard extends StatelessWidget {
  final ImportResultModel result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Результат импорта',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            _StatRow(
                label: 'Создано',
                value: '${result.created}',
                color: Colors.green),
            const Divider(height: 1),
            _StatRow(
                label: 'Пропущено',
                value: '${result.skipped}',
                color: Colors.grey),
            if (result.errors.isNotEmpty) ...[
              const Divider(height: 1),
              _StatRow(
                  label: 'Ошибок',
                  value: '${result.errors.length}',
                  color: Colors.red),
              const SizedBox(height: 12),
              const Text('Ошибки:',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              ...result.errors.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Строка ${e.row}: ${e.message}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.red),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
