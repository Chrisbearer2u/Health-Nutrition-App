import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/knowledge_repository.dart';
import 'screens/home_screen.dart';
import 'state/chat_controller.dart';
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
        Provider<ChatController>(
          create: (_) => ChatController(),
          dispose: (_, c) => c.dispose(),
        ),
        FutureProvider<KnowledgeRepository>(
          create: (_) => KnowledgeRepository.load(),
          initialData: KnowledgeRepository.empty,
          catchError: (_, __) => KnowledgeRepository.empty,
        ),
      ],
      child: MaterialApp(
        title: 'NutriGuide',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const HomeScreen(),
      ),
    );
  }
}
