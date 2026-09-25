import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/constants.dart';
import '../models/directory_item.dart';
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

  bool _isGlobalSearchCancelled = false;

  void search(String query) {
    final currentState = state;
    if (currentState is DirectoryLoaded) {
      if (query.isEmpty) {
        cancelGlobalSearch();
        emit(
          currentState.copyWith(
            filteredItems: currentState.items,
            searchQuery: '',
            isGlobalSearch: false,
            isGlobalSearchLoading: false,
            scannedFoldersCount: 0,
          ),
        );
      } else {
        final filtered = currentState.items.where((item) {
          return item.name.toLowerCase().contains(query.toLowerCase());
        }).toList();

        emit(
          currentState.copyWith(
            filteredItems: filtered,
            searchQuery: query,
            isGlobalSearch: false,
            isGlobalSearchLoading: false,
          ),
        );
      }
    }
  }

  void startGlobalSearch(String query) async {
    final currentState = state;
    if (currentState is! DirectoryLoaded || query.trim().isEmpty) return;

    _isGlobalSearchCancelled = false;
    final foundItems = <DirectoryItem>[];

    emit(
      currentState.copyWith(
        searchQuery: query,
        filteredItems: [],
        isGlobalSearch: true,
        isGlobalSearchLoading: true,
        scannedFoldersCount: 0,
      ),
    );

    final stream = _directoryService.recursiveSearch(
      startPath: _currentServer.startPath,
      baseUrl: _currentServer.baseUrl,
      query: query,
      isCancelled: () => _isGlobalSearchCancelled,
      onProgress: (scanned, matches) {
        final st = state;
        if (st is DirectoryLoaded && st.isGlobalSearch) {
          emit(st.copyWith(scannedFoldersCount: scanned));
        }
      },
    );

    await for (final item in stream) {
      if (_isGlobalSearchCancelled) break;
      foundItems.add(item);
      final st = state;
      if (st is DirectoryLoaded && st.isGlobalSearch) {
        emit(st.copyWith(filteredItems: List.from(foundItems)));
      }
    }

    final st = state;
    if (st is DirectoryLoaded && st.isGlobalSearch) {
      emit(st.copyWith(isGlobalSearchLoading: false));
    }
  }

  void cancelGlobalSearch() {
    _isGlobalSearchCancelled = true;
    final currentState = state;
    if (currentState is DirectoryLoaded) {
      emit(currentState.copyWith(isGlobalSearchLoading: false));
    }
  }

  void clearSearch() {
    cancelGlobalSearch();
    final currentState = state;
    if (currentState is DirectoryLoaded) {
      emit(
        currentState.copyWith(
          filteredItems: currentState.items,
          searchQuery: '',
          isGlobalSearch: false,
          isGlobalSearchLoading: false,
          scannedFoldersCount: 0,
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
