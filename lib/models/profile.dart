class Profile {
  Profile(this.botUsername, this.channelName, this.browserExecutable, { this.id });

  final int? id;
  final String botUsername;
  final String channelName;
  final String? browserExecutable;

  ///
  /// Returns a new Profile with given id
  ///
  Profile cloneWithId(int? id) {
    return Profile(botUsername, channelName, browserExecutable, id: id);
  }
}