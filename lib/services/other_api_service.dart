import 'dart:convert';

import 'package:http/http.dart';
import 'package:nanday_twitch_app/models/result.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';

abstract class OtherApiService {
  ///
  /// Fetches a random dad joke from the APIs and returns it if no error were encountered, otherwise null
  ///
  Future<Result<String, String>> getRandomDadJoke();
}

class OtherApiServiceImpl implements OtherApiService {
  OtherApiServiceImpl(this._keysReader, this._loggerService);

  final TwitchKeysReader _keysReader;
  final LoggerService _loggerService;

  @override
  Future<Result<String, String>> getRandomDadJoke() async {
    String? rapidApiKey = (await _keysReader.getTwitchKeys()).rapidAPIKey;
    if (rapidApiKey == null) {
      _loggerService.e("OtherApiServiceImpl - getRandomDadJoke() - Missing RapidAPI key from keys json");
      return Result.withError("Missing API key");
    }

    Map<String, String> headers = {"X-RapidAPI-Key": rapidApiKey, "X-RapidAPI-Host": "dad-jokes.p.rapidapi.com"};
    Response response = await get(Uri.parse('https://dad-jokes.p.rapidapi.com/random/joke'), headers: headers);
    if (response.statusCode != 200) {
      _loggerService.e("OtherApiServiceImpl - getRandomDadJoke() - API returned error code ${response.statusCode} - ${response.reasonPhrase}");
      return Result.withError("API returned error code ${response.statusCode}");
    }

    try {
      dynamic json = jsonDecode(response.body);
      for (var entry in json['body']) {
        return Result.successful(entry['punchline']);
      }
      _loggerService.e("OtherApiServiceImpl - getRandomDadJoke() - Empty json['body']");
      return Result.withError("Empty response");
    } catch (e) {
      return Result.withError("Could not parse JSON object response");
    }
  }
}
