import 'dart:convert';

import '../../../app/di/injector.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../domain/entities/auth/user_data.dart';
import '../../../domain/repositories/auth_repository.dart';

class Transaction {
  String? initiator; // Owner of the transaction
  final String receiverParty;
  final String receiverId;
  final String type;
  final double amount;
  final bool isDeducted;
  DateTime? createdAt;

  Transaction({
    this.initiator,
    required this.receiverParty,
    required this.receiverId,
    required this.type,
    required this.amount,
    required this.isDeducted,
    this.createdAt,
  });

  // Convert a Transaction to a Map
  Map<String, dynamic> toMap() {
    return {
      'initiator': initiator,
      'receiverParty': receiverParty,
      'receiverId': receiverId,
      'type': type,
      'amount': amount,
      'isDeducted': isDeducted,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Convert a Map to a Transaction
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      initiator: map['initiator'],
      receiverParty: map['receiverParty'],
      receiverId: map['receiverId'],
      type: map['type'],
      amount: (map['amount'] as num).toDouble(),
      isDeducted: map['isDeducted'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

class TransactionLocalDataSource {
  final LocalStorageService localStorageService;

  TransactionLocalDataSource(this.localStorageService);

  static const String transactionKeyPrefix = 'transactions_'; // Prefix per user

  /// Get the local user's transactions key
  Future<String?> _getTransactionKey(String msisdn) async {
    return "$transactionKeyPrefix$msisdn";
  }

  /// Add a new transaction (maintaining max 5 per type)
  Future<void> addTransaction(Transaction transaction) async {
    final userRepository = sl<AuthRepository>();
    User? user = await userRepository.getLocalUser();
    String? key = await _getTransactionKey(user!.msisdn);
    if (key == null) throw Exception("No local user found");

    List<Transaction> transactions = await getAllTransactions();
    transaction.initiator = user.msisdn;
    transaction.createdAt = DateTime.now();

    // Filter transactions of the same type
    List<Transaction> sameTypeTransactions = transactions.where((t) => t.type == transaction.type).toList();

    // Sort by `createdAt` in descending order (newest first)
    sameTypeTransactions.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    // Maintain only the latest 4 transactions of the same type
    if (sameTypeTransactions.length >= 5) {
      transactions.remove(sameTypeTransactions.last); // Remove the oldest (last in descending order)
    }

    transactions.add(transaction);
    String encodedData = jsonEncode(transactions.map((t) => t.toMap()).toList());
    await localStorageService.write(key, encodedData);
  }

  /// Retrieve all transactions for the local user, sorted from newest to oldest
  Future<List<Transaction>> getAllTransactions() async {
    final userRepository = sl<AuthRepository>();
    User? user = await userRepository.getLocalUser();
    String? key = await _getTransactionKey(user!.msisdn);
    if (key == null) return [];

    String? data = await localStorageService.read(key);
    print("----local data source----");
    print(data);
    if (data == null) return [];

    List<dynamic> decodedList = jsonDecode(data);
    List<Transaction> transactions = decodedList.map((map) => Transaction.fromMap(map)).toList();

    // Sort transactions by `createdAt` in descending order (newest first)
    transactions.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    return transactions;
  }

  Future<List<Transaction>> getTransactionsByType(String type) async {
    final userRepository = sl<AuthRepository>();
    User? user = await userRepository.getLocalUser();
    String? key = await _getTransactionKey(user!.msisdn);
    if (key == null) return [];

    String? data = await localStorageService.read(key);
    if (data == null) return [];

    List<dynamic> decodedList = jsonDecode(data);
    List<Transaction> transactions = decodedList.map((map) => Transaction.fromMap(map)).toList();

    // Filter transactions by type
    List<Transaction> filteredTransactions = transactions.where((t) => t.type == type).toList();

    // Sort transactions by `createdAt` in descending order (newest first)
    filteredTransactions.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    return filteredTransactions;
  }

  /// Clear transactions for the local user
  Future<void> clearTransactions() async {
    final userRepository = sl<AuthRepository>();
    User? user = await userRepository.getLocalUser();
    String? key = await _getTransactionKey(user!.msisdn);
    if (key != null) {
      await localStorageService.delete(key);
    }
  }
}
