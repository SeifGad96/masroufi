import 'package:masroufi/features/breakdown/data/models/breakdown_item.dart';

abstract class BreakdownState {
  const BreakdownState();
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
}

class BreakdownError extends BreakdownState {
  final String message;

  const BreakdownError(this.message);
}