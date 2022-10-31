import 'dart:convert';

import 'package:http/http.dart';
import 'package:nanday_twitch_app/models/result.dart';
import 'package:nanday_twitch_app/models/twich_api_responses.dart';
import 'package:nanday_twitch_app/services/session_repository.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';

class TwitchApiService {
  TwitchApiService(this._authenticationService, this._sessionRepository);

  final TwitchAuthenticationService _authenticationService;
  final SessionRepository _sessionRepository;

  Future<TwitchApiResult<StreamSchedule>> getStreamSchedule() {
    String url = 'https://api.twitch.tv/helix/schedule?broadcaster_id=${_sessionRepository.userId}';
    return _invokeGetRequest<StreamSchedule>(url, (json) {
      List<StreamScheduleElement> elements = [];
      for (dynamic segment in json['data']['segments']) {
        elements.add(StreamScheduleElement(DateTime.parse(segment['start_time']), DateTime.parse(segment['end_time']), segment['title']));
      }
      return StreamSchedule(elements);
    });
  }

  Future<TwitchApiResult<T>> _invokeGetRequest<T>(String url, T Function(dynamic) func) async {
    try {
      var headers = _authenticationService.generateApiHeaders();
      Uri uri = Uri.parse(url);
      Response response = await get(uri, headers: headers);
      dynamic responseJson = jsonDecode(response.body);
      if (response.statusCode == 200) {
        T result = func(responseJson);
        return TwitchApiResult.successful(result);
      } else {
        return TwitchApiResult.withError(TwitchApiError(responseJson['error'], responseJson['status'], responseJson['message']));
      }
    } catch (e) {
      return TwitchApiResult.withError(TwitchApiError(null, null, e.toString()));
    }
  }
}

class TwitchApiResult<T> extends Result<T, TwitchApiError> {
  TwitchApiResult.successful(T result) : super(result: result);

  TwitchApiResult.withError(TwitchApiError error) : super(error: error);
}
