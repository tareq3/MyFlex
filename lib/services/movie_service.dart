import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../models/movie_info.dart';

class MovieService {
  final http.Client _client;
  final Map<String, MovieInfo> _cache = {};

  MovieService({http.Client? client}) : _client = client ?? http.Client();

  Future<MovieInfo> fetchMovieInfo(String title, {String? year}) async {
    final cacheKey = '${title}_$year';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final queryParams = <String, String>{
        'apikey': omdbApiKey,
        't': title,
        if (year != null) 'y': year,
      };

      final url = Uri.parse(omdbBaseUrl).replace(queryParameters: queryParams);
      final response = await _client.get(url);

      if (response.statusCode != 200) {
        return MovieInfo.notFound(title);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final movieInfo = MovieInfo.fromJson(json);
      _cache[cacheKey] = movieInfo;
      return movieInfo;
    } catch (e) {
      return MovieInfo.notFound(title);
    }
  }

  Future<MovieInfo?> searchMovie(String query) async {
    try {
      final queryParams = {'apikey': omdbApiKey, 's': query};

      final url = Uri.parse(omdbBaseUrl).replace(queryParameters: queryParams);
      final response = await _client.get(url);

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['Response'] == 'False') return null;

      final searchResults = json['Search'] as List?;
      if (searchResults == null || searchResults.isEmpty) return null;

      final firstResult = searchResults.first as Map<String, dynamic>;
      return fetchMovieInfo(firstResult['Title'], year: firstResult['Year']);
    } catch (e) {
      return null;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
