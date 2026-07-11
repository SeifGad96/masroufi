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
        .map((val) => ExpenseModel.fromHiveMap(Map<dynamic, dynamic>.from(val as Map)))
        .toList();
  }
}
