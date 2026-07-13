import 'package:equatable/equatable.dart';
import 'package:masroufi/features/breakdown/data/models/breakdown_item.dart';

abstract class BreakdownState extends Equatable {
  const BreakdownState();

  @override
  List<Object?> get props => [];
}

class BreakdownInitial extends BreakdownState {
  const BreakdownInitial();
}

class BreakdownLoading extends BreakdownState {
  const BreakdownLoading();
}

class BreakdownLoaded extends BreakdownState {
  final List<BreakdownItem> items;
  final double totalAmount;

  const BreakdownLoaded({
    required this.items,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [items, totalAmount];
}

class BreakdownError extends BreakdownState {
  final String message;

  const BreakdownError(this.message);

  @override
  List<Object?> get props => [message];
}
