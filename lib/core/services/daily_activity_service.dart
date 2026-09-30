import 'package:smart_pdf_reader/core/models/coin_model.dart';
import 'package:smart_pdf_reader/core/services/coin_service.dart';
import 'package:smart_pdf_reader/core/services/storage_service.dart';

class DailyActivityService {
  final StorageService _storage = StorageService();
  final CoinService _coinService = CoinService();

  DailyActivity _getOrCreateToday() {
    final existing = _storage.getDailyActivity();
    final now = DateTime.now();
    if (existing != null && _sameDay(existing.date, now)) return existing;
    return DailyActivity(date: now);
  }

  Future<void> onAppOpened() async {
    final daily = _getOrCreateToday();
    if (!daily.appOpenedRewardClaimed) {
      await _coinService.addCoins(5, 'Daily app open', TransactionType.earn);
      daily.appOpenedRewardClaimed = true;
      await _storage.saveDailyActivity(daily);
    }
  }

  Future<void> onBookmarkAdded() async {
    final daily = _getOrCreateToday();
    if (daily.bookmarksAdded < 5) {
      await _coinService.addCoins(3, 'Bookmark added', TransactionType.earn);
      daily.bookmarksAdded++;
      await _storage.saveDailyActivity(daily);
    }
  }

  Future<void> onAnnotationAdded() async {
    final daily = _getOrCreateToday();
    if (daily.annotationsAdded < 5) {
      await _coinService.addCoins(3, 'Annotation added', TransactionType.earn);
      daily.annotationsAdded++;
      await _storage.saveDailyActivity(daily);
    }
  }

  Future<void> onAdWatched() async {
    final daily = _getOrCreateToday();
    await _coinService.addCoins(5, 'Ad watched', TransactionType.earn);
    daily.adsWatched++;
    await _storage.saveDailyActivity(daily);
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}