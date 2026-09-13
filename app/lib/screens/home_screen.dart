import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/chat_controller.dart';
import 'browse_screen.dart';
import 'chat_screen.dart';

/// Root screen with the two main sections:
/// (a) Browse by organ / body system, (b) AI assistant.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // The greeting must be presented when the chat is first opened.
    if (_index == 1) {
      context.read<ChatController>().ensureGreeting();
    }
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          BrowseScreen(),
          ChatScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Assistant',
          ),
        ],
      ),
    );
  }
}
