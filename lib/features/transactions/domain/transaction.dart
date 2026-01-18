import 'package:cloud_firestore/cloud_firestore.dart';

/// This class represents a single transaction in our wallet app.
/// It is immutable and maps directly to Firestore documents.
class TransactionModel {
  final String id;          // Firestore document ID
  final String userId;      // ID of the user who owns this transaction
  final double amount;      // Transaction amount
  final String type;        // 'credit' or 'debit'
  final String description; // Short description of the transaction
  final DateTime createdAt; // Timestamp of the transaction

  TransactionModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  /// Converts Firestore document data into a TransactionModel
  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] as String? ?? '', // fallback or throw if critical
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'unknown',
      description: map['description'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Converts this object into a Map to store in Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
