import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/theme_controller.dart';

/// App Bar action button for toggling between Light and Dark mode.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final isDark = themeController.isDarkMode(context);

    return Tooltip(
      message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      child: IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
          child: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            key: ValueKey<bool>(isDark),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onPressed: () => themeController.toggleTheme(context),
      ),
    );
  }
}
