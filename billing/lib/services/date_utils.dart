class AppDateUtils {
  /// 1. Use for 'Date only' fields (like Onboarding Date, DOB).
  /// Sets time to 12:00:00 PM to prevent timezone shifts in UTC backends.
  static DateTime toServerDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, 12, 0, 0);
  }

  /// 2. Use for 'Full Timestamps' (like Transaction Time, CreatedAt).
  /// Converts local IST time to UTC for the server.
  static DateTime toServerDateTime(DateTime date) {
    return date.toUtc();
  }

  /// 3. Use to display server data to the user.
  /// Converts UTC from server back to local device time (IST).
  static DateTime fromServer(DateTime serverDate) {
    return serverDate.toLocal();
  }

  /// Helper to get ISO string for server
  static String toIsoDateString(DateTime date) {
    return toServerDate(date).toIso8601String();
  }
}
