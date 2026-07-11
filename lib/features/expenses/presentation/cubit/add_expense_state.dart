import 'package:equatable/equatable.dart';

abstract class AddExpenseState extends Equatable {
  const AddExpenseState();

  @override
  List<Object?> get props => [];
}

class AddExpenseInitial extends AddExpenseState {
  const AddExpenseInitial();
}

class AddExpenseLoading extends AddExpenseState {
  const AddExpenseLoading();
}

class AddExpenseSuccess extends AddExpenseState {
  const AddExpenseSuccess();
}

class AddExpenseError extends AddExpenseState {
  final String message;

  const AddExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
