import 'dart:convert';

// ─────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────

enum UnlockType { permanent, perUsePack, monthly }

enum TransactionType { earn, spend, bonus, streak }

// ─────────────────────────────────────────────
// COIN TRANSACTION (ledger entry)
// ─────────────────────────────────────────────

class CoinTransaction {
  final String id;
  final int amount;          // + for earn, - for spend
  final String reason;
  final DateTime timestamp;
  final TransactionType type;

  CoinTransaction({
    required this.id,
    required this.amount,
    required this.reason,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'reason': reason,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
      };

  factory CoinTransaction.fromJson(Map<String, dynamic> json) => CoinTransaction(
        id: json['id'],
        amount: json['amount'],
        reason: json['reason'],
        timestamp: DateTime.parse(json['timestamp']),
        type: TransactionType.values.byName(json['type']),
      );
}

// ─────────────────────────────────────────────
// FEATURE UNLOCK (what the user owns)
// ─────────────────────────────────────────────

class FeatureUnlock {
  final String featureId;
  final UnlockType type;
  final DateTime? unlockedAt;
  final DateTime? expiresAt;     // only for monthly
  final int usesRemaining;       // only for perUsePack

  FeatureUnlock({
    required this.featureId,
    required this.type,
    this.unlockedAt,
    this.expiresAt,
    this.usesRemaining = 0,
  });

  bool get isActive {
    if (type == UnlockType.permanent) return true;
    if (type == UnlockType.monthly && expiresAt != null) {
      return DateTime.now().isBefore(expiresAt!);
    }
    if (type == UnlockType.perUsePack) return usesRemaining > 0;
    return false;
  }

  Map<String, dynamic> toJson() => {
        'featureId': featureId,
        'type': type.name,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'usesRemaining': usesRemaining,
      };

  factory FeatureUnlock.fromJson(Map<String, dynamic> json) => FeatureUnlock(
        featureId: json['featureId'],
        type: UnlockType.values.byName(json['type']),
        unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
        usesRemaining: json['usesRemaining'] ?? 0,
      );
}

// ─────────────────────────────────────────────
// ACHIEVEMENT PROGRESS
// ─────────────────────────────────────────────

class AchievementProgress {
  final String achievementId;
  final bool isCompleted;
  final DateTime? completedAt;

  AchievementProgress({
    required this.achievementId,
    this.isCompleted = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) => AchievementProgress(
        achievementId: json['achievementId'],
        isCompleted: json['isCompleted'],
        completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      );
}

// ─────────────────────────────────────────────
// DAILY ACTIVITY (daily caps tracking)
// ─────────────────────────────────────────────

class DailyActivity {
  final DateTime date;
  int bookmarksAdded;
  int annotationsAdded;
  bool appOpenedRewardClaimed;
  bool read5MinRewardClaimed;
  bool read10MinRewardClaimed;
  bool read20MinRewardClaimed;
  bool documentCompletedRewardClaimed;
  int adsWatched;

  DailyActivity({
    required this.date,
    this.bookmarksAdded = 0,
    this.annotationsAdded = 0,
    this.appOpenedRewardClaimed = false,
    this.read5MinRewardClaimed = false,
    this.read10MinRewardClaimed = false,
    this.read20MinRewardClaimed = false,
    this.documentCompletedRewardClaimed = false,
    this.adsWatched = 0,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'bookmarksAdded': bookmarksAdded,
        'annotationsAdded': annotationsAdded,
        'appOpenedRewardClaimed': appOpenedRewardClaimed,
        'read5MinRewardClaimed': read5MinRewardClaimed,
        'read10MinRewardClaimed': read10MinRewardClaimed,
        'read20MinRewardClaimed': read20MinRewardClaimed,
        'documentCompletedRewardClaimed': documentCompletedRewardClaimed,
        'adsWatched': adsWatched,
      };

  factory DailyActivity.fromJson(Map<String, dynamic> json) => DailyActivity(
        date: DateTime.parse(json['date']),
        bookmarksAdded: json['bookmarksAdded'] ?? 0,
        annotationsAdded: json['annotationsAdded'] ?? 0,
        appOpenedRewardClaimed: json['appOpenedRewardClaimed'] ?? false,
        read5MinRewardClaimed: json['read5MinRewardClaimed'] ?? false,
        read10MinRewardClaimed: json['read10MinRewardClaimed'] ?? false,
        read20MinRewardClaimed: json['read20MinRewardClaimed'] ?? false,
        documentCompletedRewardClaimed: json['documentCompletedRewardClaimed'] ?? false,
        adsWatched: json['adsWatched'] ?? 0,
      );
}