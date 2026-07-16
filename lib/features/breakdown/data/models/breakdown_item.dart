import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class BreakdownItem extends Equatable {
  final String categoryId;
  final String categoryName;
  final Color categoryColor;
  final double totalAmount;
  final double percentage;
  final double? budgetLimit;

  const BreakdownItem({
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.totalAmount,
    required this.percentage,
    this.budgetLimit,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        categoryColor,
        totalAmount,
        percentage,
        budgetLimit,
      ];
}
