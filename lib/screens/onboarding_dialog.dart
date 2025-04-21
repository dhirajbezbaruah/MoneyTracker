import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class ThemeSelector extends StatefulWidget {
  @override
  _ThemeSelectorState createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  ThemeMode _selectedThemeMode = ThemeMode.system;

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.brightness_auto,
                color: _selectedThemeMode == ThemeMode.system
                    ? const Color(0xFF2E5C88)
                    : null,
              ),
              title: const Text('System Theme'),
              subtitle: const Text('Follow system settings'),
              trailing: _selectedThemeMode == ThemeMode.system
                  ? const Icon(Icons.check, color: Color(0xFF2E5C88))
                  : null,
              onTap: () {
                setState(() => _selectedThemeMode = ThemeMode.system);
                context.read<ThemeProvider>().setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.light_mode,
                color: _selectedThemeMode == ThemeMode.light
                    ? const Color(0xFF2E5C88)
                    : null,
              ),
              title: const Text('Light Theme'),
              subtitle: const Text('Light colors and white background'),
              trailing: _selectedThemeMode == ThemeMode.light
                  ? const Icon(Icons.check, color: Color(0xFF2E5C88))
                  : null,
              onTap: () {
                setState(() => _selectedThemeMode = ThemeMode.light);
                context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: _selectedThemeMode == ThemeMode.dark
                    ? const Color(0xFF2E5C88)
                    : null,
              ),
              title: const Text('Dark Theme'),
              subtitle: const Text('Dark colors and black background'),
              trailing: _selectedThemeMode == ThemeMode.dark
                  ? const Icon(Icons.check, color: Color(0xFF2E5C88))
                  : null,
              onTap: () {
                setState(() => _selectedThemeMode = ThemeMode.dark);
                context.read<ThemeProvider>().setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _showThemeSelector,
      child: const Text('Select Theme'),
    );
  }
}
