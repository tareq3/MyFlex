import 'package:equatable/equatable.dart';

import '../models/movie_info.dart';

sealed class MovieInfoState extends Equatable {
  const MovieInfoState();

  @override
  List<Object?> get props => [];
}

class MovieInfoInitial extends MovieInfoState {
  const MovieInfoInitial();
}

class MovieInfoLoading extends MovieInfoState {
  final String itemPath;

  const MovieInfoLoading(this.itemPath);

  @override
  List<Object?> get props => [itemPath];
}

class MovieInfoLoaded extends MovieInfoState {
  final Map<String, MovieInfo> movieInfoMap;

  const MovieInfoLoaded(this.movieInfoMap);

  MovieInfo? getInfo(String path) => movieInfoMap[path];

  @override
  List<Object?> get props => [movieInfoMap];
}

class MovieInfoError extends MovieInfoState {
  final String message;

  const MovieInfoError(this.message);

  @override
  List<Object?> get props => [message];
}
