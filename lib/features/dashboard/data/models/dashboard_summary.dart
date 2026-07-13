import 'package:equatable/equatable.dart';

class DashboardSummary extends Equatable {
  final double todayTotal;
  final double weekTotal;
  final double monthTotal;

  const DashboardSummary({
    required this.todayTotal,
    required this.weekTotal,
    required this.monthTotal,
  });

  static const empty = DashboardSummary(
    todayTotal: 0.0,
    weekTotal: 0.0,
    monthTotal: 0.0,
  );

  @override
  List<Object?> get props => [todayTotal, weekTotal, monthTotal];
}
