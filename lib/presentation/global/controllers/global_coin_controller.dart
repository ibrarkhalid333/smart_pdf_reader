import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/models/coin_model.dart';
import 'package:smart_pdf_reader/core/services/achievement_service.dart';
import 'package:smart_pdf_reader/core/services/coin_service.dart';
import 'package:smart_pdf_reader/core/services/daily_activity_service.dart';
import 'package:smart_pdf_reader/core/services/feature_unlock_service.dart';
import 'package:smart_pdf_reader/core/services/session_tracker.dart';
import 'package:smart_pdf_reader/core/services/storage_service.dart';
import 'package:smart_pdf_reader/core/services/streak_service.dart';

class GlobalCoinController extends GetxController {
  // Services
  final CoinService _coinService = CoinService();
  final StreakService _streakService = StreakService();
  final SessionTracker _sessionTracker = SessionTracker();
  final AchievementService _achievementService = AchievementService();
  final DailyActivityService _dailyActivityService = DailyActivityService();
  final FeatureUnlockService _featureUnlockService = FeatureUnlockService();
  final StorageService _storage = StorageService();

  // Reactive state
  final RxInt balance = 0.obs;
  final RxInt totalEarned = 0.obs;
  final RxInt totalSpent = 0.obs;
  final RxInt todayEarned = 0.obs;
  final RxInt currentStreak = 0.obs;
  final RxList<CoinTransaction> transactions = <CoinTransaction>[].obs;
  final RxList<FeatureUnlock> unlockedFeatures = <FeatureUnlock>[].obs;
  final RxList<AchievementProgress> achievements = <AchievementProgress>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  void _loadData() {
    balance.value = _coinService.balance;
    currentStreak.value = _streakService.currentStreak;
    transactions.value = _coinService.transactions;
    unlockedFeatures.value = _featureUnlockService.allUnlocks;
    achievements.value = _achievementService.allAchievements;
    _recalcStats();
    _featureUnlockService.cleanupExpired();
  }

  void _recalcStats() {
    totalEarned.value = transactions
        .where((t) => t.amount > 0)
        .fold(0, (s, t) => s + t.amount);
    totalSpent.value = transactions
        .where((t) => t.amount < 0)
        .fold(0, (s, t) => s + t.amount.abs());
    final now = DateTime.now();
    todayEarned.value = transactions
        .where((t) => t.amount > 0 && _sameDay(t.timestamp, now))
        .fold(0, (s, t) => s + t.amount);
  }

  // ─────────────────────────────────────────────
  // APP LIFECYCLE
  // ─────────────────────────────────────────────

  Future<void> onAppOpened() async {
    await _dailyActivityService.onAppOpened();
    await checkStreak();
    _refresh();
  }

  Future<void> checkStreak() async {
    final bonus = await _streakService.checkAndUpdateStreak();
    if (bonus > 0) {
      Get.snackbar(
        '${currentStreak.value} Day Streak! 🔥',
        'You earned $bonus coins',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A4D3E),
        colorText: Colors.white,
      );
    }
    currentStreak.value = _streakService.currentStreak;
    _refresh();
  }

  // ─────────────────────────────────────────────
  // READING SESSION (called from PDF viewer)
  // ─────────────────────────────────────────────

  void startReadingSession() => _sessionTracker.startSession();
  void pauseReading() => _sessionTracker.pauseReading();
  void resumeReading() => _sessionTracker.resumeReading();
  void endReadingSession() => _sessionTracker.endSession();

  Future<void> onPageTurn() async {
    await _sessionTracker.onPageTurn();
    await _achievementService.onPagesRead(_storage.getTotalPagesRead());
    _refresh();
  }

  Future<void> onDocumentComplete() async {
    await _sessionTracker.onDocumentComplete();
    await _achievementService.onPdfOpened();
    _refresh();
  }

  // ─────────────────────────────────────────────
  // USER ACTIONS (bookmarks, annotations, ads)
  // ─────────────────────────────────────────────

  Future<void> onBookmarkAdded() async {
    await _dailyActivityService.onBookmarkAdded();
    await _achievementService.onBookmarkAdded();
    _refresh();
  }

  Future<void> onAnnotationAdded() async {
    await _dailyActivityService.onAnnotationAdded();
    await _achievementService.onAnnotationAdded();
    _refresh();
  }

  Future<void> onAdWatched() async {
    await _dailyActivityService.onAdWatched();
    _refresh();
  }

  // ─────────────────────────────────────────────
  // SHOP / FEATURE UNLOCK (called from StoreController)
  // ─────────────────────────────────────────────

  /// Purchase a feature. Returns true if successful.
  Future<bool> purchaseFeature({
    required String featureId,
    required int cost,
    required UnlockType type,
    int usesPerPack = 0,
  }) async {
    final success = await _featureUnlockService.purchaseFeature(
      featureId: featureId,
      cost: cost,
      type: type,
      usesPerPack: usesPerPack,
    );

    if (success) {
      Get.snackbar(
        'Unlocked! 🎉',
        'Feature purchased successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1A4D3E),
        colorText: Colors.white,
      );
    }
    _refresh();
    return success;
  }

  /// Check if user has unlocked (and not expired) a feature
  bool isFeatureUnlocked(String featureId) {
    final list = unlockedFeatures.toList(); // triggers Obx registration
    final match = list.where((u) => u.featureId == featureId).firstOrNull;
    return match != null && match.isActive;
    // return _featureUnlockService.isFeatureUnlocked(featureId);
  }

  /// Get remaining uses for per-use pack features (e.g. screenshots)
  int getUsesRemaining(String featureId) {
    // return _featureUnlockService.getUsesRemaining(featureId);
    final list = unlockedFeatures.toList(); // triggers Obx registration
    final match = list.where((u) => u.featureId == featureId).firstOrNull;
    return match?.usesRemaining ?? 0;
  }

  /// Consume one use from a per-use pack feature
  Future<bool> consumeFeatureUse(String featureId) async {
    return await _featureUnlockService.consumeUse(featureId);
  }

  // ─────────────────────────────────────────────
  // STATS
  // ─────────────────────────────────────────────

  int get totalPagesRead => _storage.getTotalPagesRead();
  int get totalPdfsRead => _storage.getTotalPdfsRead();

  // ─────────────────────────────────────────────
  // INTERNAL
  // ─────────────────────────────────────────────

  void _refresh() {
    balance.value = _coinService.balance;
    transactions.value = _coinService.transactions;
    unlockedFeatures.value = _featureUnlockService.allUnlocks;
    achievements.value = _achievementService.allAchievements;
    _recalcStats();
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void earnCoins(int amount) {
    balance.value += amount;
    todayEarned.value += amount;
    totalEarned.value += amount;
  }

  bool spendCoins(int amount) {
    if (balance.value >= amount) {
      balance.value -= amount;
      totalSpent.value += amount;
      return true;
    }
    return false;
  }
}
