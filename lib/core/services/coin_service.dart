import 'dart:math';

import 'package:smart_pdf_reader/core/models/coin_model.dart';
import 'package:smart_pdf_reader/core/services/storage_service.dart';

class CoinService {
  final StorageService _storage = StorageService();

  int get balance => _storage.getCoinBalance();
  List<CoinTransaction> get transactions => _storage.getTransactions();

  Future<void> addCoins(int amount, String reason, TransactionType type) async {
    if (amount <= 0) return;
    final newBalance = balance + amount;
    await _storage.setCoinBalance(newBalance);

    final tx = CoinTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}',
      amount: amount,
      reason: reason,
      timestamp: DateTime.now(),
      type: type,
    );

    final all = _storage.getTransactions();
    all.insert(0, tx);
    await _storage.saveTransactions(all);
  }

  Future<bool> spendCoins(int amount, String reason) async {
    if (amount <= 0 || balance < amount) return false;

    await _storage.setCoinBalance(balance - amount);

    final tx = CoinTransaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}',
      amount: -amount,
      reason: reason,
      timestamp: DateTime.now(),
      type: TransactionType.spend,
    );

    final all = _storage.getTransactions();
    all.insert(0, tx);
    await _storage.saveTransactions(all);
    return true;
  }
}