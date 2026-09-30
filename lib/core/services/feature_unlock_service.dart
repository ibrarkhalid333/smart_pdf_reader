import 'package:smart_pdf_reader/core/models/coin_model.dart';
import 'package:smart_pdf_reader/core/services/coin_service.dart';
import 'package:smart_pdf_reader/core/services/storage_service.dart';

class FeatureUnlockService {
  final StorageService _storage = StorageService();
  final CoinService _coinService = CoinService();

  List<FeatureUnlock> get allUnlocks => _storage.getFeatureUnlocks();

  bool isFeatureUnlocked(String featureId) {
    final matches = allUnlocks.where((u) => u.featureId == featureId).toList();
    return matches.isNotEmpty && matches.first.isActive;
  }

  int getUsesRemaining(String featureId) {
    final matches = allUnlocks.where((u) => u.featureId == featureId).toList();
    return matches.isNotEmpty ? matches.first.usesRemaining : 0;
  }

  Future<bool> purchaseFeature({
    required String featureId,
    required int cost,
    required UnlockType type,
    int usesPerPack = 0,
    int monthlyDays = 30,
  }) async {
    if (!await _coinService.spendCoins(cost, 'Unlocked: $featureId')) return false;

    final unlocks = allUnlocks;
    final idx = unlocks.indexWhere((u) => u.featureId == featureId);
    final now = DateTime.now();

    FeatureUnlock newUnlock;
    if (type == UnlockType.permanent) {
      newUnlock = FeatureUnlock(featureId: featureId, type: UnlockType.permanent, unlockedAt: now);
    } else if (type == UnlockType.perUsePack) {
      final current = idx >= 0 ? unlocks[idx].usesRemaining : 0;
      newUnlock = FeatureUnlock(
        featureId: featureId,
        type: UnlockType.perUsePack,
        unlockedAt: now,
        usesRemaining: current + usesPerPack,
      );
    } else {
      newUnlock = FeatureUnlock(
        featureId: featureId,
        type: UnlockType.monthly,
        unlockedAt: now,
        expiresAt: now.add(Duration(days: monthlyDays)),
      );
    }

    if (idx >= 0) {
      unlocks[idx] = newUnlock;
    } else {
      unlocks.add(newUnlock);
    }

    await _storage.saveFeatureUnlocks(unlocks);
    return true;
  }

  Future<bool> consumeUse(String featureId) async {
    final unlocks = allUnlocks;
    final idx = unlocks.indexWhere((u) => u.featureId == featureId);
    if (idx == -1) return false;

    final u = unlocks[idx];
    if (u.type != UnlockType.perUsePack || u.usesRemaining <= 0) return false;

    unlocks[idx] = FeatureUnlock(
      featureId: featureId,
      type: UnlockType.perUsePack,
      unlockedAt: u.unlockedAt,
      usesRemaining: u.usesRemaining - 1,
    );
    await _storage.saveFeatureUnlocks(unlocks);
    return true;
  }

  Future<void> cleanupExpired() async {
    final valid = allUnlocks.where((u) => u.isActive).toList();
    await _storage.saveFeatureUnlocks(valid);
  }
}