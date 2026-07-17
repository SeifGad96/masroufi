import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:masroufi/features/expenses/data/models/expense_model.dart';

class ExpenseDataSource {
  final FirebaseFirestore _firestore;
  final Box _pendingBox;

  ExpenseDataSource({
    FirebaseFirestore? firestore,
    Box? pendingBox,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _pendingBox = pendingBox ?? Hive.box('pending_expenses');

  

  
  
  
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

    
    try {
      await _pendingBox.put(id, expense.toHiveMap());
    } catch (e) {
      debugPrint('Hive write failed: $e');
    }

    
    
    
    
    
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

  

  
  Stream<List<ExpenseModel>> watchExpenses(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ExpenseModel.fromFirestore).toList());
  }

  
  Future<List<ExpenseModel>> getExpenses(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map(ExpenseModel.fromFirestore).toList();
  }

  
  List<ExpenseModel> getUnsyncedExpenses() {
    return _pendingBox.values
        .map((val) => ExpenseModel.fromHiveMap(Map<dynamic, dynamic>.from(val as Map))
        )
        .toList();
  }

  
  Future<ExpenseModel> updateExpense({
    required String uid,
    required ExpenseModel expense,
  }) async {
    
    try {
      await _pendingBox.put(expense.id, expense.toHiveMap());
    } catch (e) {
      debugPrint('Hive write failed: $e');
    }

    
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

  
  Future<void> deleteExpense({
    required String uid,
    required String expenseId,
  }) async {
    
    try {
      await _pendingBox.delete(expenseId);
    } catch (e) {
      debugPrint('Hive delete failed: $e');
    }

    
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

    
    breakdown.sort((a, b) => (b['totalAmount'] as double).compareTo(a['totalAmount'] as double));

    return breakdown;
  }
}
