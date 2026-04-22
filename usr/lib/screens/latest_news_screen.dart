import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/library_service.dart';
import '../services/audio_player_service.dart';

class LatestNewsScreen extends StatelessWidget {
  const LatestNewsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final player = context.read<AudioPlayerService>();
    final recentTracks = library.recentTracks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest News'),
      ),
      body: recentTracks.isEmpty
          ? const Center(child: Text('No tracks found. Go to Settings to scan.'))
          : ListView.builder(
              itemCount: recentTracks.length,
              itemBuilder: (context, index) {
                final track = recentTracks[index];
                
                final actualAlbum = library.albums.where((a) => a.name == track.album && a.artist == track.artist).firstOrNull;
                final coverPath = actualAlbum?.localCoverPath;

                return ListTile(
                  leading: coverPath != null
                      ? Image.file(File(coverPath), width: 50, height: 50, fit: BoxFit.cover)
                      : Container(width: 50, height: 50, color: Colors.grey[800], child: const Icon(Icons.music_note)),
                  title: Text(track.title),
                  subtitle: Text('${track.artist} • ${track.album}'),
                  onTap: () {
                    player.playTrack(track, recentTracks);
                  },
                );
              },
            ),
    );
  }
}
