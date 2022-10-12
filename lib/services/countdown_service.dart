abstract class CountdownService {

  Duration? parseCountdownDurationString(String durationString);

  Future awaitCountdown(Duration duration);
}

class CountdownServiceImpl implements CountdownService {

  static final RegExp _regExp = RegExp("(\\d{1,2}h)?(\\d{1,2}m)?(\\d{1,2}s)?");

  @override
  Duration? parseCountdownDurationString(String durationString) {
    Match? countdownMatch = _regExp.matchAsPrefix(durationString);
    if (countdownMatch == null) {
      return null;
    }
    int hours = _tryParseGroup(countdownMatch.group(1), "h");
    int minutes = _tryParseGroup(countdownMatch.group(2), "m");
    int seconds = _tryParseGroup(countdownMatch.group(3), "s");
    if (hours == 0 && minutes == 0 && seconds == 0) {
      return null;
    }
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  @override
  Future awaitCountdown(Duration duration) {
    return Future.delayed(duration);
  }

  int _tryParseGroup(String? groupString, String timeIndicator) {
    if (groupString == null) {
      return 0;
    }
    String hoursString = groupString.replaceFirst("h", "");
    return int.tryParse(hoursString) ?? 0;
  }
}