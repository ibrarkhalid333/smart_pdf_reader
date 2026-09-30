import 'package:smart_pdf_reader/core/models/coin_model.dart';
import 'package:smart_pdf_reader/core/services/coin_service.dart';
import 'package:smart_pdf_reader/core/services/storage_service.dart';

class AchievementService {
  final StorageService _storage = StorageService();
  final CoinService _coinService = CoinService();

  final Map<String, _AchievementDef> _defs = {
    'first_pdf': _AchievementDef('First PDF opened', 20),
    'first_bookmark': _AchievementDef('First bookmark', 10),
    'first_annotation': _AchievementDef('First annotation', 10),
    'read_5_pdfs': _AchievementDef('Read 5 PDFs', 50),
    'read_10_pdfs': _AchievementDef('Read 10 PDFs', 100),
    'read_100_pages': _AchievementDef('100 pages read', 50),
    'read_500_pages': _AchievementDef('500 pages read', 150),
  };

  List<AchievementProgress> get allAchievements {
    final saved = _storage.getAchievements();
    return _defs.entries.map((e) {
      final found = saved.where((a) => a.achievementId == e.key).toList();
      return found.isNotEmpty ? found.first : AchievementProgress(achievementId: e.key);
    }).toList();
  }

  Future<void> checkAchievement(String id) async {
    final all = allAchievements;
    final idx = all.indexWhere((a) => a.achievementId == id);
    if (idx == -1) return;
    if (all[idx].isCompleted) return;

    all[idx] = AchievementProgress(
      achievementId: id,
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    await _storage.saveAchievements(all);

    final def = _defs[id]!;
    await _coinService.addCoins(def.reward, 'Achievement: ${def.title}', TransactionType.bonus);
  }

  Future<void> onPdfOpened() async {
    final total = _storage.getTotalPdfsRead();
    if (total >= 1) await checkAchievement('first_pdf');
    if (total >= 5) await checkAchievement('read_5_pdfs');
    if (total >= 10) await checkAchievement('read_10_pdfs');
  }

  Future<void> onBookmarkAdded() async => await checkAchievement('first_bookmark');
  Future<void> onAnnotationAdded() async => await checkAchievement('first_annotation');

  Future<void> onPagesRead(int total) async {
    if (total >= 100) await checkAchievement('read_100_pages');
    if (total >= 500) await checkAchievement('read_500_pages');
  }
}

class _AchievementDef {
  final String title;
  final int reward;
  _AchievementDef(this.title, this.reward);
}