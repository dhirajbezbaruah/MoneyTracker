import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/profile.dart';
import 'profile_screen.dart';
import 'package:money_tracker/widgets/native_ad_widget.dart';
import 'package:money_tracker/widgets/banner_ad_widget.dart';

class ProfileListScreen extends StatelessWidget {
  const ProfileListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                return ListView.builder(
                  itemCount: provider.profiles.length,
                  itemBuilder: (context, index) {
                    final profile = provider.profiles[index];
                    final isSelected = profile.isSelected;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: Theme.of(context).brightness ==
                                        Brightness.dark
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
                              )
                            : null,
                        color: isSelected
                            ? null
                            : Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[900]
                                : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF2E5C88).withOpacity(0.15)
                                    : const Color(0xFF2E5C88).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconData(profile.iconName),
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF2E5C88)
                                    : const Color(0xFF2E5C88),
                          ),
                        ),
                        title: Text(
                          profile.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: isSelected
                            ? Text(
                                'Active Profile',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isSelected) ...[
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(
                                        profile: profile,
                                        isEditing: true,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Profile'),
                                      content: Text(
                                          'Are you sure you want to delete ${profile.name}?'),
                                      actions: [
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                        ),
                                        TextButton(
                                          child: const Text('Delete'),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await provider.deleteProfile(profile.id!);
                                  }
                                },
                              ),
                            ],
                            if (!isSelected)
                              TextButton(
                                onPressed: () {
                                  provider.switchProfile(profile.id!);
                                },
                                child: const Text('Switch'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Add native ad with approximately 50% of height before the banner

          // Keep the banner ad at the bottom
          const BannerAdWidget(),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final icons = {
      'person': Icons.person,
      'face': Icons.face,
      'person_2': Icons.person_2,
      'person_3': Icons.person_3,
      'person_4': Icons.person_4,
      'face_2': Icons.face_2,
      'face_3': Icons.face_3,
      'face_4': Icons.face_4,
      'face_5': Icons.face_5,
      'face_6': Icons.face_6,
      'family_restroom': Icons.family_restroom,
      'diversity_1': Icons.diversity_1,
      'diversity_2': Icons.diversity_2,
      'diversity_3': Icons.diversity_3,
      'group': Icons.group,
      'groups': Icons.groups,
      'school': Icons.school,
      'work': Icons.work,
    };
    return icons[iconName] ?? Icons.person;
  }
}
