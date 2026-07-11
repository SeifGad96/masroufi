import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final double amount;
  final String categoryId;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final bool synced;

  const ExpenseModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.date,
    required this.createdAt,
    this.synced = false,
  });

  // ── Firestore Serialization ───────────────────────────────────────────────

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      categoryId: data['categoryId'] as String,
      note: data['note'] as String?,
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      synced: data['synced'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'synced': true,
    };
  }

  // ── Hive Map Serialization ───────────────────────────────────────────────

  factory ExpenseModel.fromHiveMap(Map<dynamic, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['categoryId'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      synced: map['synced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'synced': synced,
    };
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  ExpenseModel copyWith({
    String? id,
    double? amount,
    String? categoryId,
    String? note,
    DateTime? date,
    DateTime? createdAt,
    bool? synced,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          amount == other.amount &&
          categoryId == other.categoryId &&
          note == other.note &&
          date == other.date &&
          createdAt == other.createdAt &&
          synced == other.synced;

  @override
  int get hashCode =>
      id.hashCode ^
      amount.hashCode ^
      categoryId.hashCode ^
      note.hashCode ^
      date.hashCode ^
      createdAt.hashCode ^
      synced.hashCode;

  @override
  String toString() {
    return 'ExpenseModel(id: $id, amount: $amount, categoryId: $categoryId, synced: $synced)';
  }
}
