import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/library_service.dart';
import '../services/audio_player_service.dart';

class ArtistsScreen extends StatelessWidget {
  const ArtistsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();
    final artists = library.artists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artists'),
      ),
      body: artists.isEmpty
          ? const Center(child: Text('No artists found.'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArtistDetailScreen(artist: artist),
                      ),
                    );
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: artist.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: artist.coverUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 50),
                                )
                              : const Icon(Icons.person, size: 50),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          color: Colors.black54,
                          child: Text(
                            artist.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ArtistDetailScreen extends StatelessWidget {
  final artist;
  const ArtistDetailScreen({Key? key, required this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayerService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name),
      ),
      body: ListView.builder(
        itemCount: artist.tracks.length,
        itemBuilder: (context, index) {
          final track = artist.tracks[index];
          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(track.title),
            subtitle: Text(track.album),
            onTap: () {
              player.playTrack(track, artist.tracks);
            },
          );
        },
      ),
    );
  }
}
