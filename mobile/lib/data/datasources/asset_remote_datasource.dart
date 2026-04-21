import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/asset_models.dart';

final assetRemoteDatasourceProvider = Provider<AssetRemoteDatasource>((ref) {
  return AssetRemoteDatasource(ref.watch(apiClientProvider));
});

class AssetRemoteDatasource {
  final Dio _dio;

  AssetRemoteDatasource(this._dio);

  Future<List<AssetModel>> getAssets({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    final response = await _dio.get('/assets', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status,
    });
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AssetModel> getAssetByBarcode(String barcode) async {
    final response = await _dio.get('/assets/barcode/$barcode');
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AssetModel> getAsset(String id) async {
    final response = await _dio.get('/assets/$id');
    return AssetModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ImportResultModel> importFromFile(
      Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post('/assets/import', data: formData);
    return ImportResultModel.fromJson(response.data as Map<String, dynamic>);
  }
}
