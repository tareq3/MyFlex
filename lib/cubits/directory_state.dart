import 'package:equatable/equatable.dart';

import '../models/directory_item.dart';

sealed class DirectoryState extends Equatable {
  const DirectoryState();

  @override
  List<Object?> get props => [];
}

class DirectoryInitial extends DirectoryState {
  const DirectoryInitial();
}

class DirectoryLoading extends DirectoryState {
  final String path;

  const DirectoryLoading(this.path);

  @override
  List<Object?> get props => [path];
}

class DirectoryLoaded extends DirectoryState {
  final String path;
  final List<DirectoryItem> items;
  final List<DirectoryItem> filteredItems;
  final String searchQuery;
  final List<String> pathSegments;

  const DirectoryLoaded({
    required this.path,
    required this.items,
    required this.filteredItems,
    this.searchQuery = '',
    required this.pathSegments,
  });

  int get folderCount => filteredItems.where((i) => i.isFolder).length;
  int get videoCount => filteredItems.where((i) => i.isVideo).length;
  int get imageCount => filteredItems.where((i) => i.isImage).length;

  DirectoryLoaded copyWith({
    String? path,
    List<DirectoryItem>? items,
    List<DirectoryItem>? filteredItems,
    String? searchQuery,
    List<String>? pathSegments,
  }) {
    return DirectoryLoaded(
      path: path ?? this.path,
      items: items ?? this.items,
      filteredItems: filteredItems ?? this.filteredItems,
      searchQuery: searchQuery ?? this.searchQuery,
      pathSegments: pathSegments ?? this.pathSegments,
    );
  }

  @override
  List<Object?> get props => [
    path,
    items,
    filteredItems,
    searchQuery,
    pathSegments,
  ];
}

class DirectoryError extends DirectoryState {
  final String message;
  final String path;

  const DirectoryError({required this.message, required this.path});

  @override
  List<Object?> get props => [message, path];
}
