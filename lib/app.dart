import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tacit_understanding/config.dart';
import 'package:tacit_understanding/providers/game_provider.dart';
import 'package:tacit_understanding/screens/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        Supabase.initialize(
          url: Config.supabaseUrl,
          anonKey: Config.supabaseAnonKey,
        ),
        // 初始化 GameProvider
        Future.microtask(() async {
          final gameProvider = GameProvider();
          await gameProvider.initialize();
          return gameProvider;
        })
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('初始化失败: ${snapshot.error}'),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          final gameProvider = snapshot.data![1] as GameProvider;
          return MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: gameProvider),
            ],
            child: MaterialApp(
              title: '默契挑战',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                visualDensity: VisualDensity.adaptivePlatformDensity,
              ),
              home: const SplashScreen(),
              debugShowCheckedModeBanner: false,
            ),
          );
        }
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
