class ChannelOnlineInfo {
  ChannelOnlineInfo(this.isStarted, this.streamTitle);

  ///
  /// Whether the stream has started or not
  ///
  final bool isStarted;

  ///
  /// Title of the stream (null if not started)
  ///
  final String? streamTitle;
}
