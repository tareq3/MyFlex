import 'package:equatable/equatable.dart';

class MovieInfo extends Equatable {
  final String title;
  final String? year;
  final String? rated;
  final String? released;
  final String? runtime;
  final String? genre;
  final String? director;
  final String? actors;
  final String? plot;
  final String? poster;
  final String? imdbRating;
  final String? imdbId;
  final bool found;

  const MovieInfo({
    required this.title,
    this.year,
    this.rated,
    this.released,
    this.runtime,
    this.genre,
    this.director,
    this.actors,
    this.plot,
    this.poster,
    this.imdbRating,
    this.imdbId,
    this.found = true,
  });

  factory MovieInfo.notFound(String title) {
    return MovieInfo(title: title, found: false);
  }

  factory MovieInfo.fromJson(Map<String, dynamic> json) {
    if (json['Response'] == 'False') {
      return MovieInfo.notFound(json['Title'] ?? 'Unknown');
    }
    return MovieInfo(
      title: json['Title'] ?? 'Unknown',
      year: json['Year'],
      rated: json['Rated'],
      released: json['Released'],
      runtime: json['Runtime'],
      genre: json['Genre'],
      director: json['Director'],
      actors: json['Actors'],
      plot: json['Plot'],
      poster: json['Poster'] != 'N/A' ? json['Poster'] : null,
      imdbRating: json['imdbRating'] != 'N/A' ? json['imdbRating'] : null,
      imdbId: json['imdbID'],
    );
  }

  bool get hasPoster => poster != null && poster!.isNotEmpty;
  bool get hasRating => imdbRating != null && imdbRating!.isNotEmpty;

  @override
  List<Object?> get props => [
    title,
    year,
    rated,
    released,
    runtime,
    genre,
    director,
    actors,
    plot,
    poster,
    imdbRating,
    imdbId,
    found,
  ];
}
