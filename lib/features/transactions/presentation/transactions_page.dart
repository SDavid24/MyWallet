
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/transaction.dart';
import 'transactions_view_model.dart';
import '../../auth/presentation/auth_view_model.dart';

/// Main UI for transactions
/// Shows a list of transactions and a button to add a new one
class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      // If scrolled to the bottom
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        // Load more transactions
        ref.read(transactionsViewModelProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Always dispose controllers
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: transactionsAsync.when(
        data: (transactions) => Column(
          children: [
            // Wallet balance
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance', style: TextStyle(fontSize: 18)),
                      Text(
                        ref.read(transactionsViewModelProvider.notifier)
                            .totalBalance
                            .toStringAsFixed(2),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Transaction list
            Expanded(
              child: ListView.builder(
                controller: _scrollController, // Use persistent controller
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return ListTile(
                    title: Text(tx.description),
                    subtitle: Text(tx.type),
                    trailing: Text(tx.amount.toStringAsFixed(2)),
                  );
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final user = ref.read(authStateProvider).value;
          if (user == null) return;

          final tx = TransactionModel(
            id: '',
            userId: user.uid,
            amount: 50,
            type: 'credit',
            description: 'Sample Transaction',
            createdAt: DateTime.now(),
          );

          await ref.read(transactionsViewModelProvider.notifier).addTransaction(tx);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
