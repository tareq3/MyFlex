import 'package:dhaka_flix/models/directory_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DirectoryItem extractTitle', () {
    test('extracts title cleanly without resolution, quality, or year', () {
      const item = DirectoryItem(
        name: 'Inception.2010.1080p.BluRay.x264.mkv',
        path: '/movies/Inception.2010.1080p.BluRay.x264.mkv',
        type: DirectoryItemType.video,
      );
      expect(item.extractTitle(), 'Inception');
    });

    test('truncates at special characters like parentheses', () {
      const item = DirectoryItem(
        name: 'Interstellar (2014) [1080p] Dual Audio.mkv',
        path: '/movies/Interstellar (2014) [1080p] Dual Audio.mkv',
        type: DirectoryItemType.video,
      );
      expect(item.extractTitle(), 'Interstellar');
    });

    test('truncates at slashes and brackets', () {
      const item = DirectoryItem(
        name: 'The Dark Knight / Batman 2 [720p].mp4',
        path: '/movies/The Dark Knight / Batman 2 [720p].mp4',
        type: DirectoryItemType.video,
      );
      expect(item.extractTitle(), 'The Dark Knight');
    });

    test('handles title with multiple words before special characters', () {
      const item = DirectoryItem(
        name: 'Avatar The Way of Water (Extended Cut).mkv',
        path: '/movies/Avatar The Way of Water (Extended Cut).mkv',
        type: DirectoryItemType.video,
      );
      expect(item.extractTitle(), 'Avatar The Way of Water');
    });

    test('ignores release sources like AMZN, Amazon, Netflix, NF', () {
      const item = DirectoryItem(
        name: 'Stranger Things AMZN 1080p.mkv',
        path: '/movies/Stranger Things AMZN 1080p.mkv',
        type: DirectoryItemType.video,
      );
      expect(item.extractTitle(), 'Stranger Things');
    });

    test('preserves & character in title', () {
      const item = DirectoryItem(
        name: 'Dungeons & Dragons Honor Among Thieves (2023).mkv',
        path: '/movies/Dungeons & Dragons Honor Among Thieves (2023).mkv',
        type: DirectoryItemType.video,
      );
      expect(item.extractTitle(), 'Dungeons & Dragons Honor Among Thieves');
    });
  });
}
