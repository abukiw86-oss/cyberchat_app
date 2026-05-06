enum AppStatus {
  initial,

  loading,

  success,

  failure,
}

/// Extension helpers for [AppStatus].
extension AppStatusX on AppStatus {
  bool get isInitial => this == AppStatus.initial;
  bool get isLoading => this == AppStatus.loading;
  bool get isSuccess => this == AppStatus.success;
  bool get isFailure => this == AppStatus.failure;
  bool get isDone => isSuccess || isFailure;
}
