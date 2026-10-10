import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/knowledge_repository.dart';
import 'screens/home_screen.dart';
import 'state/chat_controller.dart';
import 'state/theme_controller.dart';
import 'theme.dart';

void main() {
  runApp(const NutriGuideApp());
}

class NutriGuideApp extends StatelessWidget {
  const NutriGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
        ChangeNotifierProvider<ChatController>(
          create: (_) => ChatController(),
        ),
        FutureProvider<KnowledgeRepository>(
          create: (_) => KnowledgeRepository.load(),
          initialData: KnowledgeRepository.empty,
          catchError: (_, __) => KnowledgeRepository.empty,
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'NutriGuide',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeController.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
