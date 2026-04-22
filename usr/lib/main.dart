import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/audio_player_service.dart';
import 'services/library_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
        ChangeNotifierProvider(create: (_) => LibraryService()..init()),
      ],
      child: MaterialApp(
        title: 'Local Audio Player',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.blueAccent,
          colorScheme: ColorScheme.dark(
            primary: Colors.blueAccent,
            secondary: Colors.lightBlueAccent,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
