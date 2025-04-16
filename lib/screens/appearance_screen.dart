import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance'), elevation: 0),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        Theme.of(context).brightness == Brightness.dark
                            ? [const Color(0xFF2E5C88), const Color(0xFF15294D)]
                            : [
                              const Color(0xFF2E5C88),
                              const Color(0xFF1E3D59),
                            ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2E5C88).withOpacity(0.3)
                              : const Color(0xFF2E5C88).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.25),
                          child: Icon(
                            Icons.brightness_medium,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose your preferred theme mode',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildThemeOption(
                context,
                title: 'System Theme',
                subtitle: 'Follow system settings',
                iconData: Icons.brightness_auto,
                isSelected: themeProvider.themeMode == ThemeMode.system,
                onTap: () => themeProvider.setThemeMode(ThemeMode.system),
              ),
              _buildThemeOption(
                context,
                title: 'Light Theme',
                subtitle: 'Light colors and white background',
                iconData: Icons.light_mode,
                isSelected: themeProvider.themeMode == ThemeMode.light,
                onTap: () => themeProvider.setThemeMode(ThemeMode.light),
              ),
              _buildThemeOption(
                context,
                title: 'Dark Theme',
                subtitle: 'Dark colors and black background',
                iconData: Icons.dark_mode,
                isSelected: themeProvider.themeMode == ThemeMode.dark,
                onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.8)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2E5C88).withOpacity(0.1)
                            : const Color(0xFF2E5C88).withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2E5C88).withOpacity(0.15)
                                    : const Color(0xFF2E5C88).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.info_outline,
                            size: 20,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFF2E5C88)
                                    : const Color(0xFF2E5C88),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'About Themes',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.9)
                                    : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The app theme will change the colors and appearance of the entire app. Light theme is ideal for daytime use, while dark theme reduces eye strain in low-light environments.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'System theme automatically switches between light and dark modes based on your device settings.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData iconData,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isSelected
                  ? Theme.of(context).brightness == Brightness.dark
                      ? [
                        const Color(0xFF2E5C88).withOpacity(0.2),
                        const Color(0xFF15294D).withOpacity(0.15),
                      ]
                      : [
                        const Color(0xFF2E5C88).withOpacity(0.15),
                        const Color(0xFF1E3D59).withOpacity(0.1),
                      ]
                  : Theme.of(context).brightness == Brightness.dark
                  ? [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withOpacity(0.7),
                  ]
                  : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color:
              isSelected
                  ? Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2E5C88).withOpacity(0.3)
                      : const Color(0xFF2E5C88).withOpacity(0.3)
                  : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2E5C88).withOpacity(0.15)
                    : const Color(0xFF2E5C88).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color:
                isSelected
                    ? const Color(0xFF2E5C88)
                    : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.grey.shade700,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.9)
                    : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
          ),
        ),
        trailing:
            isSelected
                ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF2E5C88).withOpacity(0.2)
                            : const Color(0xFF2E5C88).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: const Color(0xFF2E5C88),
                    size: 20,
                  ),
                )
                : null,
        onTap: onTap,
      ),
    );
  }
}
