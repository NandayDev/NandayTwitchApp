///
/// Session data shared across the application
///
class SessionRepository {
  ///
  /// Streamer's username
  ///
  late String username;

  ///
  /// Streamer's display name (username with caps)
  ///
  late String userDisplayName;

  ///
  /// Access token provided by the authentication method
  ///
  late String accessToken;

  ///
  /// Twitch ID of the user
  ///
  late int userId;

  ///
  /// Since when the stream is live; if not live, null
  ///
  DateTime? streamLiveSince;
}
