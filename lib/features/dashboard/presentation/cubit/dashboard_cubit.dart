import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masroufi/features/auth/data/data_sources/auth_data_source.dart';
import 'package:masroufi/features/dashboard/data/data_sources/dashboard_data_source.dart';
import 'package:masroufi/features/dashboard/presentation/cubit/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final DashboardDataSource _dataSource;
  final AuthDataSource _authDataSource;

  DashboardCubit({
    required DashboardDataSource dataSource,
    required AuthDataSource authDataSource,
  })  : _dataSource = dataSource,
        _authDataSource = authDataSource,
        super(const DashboardInitial());

  Future<void> loadSummary() async {
    final uid = _authDataSource.currentUser?.uid;
    if (uid == null) {
      emit(const DashboardError('User is not authenticated'));
      return;
    }
    
    emit(const DashboardLoading());
    try {
      final summary = await _dataSource.getSummary(uid);
      emit(DashboardLoaded(summary));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }
}
