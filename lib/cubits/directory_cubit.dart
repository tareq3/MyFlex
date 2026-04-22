import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/constants.dart';
import '../services/directory_service.dart';
import 'directory_state.dart';

class DirectoryCubit extends Cubit<DirectoryState> {
  final DirectoryService _directoryService;
  ServerConfig _currentServer = servers.first;

  DirectoryCubit({DirectoryService? directoryService})
    : _directoryService = directoryService ?? DirectoryService(),
      super(const DirectoryInitial());

  ServerConfig get currentServer => _currentServer;

  Future<void> loadDirectory(String path) async {
    emit(DirectoryLoading(path));

    try {
      final items = await _directoryService.fetchDirectory(
        path,
        baseUrl: _currentServer.baseUrl,
      );
      final pathSegments = _buildPathSegments(path);

      emit(
        DirectoryLoaded(
          path: path,
          items: items,
          filteredItems: items,
          pathSegments: pathSegments,
        ),
      );
    } catch (e) {
      emit(DirectoryError(message: e.toString(), path: path));
    }
  }

  void loadInitialDirectory() {
    loadDirectory(_currentServer.startPath);
  }

  void switchServer(ServerConfig server) {
    _currentServer = server;
    loadDirectory(server.startPath);
  }

  void navigateToDeepLink(ServerConfig server, String path) {
    _currentServer = server;
    loadDirectory(path);
  }

  void navigateToFolder(String folderPath) {
    loadDirectory(folderPath);
  }

  void navigateBack() {
    final currentState = state;
    if (currentState is DirectoryLoaded) {
      final segments = currentState.pathSegments;
      if (segments.length > 1) {
        final parentPath = segments[segments.length - 2];
        loadDirectory(parentPath);
      }
    }
  }

  void navigateToSegment(int index) {
    final currentState = state;
    if (currentState is DirectoryLoaded) {
      if (index < currentState.pathSegments.length) {
        final targetPath = currentState.pathSegments[index];
        loadDirectory(targetPath);
      }
    }
  }

  void search(String query) {
    final currentState = state;
    if (currentState is DirectoryLoaded) {
      if (query.isEmpty) {
        emit(
          currentState.copyWith(
            filteredItems: currentState.items,
            searchQuery: '',
          ),
        );
      } else {
        final filtered = currentState.items.where((item) {
          return item.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

        emit(
          currentState.copyWith(filteredItems: filtered, searchQuery: query),
        );
      }
    }
  }

  void clearSearch() {
    final currentState = state;
    if (currentState is DirectoryLoaded) {
      emit(
        currentState.copyWith(
          filteredItems: currentState.items,
          searchQuery: '',
        ),
      );
    }
  }

  void refresh() {
    final currentState = state;
    if (currentState is DirectoryLoaded) {
      loadDirectory(currentState.path);
    } else if (currentState is DirectoryError) {
      loadDirectory(currentState.path);
    }
  }

  List<String> _buildPathSegments(String path) {
    final segments = <String>['/'];
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();

    var currentPath = '';
    for (final part in parts) {
      currentPath = '$currentPath/$part';
      segments.add(currentPath);
    }

    return segments;
  }
}
