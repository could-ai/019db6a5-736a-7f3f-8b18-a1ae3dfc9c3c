import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../models/models.dart';

class LibraryService extends ChangeNotifier {
  List<Track> _tracks = [];
  Map<String, Artist> _artistsMap = {};
  Map<String, Album> _albumsMap = {};
  
  bool _isScanning = false;
  String _scanStatus = '';

  List<Track> get tracks => _tracks;
  List<Artist> get artists => _artistsMap.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  List<Album> get albums => _albumsMap.values.toList()..sort((a, b) => a.name.compareTo(b.name));
  
  // Latest News (Recent tracks)
  List<Track> get recentTracks => List.from(_tracks.reversed.take(50));

  bool get isScanning => _isScanning;
  String get scanStatus => _scanStatus;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final tracksJson = prefs.getString('library_tracks');
    if (tracksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(tracksJson);
        _tracks = decoded.map((e) => Track.fromJson(e)).toList();
        await _rebuildGraph();
      } catch (e) {
        debugPrint('Error loading library: $e');
      }
    }
  }

  Future<void> pickFolderAndScan() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      await _scanDirectory(Directory(selectedDirectory));
    }
  }

  Future<void> _scanDirectory(Directory dir) async {
    _isScanning = true;
    _scanStatus = 'Finding files...';
    notifyListeners();

    final List<File> audioFiles = [];
    final allowedExts = ['.mp3', '.flac', '.wav', '.m4a', '.ogg'];

    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (allowedExts.contains(ext)) {
            audioFiles.add(entity);
          }
        }
      }
    } catch (e) {
      debugPrint('Error listing files: $e');
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(docsDir.path, 'album_covers'));
    if (!await coversDir.exists()) {
      await coversDir.create();
    }

    int count = 0;
    List<Track> newTracks = [];

    for (final file in audioFiles) {
      count++;
      _scanStatus = 'Scanning $count / ${audioFiles.length}...';
      if (count % 10 == 0) notifyListeners();

      try {
        final metadata = await MetadataRetriever.fromFile(file);
        
        final title = metadata.trackName ?? p.basenameWithoutExtension(file.path);
        final artist = metadata.trackArtistNames?.join(', ') ?? metadata.albumArtistName ?? 'Unknown Artist';
        final album = metadata.albumName ?? 'Unknown Album';
        final duration = metadata.trackDuration ?? 0;

        String? localCoverPath;
        if (metadata.albumArt != null) {
          final safeAlbumName = album.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
          final coverFile = File(p.join(coversDir.path, '$safeAlbumName.jpg'));
          if (!await coverFile.exists()) {
            await coverFile.writeAsBytes(metadata.albumArt!);
          }
          localCoverPath = coverFile.path;
        }

        newTracks.add(Track(
          id: file.path,
          path: file.path,
          title: title,
          artist: artist,
          album: album,
          durationMs: duration,
        ));
      } catch (e) {
        debugPrint('Error reading metadata for ${file.path}: $e');
        newTracks.add(Track(
          id: file.path,
          path: file.path,
          title: p.basenameWithoutExtension(file.path),
          artist: 'Unknown Artist',
          album: 'Unknown Album',
          durationMs: 0,
        ));
      }
    }

    _tracks = newTracks;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('library_tracks', jsonEncode(_tracks.map((t) => t.toJson()).toList()));

    await _rebuildGraph();
    
    _isScanning = false;
    _scanStatus = 'Completed';
    notifyListeners();
    
    _fetchMissingArtistCovers();
  }

  Future<void> _rebuildGraph() async {
    _artistsMap.clear();
    _albumsMap.clear();

    final docsDir = await getApplicationDocumentsDirectory();
    final coversDir = Directory(p.join(docsDir.path, 'album_covers'));

    for (final track in _tracks) {
      if (!_artistsMap.containsKey(track.artist)) {
        _artistsMap[track.artist] = Artist(name: track.artist, tracks: []);
      }
      _artistsMap[track.artist]!.tracks.add(track);

      final albumKey = '${track.artist} - ${track.album}';
      if (!_albumsMap.containsKey(albumKey)) {
        final safeAlbumName = track.album.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final potentialCoverPath = p.join(coversDir.path, '$safeAlbumName.jpg');
        final hasCover = await File(potentialCoverPath).exists();

        _albumsMap[albumKey] = Album(
          name: track.album,
          artist: track.artist,
          tracks: [],
          localCoverPath: hasCover ? potentialCoverPath : null,
        );
      }
      _albumsMap[albumKey]!.tracks.add(track);
    }
    
    // Load cached artist covers
    final prefs = await SharedPreferences.getInstance();
    for (final artist in _artistsMap.values) {
      final cachedCover = prefs.getString('artist_cover_${artist.name}');
      if (cachedCover != null) {
        artist.coverUrl = cachedCover;
      }
    }
    
    notifyListeners();
  }
  
  Future<void> _fetchMissingArtistCovers() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final artist in _artistsMap.values) {
      if (artist.coverUrl == null && artist.name != 'Unknown Artist') {
        try {
          final url = Uri.parse('https://www.theaudiodb.com/api/v1/json/2/search.php?s=${Uri.encodeComponent(artist.name)}');
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['artists'] != null && data['artists'].isNotEmpty) {
              final thumb = data['artists'][0]['strArtistThumb'];
              if (thumb != null && thumb.toString().isNotEmpty) {
                artist.coverUrl = thumb;
                await prefs.setString('artist_cover_${artist.name}', thumb);
                notifyListeners();
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching cover for ${artist.name}: $e');
        }
      }
    }
  }
}
