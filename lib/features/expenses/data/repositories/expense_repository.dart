import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:masroufi/features/expenses/data/models/expense_model.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;
  final Box _pendingBox;

  ExpenseRepository({
    FirebaseFirestore? firestore,
    Box? pendingBox,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _pendingBox = pendingBox ?? Hive.box('pending_expenses');

  // ── Create Operation ──────────────────────────────────────────────────────

  /// Adds an expense: Writes to Hive immediately, then fire-and-forgets
  /// the Firestore push in the background. Returns as soon as the local
  /// write completes — the UI never blocks on network.
  Future<ExpenseModel> addExpense({
    required String uid,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? note,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final expense = ExpenseModel(
      id: id,
      amount: amount,
      categoryId: categoryId,
      note: note,
      date: date,
      createdAt: now,
      synced: false,
    );

    // 1. Write to local Hive pending box — instant UX feedback
    try {
      await _pendingBox.put(id, expense.toHiveMap());
    } catch (e) {
      debugPrint('Hive write failed: $e');
    }

    // 2. Fire-and-forget Firestore push.
    //    Firestore .set() does NOT throw when offline — it hangs until
    //    connectivity returns. Awaiting it would cause the spinner to
    //    spin forever. Instead, we push in the background and clean up
    //    the Hive entry on success.
    _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(id)
        .set(expense.toFirestore())
        .then((_) => _pendingBox.delete(id))
        .catchError((e) {
      debugPrint('Firestore write failed, queued locally: $e');
    });

    return expense;
  }

  // ── Read Operations ───────────────────────────────────────────────────────

  /// Streams expenses from Firestore ordered by date descending.
  Stream<List<ExpenseModel>> watchExpenses(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ExpenseModel.fromFirestore).toList());
  }

  /// Gets a list of expenses from Firestore once.
  Future<List<ExpenseModel>> getExpenses(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(ExpenseModel.fromFirestore).toList();
  }

  /// Gets all unsynced expenses currently stored in the Hive box.
  List<ExpenseModel> getUnsyncedExpenses() {
    return _pendingBox.values
        .map((val) => ExpenseModel.fromHiveMap(Map<dynamic, dynamic>.from(val as Map))
        )
        .toList();
  }

  /// Updates an existing expense. Fire-and-forget Firestore update.
  Future<ExpenseModel> updateExpense({
    required String uid,
    required ExpenseModel expense,
  }) async {
    // 1. Update Hive entry if it exists in pending box or queue it as unsynced
    try {
      await _pendingBox.put(expense.id, expense.toHiveMap());
    } catch (e) {
      debugPrint('Hive write failed: $e');
    }

    // 2. Fire-and-forget Firestore update in the background.
    _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expense.id)
        .set(expense.toFirestore())
        .then((_) => _pendingBox.delete(expense.id))
        .catchError((e) {
      debugPrint('Firestore update failed, queued locally: $e');
    });

    return expense;
  }

  /// Deletes an expense. Fire-and-forget Firestore delete.
  Future<void> deleteExpense({
    required String uid,
    required String expenseId,
  }) async {
    // 1. Delete from Hive pending box (if present)
    try {
      await _pendingBox.delete(expenseId);
    } catch (e) {
      debugPrint('Hive delete failed: $e');
    }

    // 2. Fire-and-forget Firestore delete.
    _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .doc(expenseId)
        .delete()
        .catchError((e) {
      debugPrint('Firestore delete failed: $e');
    });
  }

  /// Gets aggregated spending for the current month, grouped by category.
  /// Returns a list of Map objects containing categoryId, totalAmount, and percentage.
  Future<List<Map<String, dynamic>>> getMonthlyBreakdown(String uid) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .get();

    final expenses = snap.docs.map(ExpenseModel.fromFirestore).toList();

    final Map<String, double> totals = {};
    double overallTotal = 0.0;

    for (final exp in expenses) {
      totals[exp.categoryId] = (totals[exp.categoryId] ?? 0.0) + exp.amount;
      overallTotal += exp.amount;
    }

    final breakdown = totals.entries.map((entry) {
      return {
        'categoryId': entry.key,
        'totalAmount': entry.value,
        'percentage': overallTotal > 0 ? (entry.value / overallTotal) * 100 : 0.0,
      };
    }).toList();

    // Sort descending by totalAmount
    breakdown.sort((a, b) => (b['totalAmount'] as double).compareTo(a['totalAmount'] as double));

    return breakdown;
  }
}

