import 'package:masroufi/features/dashboard/data/models/dashboard_summary.dart';

abstract class DashboardState {
  const DashboardState();
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardSummary summary;

  const DashboardLoaded(this.summary);
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);
}