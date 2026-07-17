import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BudgetModel extends Equatable {
  final String categoryId;
  final double limit;
  final String month; 

  const BudgetModel({
    required this.categoryId,
    required this.limit,
    required this.month,
  });

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      categoryId: doc.id,
      limit: (data['limit'] as num).toDouble(),
      month: data['month'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'limit': limit,
      'month': month,
    };
  }

  @override
  List<Object?> get props => [categoryId, limit, month];
}
