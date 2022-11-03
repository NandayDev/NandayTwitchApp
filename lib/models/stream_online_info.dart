import 'package:nanday_twitch_app/models/db_stream.dart';

class StreamOnlineInfo {
  StreamOnlineInfo(this.isStarted, this.streamTitle, this.dbStream);

  ///
  /// Whether the stream has started or not
  ///
  final bool isStarted;

  ///
  /// Title of the stream (null if not started)
  ///
  final String? streamTitle;

  ///
  /// Database stream associated with this info
  ///
  final DbStream? dbStream;
}
