import 'package:flutter/material.dart';
import 'package:money_tracker/screens/currency_settings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import 'profile_list_screen.dart';
import 'appearance_screen.dart';
import 'package:money_tracker/widgets/banner_ad_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _shareApp() {
    Share.share(
      'Track your expenses with Money Tracker!\n'
      'Download now: https://play.google.com/store/apps/details?id=com.fincalculators.moneytrack',
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    // Replace with your actual app store links
    const appStoreUrl = 'https://apps.apple.com/app/[your-app-id]';
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.fincalculators.moneytrack';

    final Uri url = Uri.parse(
      Theme.of(context).platform == TargetPlatform.iOS
          ? appStoreUrl
          : playStoreUrl,
    );

    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          final selectedProfile = provider.selectedProfile;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                Theme.of(context).brightness == Brightness.dark
                                    ? [
                                        const Color(0xFF2E5C88),
                                        const Color(0xFF15294D),
                                      ]
                                    : [
                                        const Color(0xFF2E5C88),
                                        const Color(0xFF1E3D59),
                                      ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF2E5C88).withOpacity(0.3)
                                  : const Color(0xFF2E5C88).withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical:
                                4, // Reduced from 12 to 4 to match other rows
                          ),
                          visualDensity: VisualDensity(
                              vertical:
                                  -4), // Added negative visual density for consistency
                          leading: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.25),
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            selectedProfile?.name ?? 'Profile 1',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(Icons.chevron_right, color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfileListScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(
                          height: 12), // Consistent spacing between sections
                      _buildSettingsCard(
                        context,
                        title: 'Currency',
                        subtitle: 'Change your preferred currency',
                        iconData: Icons.currency_exchange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CurrencySettingsScreen(),
                            ),
                          );
                        },
                        showTrailing: true,
                      ),
                      const SizedBox(height: 16),
                      _buildSettingsCard(
                        context,
                        title: 'Appearance',
                        subtitle: 'Theme, colors and display options',
                        iconData: Icons.palette_outlined,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AppearanceScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsCard(
                        context,
                        title: 'Share App',
                        subtitle: 'Tell your friends about Money Tracker',
                        iconData: Icons.share_outlined,
                        onTap: _shareApp,
                      ),
                      _buildSettingsCard(
                        context,
                        title: 'Rate Us',
                        subtitle: 'Love the app? Give us 5 stars!',
                        iconData: Icons.star_outline,
                        onTap: () => _rateApp(context),
                      ),
                      _buildSettingsCard(
                        context,
                        title: 'About',
                        subtitle: 'Version 1.0.0',
                        iconData: Icons.info_outline,
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'Money Tracker',
                            applicationVersion: '1.0.0',
                            applicationIcon: Icon(
                              Icons.account_balance_wallet,
                              size: 48,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF2E5C88)
                                  : const Color(0xFF2E5C88),
                            ),
                            children: [
                              const Text(
                                'A simple and intuitive app to track your personal finances, '
                                'manage expenses, and stay within your budget.',
                              ),
                            ],
                          );
                        },
                        showTrailing: true,
                      ),
                      _buildSettingsCard(
                        context,
                        title: 'Privacy',
                        subtitle: 'Privacy policy and terms',
                        iconData: Icons.privacy_tip_outlined,
                        onTap: () async {
                          const privacyUrl =
                              'https://fincalculators.com/privacy';
                          final Uri url = Uri.parse(privacyUrl);
                          if (!await launchUrl(url)) {
                            throw Exception('Could not launch \$url');
                          }
                        },
                        showTrailing: true,
                      ),
                      const SizedBox(
                          height: 16), // A bit of padding at the bottom
                    ],
                  ),
                ),
              ),
              // Add banner ad at the bottom
              const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData iconData,
    required VoidCallback onTap,
    bool showTrailing = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 3), // Further reduced vertical margin
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  Theme.of(context).colorScheme.surface,
                  Theme.of(context).colorScheme.surface.withOpacity(0.8),
                ]
              : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 1,
          ),
        ],
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2E5C88).withOpacity(0.1)
              : const Color(0xFF2E5C88).withOpacity(0.08),
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4, // Further reduced vertical padding
        ),
        visualDensity: VisualDensity(
            vertical:
                -4), // Add negative visual density to make it more compact
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2E5C88).withOpacity(0.15)
                : const Color(0xFF2E5C88).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            size: 22,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2E5C88)
                : const Color(0xFF2E5C88),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withOpacity(0.9)
                : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade400
                : Colors.grey.shade700,
          ),
        ),
        trailing: showTrailing
            ? Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2E5C88).withOpacity(0.1)
                      : const Color(0xFF2E5C88).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2E5C88)
                      : const Color(0xFF2E5C88),
                  size: 20,
                ),
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
