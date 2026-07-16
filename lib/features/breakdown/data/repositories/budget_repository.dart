import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:masroufi/features/breakdown/data/models/budget_model.dart';

class BudgetRepository {
  final FirebaseFirestore _firestore;

  BudgetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _budgetsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('budgets');

  /// Streams all category budgets for the user.
  Stream<List<BudgetModel>> watchBudgets(String uid) {
    return _budgetsRef(uid)
        .snapshots()
        .map((snap) => snap.docs.map(BudgetModel.fromFirestore).toList());
  }

  /// Gets all category budgets for the user once.
  Future<List<BudgetModel>> getBudgets(String uid) async {
    final snap = await _budgetsRef(uid).get();
    return snap.docs.map(BudgetModel.fromFirestore).toList();
  }

  /// Sets or updates a budget for a category.
  Future<void> setBudget({
    required String uid,
    required BudgetModel budget,
  }) async {
    await _budgetsRef(uid)
        .doc(budget.categoryId)
        .set(budget.toFirestore());
  }

  /// Deletes a budget for a category.
  Future<void> deleteBudget({
    required String uid,
    required String categoryId,
  }) async {
    await _budgetsRef(uid).doc(categoryId).delete();
  }
}
