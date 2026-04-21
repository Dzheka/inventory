import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../datasources/asset_remote_datasource.dart';
import '../models/asset_models.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(ref.watch(assetRemoteDatasourceProvider));
});

class AssetRepository {
  final AssetRemoteDatasource _datasource;

  AssetRepository(this._datasource);

  Future<List<AssetModel>> getAssets({String? search, String? status}) async {
    return _datasource.getAssets(search: search, status: status, limit: 200);
  }

  Future<AssetModel?> getAssetByBarcode(String barcode) async {
    try {
      return await _datasource.getAssetByBarcode(barcode);
    } catch (_) {
      return null;
    }
  }

  Future<ImportResultModel> importFromFile(
      Uint8List bytes, String filename) async {
    try {
      return await _datasource.importFromFile(bytes, filename);
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] as String? ??
          e.message ??
          'Ошибка загрузки файла';
      throw Exception(msg);
    }
  }
}
