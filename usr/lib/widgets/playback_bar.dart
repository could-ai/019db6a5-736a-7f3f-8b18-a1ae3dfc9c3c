import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_player_service.dart';
import '../services/library_service.dart';

class PlaybackBar extends StatelessWidget {
  const PlaybackBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final library = context.watch<LibraryService>();
    final track = player.currentTrack;

    if (track == null) return const SizedBox.shrink();

    // Find the album to get the local cover path
    final albumKey = '${track.artist} - ${track.album}';
    final album = library.albums.firstWhere(
      (a) => a.name == track.album && a.artist == track.artist,
      orElse: () => library.albums.first, // fallback, though it might not be accurate if not found
    );
    
    // In case the album isn't actually the correct one
    final actualAlbum = library.albums.where((a) => a.name == track.album && a.artist == track.artist).firstOrNull;
    final coverPath = actualAlbum?.localCoverPath;

    return Container(
      color: Theme.of(context).bottomAppBarTheme.color ?? Colors.grey[900],
      height: 70,
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: player.duration.inMilliseconds > 0 
                ? player.position.inMilliseconds / player.duration.inMilliseconds 
                : 0.0,
            minHeight: 2,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
          Expanded(
            child: Row(
              children: [
                if (coverPath != null)
                  Image.file(
                    File(coverPath),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () => player.skipToPrevious(),
                ),
                IconButton(
                  icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (player.isPlaying) {
                      player.pause();
                    } else {
                      player.resume();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => player.skipToNext(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
