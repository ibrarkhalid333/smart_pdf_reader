import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_pdf_reader/core/models/coin_model.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Coin Balance ───
  int getCoinBalance() => _prefs?.getInt('coin_balance') ?? 342;
  Future<void> setCoinBalance(int value) async => await _prefs?.setInt('coin_balance', value);

  // ─── Transactions ───
  List<CoinTransaction> getTransactions() {
    final raw = _prefs?.getString('coin_transactions');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => CoinTransaction.fromJson(e)).toList();
  }

  Future<void> saveTransactions(List<CoinTransaction> list) async {
    await _prefs?.setString('coin_transactions', jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ─── Feature Unlocks ───
  List<FeatureUnlock> getFeatureUnlocks() {
    final raw = _prefs?.getString('feature_unlocks');
    if (raw == null) {
      return [
        FeatureUnlock(featureId: 'area_screenshot_5', type: UnlockType.perUsePack, usesRemaining: 3),
        FeatureUnlock(featureId: 'scan_pdf', type: UnlockType.permanent),
        FeatureUnlock(featureId: 'dark_theme', type: UnlockType.permanent),
      ];
    }
    final list = jsonDecode(raw) as List;
    return list.map((e) => FeatureUnlock.fromJson(e)).toList();
  }

  Future<void> saveFeatureUnlocks(List<FeatureUnlock> list) async {
    await _prefs?.setString('feature_unlocks', jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ─── Achievements ───
  List<AchievementProgress> getAchievements() {
    final raw = _prefs?.getString('achievements');
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => AchievementProgress.fromJson(e)).toList();
  }

  Future<void> saveAchievements(List<AchievementProgress> list) async {
    await _prefs?.setString('achievements', jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  // ─── Streak ───
  int getCurrentStreak() => _prefs?.getInt('current_streak') ?? 0;
  Future<void> setCurrentStreak(int value) async => await _prefs?.setInt('current_streak', value);

  DateTime? getLastOpenDate() {
    final raw = _prefs?.getString('last_open_date');
    return raw != null ? DateTime.parse(raw) : null;
  }

  Future<void> setLastOpenDate(DateTime date) async {
    await _prefs?.setString('last_open_date', date.toIso8601String());
  }

  // ─── Daily Activity ───
  DailyActivity? getDailyActivity() {
    final raw = _prefs?.getString('daily_activity');
    if (raw == null) return null;
    return DailyActivity.fromJson(jsonDecode(raw));
  }

  Future<void> saveDailyActivity(DailyActivity activity) async {
    await _prefs?.setString('daily_activity', jsonEncode(activity.toJson()));
  }

  // ─── Stats ───
  int getTotalPagesRead() => _prefs?.getInt('total_pages_read') ?? 0;
  Future<void> setTotalPagesRead(int value) async => await _prefs?.setInt('total_pages_read', value);

  int getTotalPdfsRead() => _prefs?.getInt('total_pdfs_read') ?? 0;
  Future<void> setTotalPdfsRead(int value) async => await _prefs?.setInt('total_pdfs_read', value);

  // ─── Reset (for testing) ───
  Future<void> clearAll() async => await _prefs?.clear();
}