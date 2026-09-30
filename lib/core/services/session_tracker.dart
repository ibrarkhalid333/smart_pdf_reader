import 'dart:async';

import 'package:smart_pdf_reader/core/models/coin_model.dart';
import 'package:smart_pdf_reader/core/services/coin_service.dart';
import 'package:smart_pdf_reader/core/services/storage_service.dart';

class SessionTracker {
  final StorageService _storage = StorageService();
  final CoinService _coinService = CoinService();

  Timer? _readingTimer;
  Timer? _inactivityTimer;
  bool _isReading = false;
  int _continuousSeconds = 0;
  bool _claimed5 = false;
  bool _claimed10 = false;
  bool _claimed20 = false;

  void startSession() {
    _continuousSeconds = 0;
    _claimed5 = _claimed10 = _claimed20 = false;
    _isReading = true;

    _readingTimer?.cancel();
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isReading) {
        _continuousSeconds++;
        _checkRewards();
      }
    });
  }

  void pauseReading() {
    _isReading = false;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 2), () {
      _continuousSeconds = 0;
      _claimed5 = _claimed10 = _claimed20 = false;
    });
  }

  void resumeReading() {
    _isReading = true;
    _inactivityTimer?.cancel();
  }

  void endSession() {
    _readingTimer?.cancel();
    _inactivityTimer?.cancel();
    _isReading = false;
  }

  void _checkRewards() {
    final mins = _continuousSeconds ~/ 60;
    if (mins >= 5 && !_claimed5) {
      _claimed5 = true;
      _awardIfNotClaimedToday('read_5min', 5, 'Read 5 minutes straight');
    }
    if (mins >= 10 && !_claimed10) {
      _claimed10 = true;
      _awardIfNotClaimedToday('read_10min', 15, 'Read 10 minutes straight');
    }
    if (mins >= 20 && !_claimed20) {
      _claimed20 = true;
      _awardIfNotClaimedToday('read_20min', 30, 'Read 20 minutes straight');
    }
  }

  Future<void> _awardIfNotClaimedToday(String key, int coins, String reason) async {
    final daily = _storage.getDailyActivity();
    final today = DateTime.now();

    if (daily != null && _sameDay(daily.date, today)) {
      if (key == 'read_5min' && daily.read5MinRewardClaimed) return;
      if (key == 'read_10min' && daily.read10MinRewardClaimed) return;
      if (key == 'read_20min' && daily.read20MinRewardClaimed) return;
    }

    await _coinService.addCoins(coins, reason, TransactionType.earn);

    final updated = daily ?? DailyActivity(date: today);
    if (key == 'read_5min') updated.read5MinRewardClaimed = true;
    if (key == 'read_10min') updated.read10MinRewardClaimed = true;
    if (key == 'read_20min') updated.read20MinRewardClaimed = true;
    await _storage.saveDailyActivity(updated);
  }

  Future<void> onPageTurn() async {
    await _coinService.addCoins(1, 'Page read', TransactionType.earn);
    await _storage.setTotalPagesRead(_storage.getTotalPagesRead() + 1);
  }

  Future<void> onDocumentComplete() async {
    final daily = _storage.getDailyActivity() ?? DailyActivity(date: DateTime.now());
    if (!daily.documentCompletedRewardClaimed) {
      await _coinService.addCoins(50, 'Completed a document', TransactionType.earn);
      daily.documentCompletedRewardClaimed = true;
      await _storage.saveDailyActivity(daily);
      await _storage.setTotalPdfsRead(_storage.getTotalPdfsRead() + 1);
    }
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}