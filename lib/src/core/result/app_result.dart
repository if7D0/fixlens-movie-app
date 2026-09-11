/// Sealed result type for all data-layer calls (锁定 Phase 1).
///
/// UI layers must handle [AppErr] via [AppError] widget.
/// Raw throws must never reach widgets.
sealed class AppResult<T> {
  const AppResult();
}

/// Success case carrying [data].
final class AppOk<T> extends AppResult<T> {
  final T data;
  const AppOk(this.data);
}

/// Failure case carrying a user-safe [message].
final class AppErr<T> extends AppResult<T> {
  final String message;
  const AppErr(this.message);
}
