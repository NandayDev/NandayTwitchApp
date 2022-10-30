class TwitchApiError {
  TwitchApiError(this.error, this.status, this.message);

  final String? error;
  final int? status;
  final String? message;
}

class StreamSchedule {
  StreamSchedule(this.elements);

  final List<StreamScheduleElement> elements;
}

class StreamScheduleElement {
  StreamScheduleElement(this.startTime, this.endTime, this.title);

  final DateTime startTime;
  final DateTime endTime;
  final String title;
}
