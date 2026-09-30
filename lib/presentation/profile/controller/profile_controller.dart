import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/const/app_constants.dart';
import 'package:smart_pdf_reader/presentation/global/controllers/global_coin_controller.dart';

class ProfileController extends GetxController {
  GlobalCoinController get _coinController => Get.find<GlobalCoinController>();

  var achievements = <Achievement>[].obs;
  // static profile info
  var userName = 'Alex Rahman'.obs;
  var memberSince = 'Jan 2025'.obs;
  // live stat from coin system
  int get streakDays => _coinController.currentStreak.value;
  int get pdfsRead => _coinController.totalPdfsRead;
  int get pagesRead => _coinController.totalPagesRead;
  int get readingTimeHours => 18; // TODO: track actual reading time

  // Achievement display definitions
  final List<_AchievementItem> achievementItems = [
    _AchievementItem(id: 'first_pdf', title: 'First PDF opened', icon: Icons.picture_as_pdf_outlined, reward: 20),
    _AchievementItem(id: 'first_bookmark', title: 'First bookmark', icon: Icons.bookmark_outline, reward: 10),
    _AchievementItem(id: 'first_annotation', title: 'First annotation', icon: Icons.comment_outlined, reward: 10),
    _AchievementItem(id: 'read_5_pdfs', title: 'Read 5 PDFs', icon: Icons.menu_book_outlined, reward: 50),
    _AchievementItem(id: 'read_10_pdfs', title: 'Read 10 PDFs', icon: Icons.library_books_outlined, reward: 100),
    _AchievementItem(id: 'read_500_pages', title: '500 pages read', icon: Icons.collections_bookmark_outlined, reward: 150),
  ];

  bool isAchievementUnlocked(String id) {
    final ach = _coinController.achievements.firstWhereOrNull((a) => a.achievementId == id);
    return ach?.isCompleted ?? false;
  }

  @override
  void onInit() {
    super.onInit();
    
  }

  
}

class _AchievementItem {
  final String id;
  final String title;
  final IconData icon;
  final int reward;
  _AchievementItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.reward,
  });
}
