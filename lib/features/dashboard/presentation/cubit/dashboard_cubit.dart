import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masroufi/features/auth/data/repositories/auth_repository.dart';
import 'package:masroufi/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:masroufi/features/dashboard/presentation/cubit/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardRepository _repository;
  final AuthRepository _authRepository;

  DashboardCubit({
    required DashboardRepository repository,
    required AuthRepository authRepository,
  })  : _repository = repository,
        _authRepository = authRepository,
        super(const DashboardInitial());

  Future<void> loadSummary() async {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null) {
      emit(const DashboardError('User is not authenticated'));
      return;
    }
    
    emit(const DashboardLoading());
    try {
      final summary = await _repository.getSummary(uid);
      emit(DashboardLoaded(summary));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
