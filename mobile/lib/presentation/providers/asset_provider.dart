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
