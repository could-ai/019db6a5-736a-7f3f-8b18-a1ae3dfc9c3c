import 'dart:convert';

class Track {
  final String id;
  final String path;
  final String title;
  final String artist;
  final String album;
  final int durationMs;

  Track({
    required this.id,
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'title': title,
    'artist': artist,
    'album': album,
    'durationMs': durationMs,
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    path: json['path'],
    title: json['title'],
    artist: json['artist'],
    album: json['album'],
    durationMs: json['durationMs'],
  );
}

class Artist {
  final String name;
  String? coverUrl;
  final List<Track> tracks;

  Artist({
    required this.name,
    this.coverUrl,
    required this.tracks,
  });
}

class Album {
  final String name;
  final String artist;
  final List<Track> tracks;
  final String? localCoverPath;

  Album({
    required this.name,
    required this.artist,
    required this.tracks,
    this.localCoverPath,
  });
}
