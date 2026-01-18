import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/transactions_repository.dart';
import '../domain/transaction.dart';
import '../../auth/presentation/auth_view_model.dart';

/// Provider for repository
final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository(FirebaseFirestore.instance);
});


/// StateNotifierProvider manages the async list of transactions
final transactionsViewModelProvider =
StateNotifierProvider<TransactionsViewModel, AsyncValue<List<TransactionModel>>>(
      (ref) => TransactionsViewModel(ref),
);


/// ViewModel that exposes transactions to the UI
class TransactionsViewModel
    extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final Ref ref;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;

  TransactionsViewModel(this.ref) : super(const AsyncLoading()) {
    _fetchInitialTransactions();
  }

  Future<void> _fetchInitialTransactions() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncLoading();
    try {
      final snapshotBatch = await ref
          .read(transactionsRepositoryProvider)
          .getUserTransactionsPaginatedSnapshots(user.uid, limit: 20);

      if (snapshotBatch.isNotEmpty) {
        _lastDoc = snapshotBatch.last; // ✅ last snapshot
      }

      // Convert snapshots to TransactionModel
      final firstBatch =
      snapshotBatch.map((doc) => TransactionModel.fromMap(doc.data(), doc.id)).toList();

      state = AsyncData(firstBatch);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final snapshotBatch = await ref
          .read(transactionsRepositoryProvider)
          .getUserTransactionsPaginatedSnapshots(user.uid, limit: 20, startAfter: _lastDoc);

      if (snapshotBatch.isEmpty) {
        _hasMore = false;
        return;
      }

      _lastDoc = snapshotBatch.last;

      final nextBatch =
      snapshotBatch.map((doc) => TransactionModel.fromMap(doc.data(), doc.id)).toList();

      final currentList = state.value ?? [];
      state = AsyncData([...currentList, ...nextBatch]);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Add transaction stays the same
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await ref.read(transactionsRepositoryProvider).addTransaction(transaction);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // totalBalance stays the same
  double get totalBalance {
    final transactions = state.value ?? [];
    double sum = 0;
    for (var tx in transactions) {
      sum += (tx.type == 'credit') ? tx.amount : -tx.amount;
    }
    return sum;
  }
}

