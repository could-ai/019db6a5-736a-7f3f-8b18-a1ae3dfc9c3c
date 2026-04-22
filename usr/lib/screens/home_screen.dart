import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/audio_player_service.dart';
import 'latest_news_screen.dart';
import 'artists_screen.dart';
import 'network_screen.dart';
import 'settings_screen.dart';
import '../widgets/playback_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LatestNewsScreen(),
    const ArtistsScreen(),
    const NetworkScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<AudioPlayerService>();
    final showPlaybackBar = playerService.currentTrack != null;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
          if (showPlaybackBar) const PlaybackBar(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.new_releases), label: 'Latest News'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Artists'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Network'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
