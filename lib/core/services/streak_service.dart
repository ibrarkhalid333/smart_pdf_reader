import 'package:smart_pdf_reader/core/models/coin_model.dart';
import 'package:smart_pdf_reader/core/services/coin_service.dart';
import 'package:smart_pdf_reader/core/services/storage_service.dart';

class StreakService {
  final StorageService _storage = StorageService();
  final CoinService _coinService = CoinService();

  int get currentStreak => _storage.getCurrentStreak();

  Future<int> checkAndUpdateStreak() async {
    final lastOpen = _storage.getLastOpenDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastOpen == null) {
      await _storage.setCurrentStreak(1);
      await _storage.setLastOpenDate(today);
      return 0;
    }

    final lastDay = DateTime(lastOpen.year, lastOpen.month, lastOpen.day);
    final diff = today.difference(lastDay).inDays;

    if (diff == 0) {
      // Already opened today
      return 0;
    } else if (diff == 1) {
      // Consecutive day
      final newStreak = currentStreak + 1;
      await _storage.setCurrentStreak(newStreak);
      await _storage.setLastOpenDate(today);

      final bonus = _getStreakBonus(newStreak);
      if (bonus > 0) {
        await _coinService.addCoins(bonus, '$newStreak Day Streak Bonus!', TransactionType.streak);
      }
      return bonus;
    } else {
      // Streak broken
      await _storage.setCurrentStreak(1);
      await _storage.setLastOpenDate(today);
      return 0;
    }
  }

  int _getStreakBonus(int streak) {
    return switch (streak) {
      2 => 10,
      3 => 15,
      5 => 25,
      7 => 50,
      14 => 100,
      30 => 300,
      _ => 0,
    };
  }
}