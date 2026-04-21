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
}
