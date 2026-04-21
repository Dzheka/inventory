import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/asset_models.dart';
import '../../data/repositories/asset_repository.dart';

class AssetListNotifier extends AsyncNotifier<List<AssetModel>> {
  @override
  Future<List<AssetModel>> build() async {
    return ref.read(assetRepositoryProvider).getAssets();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(assetRepositoryProvider).getAssets(),
    );
  }
}

final assetListProvider =
    AsyncNotifierProvider<AssetListNotifier, List<AssetModel>>(
  AssetListNotifier.new,
);

enum ImportStatus { idle, loading, success, error }

class ImportState {
  final ImportStatus status;
  final ImportResultModel? result;
  final String? error;

  const ImportState({
    this.status = ImportStatus.idle,
    this.result,
    this.error,
  });
}

class FileImportNotifier extends StateNotifier<ImportState> {
  final AssetRepository _repository;

  FileImportNotifier(this._repository) : super(const ImportState());

  Future<void> importFile(Uint8List bytes, String filename) async {
    state = const ImportState(status: ImportStatus.loading);
    try {
      final result = await _repository.importFromFile(bytes, filename);
      state = ImportState(status: ImportStatus.success, result: result);
    } catch (e) {
      state = ImportState(
        status: ImportStatus.error,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const ImportState();
}

final fileImportProvider =
    StateNotifierProvider<FileImportNotifier, ImportState>((ref) {
  return FileImportNotifier(ref.watch(assetRepositoryProvider));
});
