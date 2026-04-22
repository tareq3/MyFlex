import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/directory_item.dart';
import '../models/movie_info.dart';
import '../services/movie_service.dart';
import 'movie_info_state.dart';

class MovieInfoCubit extends Cubit<MovieInfoState> {
  final MovieService _movieService;
  final Map<String, MovieInfo> _cache = {};

  MovieInfoCubit({MovieService? movieService})
    : _movieService = movieService ?? MovieService(),
      super(const MovieInfoInitial());

  Future<void> fetchMovieInfo(DirectoryItem item) async {
    if (_cache.containsKey(item.path)) {
      emit(MovieInfoLoaded(Map.from(_cache)));
      return;
    }

    emit(MovieInfoLoading(item.path));

    try {
      final title = item.extractTitle();
      final year = item.extractYear();

      final movieInfo = await _movieService.fetchMovieInfo(title, year: year);
      _cache[item.path] = movieInfo;

      emit(MovieInfoLoaded(Map.from(_cache)));
    } catch (e) {
      _cache[item.path] = MovieInfo.notFound(item.displayName);
      emit(MovieInfoLoaded(Map.from(_cache)));
    }
  }

  Future<void> fetchAllMovieInfo(List<DirectoryItem> items) async {
    final videos = items.where((i) => i.isVideo).toList();

    for (final video in videos) {
      if (!_cache.containsKey(video.path)) {
        await fetchMovieInfo(video);
      }
    }
  }

  MovieInfo? getCachedInfo(String path) => _cache[path];

  void clearCache() {
    _cache.clear();
    emit(const MovieInfoInitial());
  }
}
