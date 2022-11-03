class DbStream {

  DbStream(this.twitchId, this.title, this.startTimestampUtc, this.endTimestampUtc, { this.databaseId, this.flags = 0 });

  final int? databaseId;
  final String twitchId;
  final String title;
  final int startTimestampUtc;
  final int? endTimestampUtc;
  int flags = 0;

  bool get isOpen => endTimestampUtc == null;

  bool get discordStartMessageSent => _isFlagsBitSet(0);
  set discordStartMessageSent(bool value) => _setFlagBit(0, value);

  bool get discordEndMessageSent => _isFlagsBitSet(1);
  set discordEndMessageSent(bool value) => _setFlagBit(1, value);

  bool get countsReset => _isFlagsBitSet(2);
  set countsReset(bool value) => _setFlagBit(2, value);

  bool _isFlagsBitSet(int bitIndex) => (flags & (1 << bitIndex)) != 0;
  void _setFlagBit(int bitIndex, bool value) {
    if (value) {
      flags |= 1 << bitIndex;
    } else {
      flags &= ~(1 << bitIndex);
    }
  }
}