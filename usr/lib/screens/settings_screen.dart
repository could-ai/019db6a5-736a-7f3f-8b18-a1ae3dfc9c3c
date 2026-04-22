import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/library_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Local Library',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: const Text('Select Music Folder & Scan'),
              onPressed: library.isScanning
                  ? null
                  : () {
                      library.pickFolderAndScan();
                    },
            ),
            const SizedBox(height: 16),
            if (library.isScanning) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                library.scanStatus,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text('Tracks found: ${library.tracks.length}'),
              Text('Artists found: ${library.artists.length}'),
              Text('Albums found: ${library.albums.length}'),
            ],
          ],
        ),
      ),
    );
  }
}
