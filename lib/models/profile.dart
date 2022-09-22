class Profile {
  Profile(this.botUsername, this.channelName, this.browserExecutable, this.botLanguage, { this.id });

  final int? id;
  final String botUsername;
  final String channelName;
  final String botLanguage;
  final String? browserExecutable;
}