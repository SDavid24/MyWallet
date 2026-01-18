import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/transaction.dart';


/// Repository that handles all Firestore operations for transactions.
/// This isolates Firestore from the UI and ViewModel.
class TransactionsRepository {
  final FirebaseFirestore firestore;

  TransactionsRepository(this.firestore);

  /// ✅ New method: Fetch next page of transactions once (not stream)
  /// Returns a stream of transactions for a user.
  /// Automatically orders by `createdAt` descending and supports pagination.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  getUserTransactionsPaginatedSnapshots(
      String userId,
      {int limit = 20,
        DocumentSnapshot? startAfter}) async {

    Query<Map<String, dynamic>> query = firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await query.get();
    return snapshot.docs; // return raw QueryDocumentSnapshots
  }


  /// Adds a new transaction for the user
  Future<void> addTransaction(TransactionModel transaction) async {
    await firestore.collection('transactions').add(transaction.toMap());
  }
}

