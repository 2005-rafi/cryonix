/// Optional navigation args when opening [AttendanceScreen].
class AttendanceRouteArgs {
  const AttendanceRouteArgs({
    this.initialDate,
    this.initialTabIndex = 0,
  });

  final DateTime? initialDate;
  final int initialTabIndex;
}
