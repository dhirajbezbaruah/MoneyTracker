import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/profile.dart';
import '../db/database_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = true;
  String? _selectedIcon;

  final _availableIcons = {
    'person': Icons.person,
    'person_2': Icons.person_2,
    'person_3': Icons.person_3,
    'person_4': Icons.person_4,
    'face': Icons.face,
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

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
    });
    print('DEBUG: ProfileScreen _loadProfiles called');
    try {
      await context.read<TransactionProvider>().loadProfiles();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print(
          'DEBUG: ProfileScreen _loadProfiles completed, _isLoading=' +
              _isLoading.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddProfileDialog() {
    _nameController.clear();
    _selectedIcon = 'person'; // Default icon

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Add Profile'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Profile Name',
                            counterText: '10 characters max',
                          ),
                          maxLength: 10,
                          textCapitalization: TextCapitalization.words,
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        const Text('Choose an icon:'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              _availableIcons.entries.map((entry) {
                                final isSelected = entry.key == _selectedIcon;
                                return InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      _selectedIcon = entry.key;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey.shade400,
                                      ),
                                    ),
                                    child: Icon(
                                      entry.value,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                      size: 28,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _selectedIcon = null;
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty) {
                          context.read<TransactionProvider>().addProfile(
                            _nameController.text,
                            iconName: _selectedIcon,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showEditProfileDialog(Profile profile) {
    setState(() {
      _nameController.text = profile.name;
      _selectedIcon = profile.iconName;
    });

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Edit Profile'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Profile Name',
                            counterText: '10 characters max',
                          ),
                          maxLength: 10,
                          textCapitalization: TextCapitalization.words,
                          autofocus: true,
                        ),
                        const SizedBox(height: 16),
                        const Text('Choose an icon:'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children:
                              _availableIcons.entries.map((entry) {
                                final isSelected = entry.key == _selectedIcon;
                                return InkWell(
                                  onTap: () {
                                    setDialogState(() {
                                      _selectedIcon = entry.key;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? Theme.of(context).primaryColor
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey.shade400,
                                      ),
                                    ),
                                    child: Icon(
                                      entry.value,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey.shade700,
                                      size: 28,
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _selectedIcon = null;
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (_nameController.text.isNotEmpty) {
                          final updatedProfile = profile.copyWith(
                            name: _nameController.text,
                            iconName: _selectedIcon,
                          );
                          context.read<TransactionProvider>().updateProfile(
                            updatedProfile,
                          );
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteConfirmation(Profile profile) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Profile'),
            content: Text(
              'Are you sure you want to delete "${profile.name}"? '
              'This will not delete the transactions, but they will be hidden.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  try {
                    context.read<TransactionProvider>().deleteProfile(
                      profile.id!,
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Database'),
            content: const Text(
              'Are you sure you want to reset the database? '
              'This will delete all profiles, transactions, and budgets.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() {
                    _isLoading = true;
                  });

                  await DatabaseHelper.instance.resetDatabase();
                  if (!mounted) return;

                  // Reload everything
                  await context.read<TransactionProvider>().loadProfiles();
                  setState(() {
                    _isLoading = false;
                  });

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Database has been reset')),
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiles'),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset database',
              onPressed: () => _showResetConfirmation(),
              style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2E5C88).withOpacity(0.15)
                        : const Color(0xFF2E5C88).withOpacity(0.1),
                foregroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2E5C88)
                        : const Color(0xFF2E5C88),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add profile',
              onPressed: () {
                final provider = context.read<TransactionProvider>();
                if (provider.profiles.length >= 5) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Maximum 5 profiles allowed')),
                  );
                  return;
                }
                _showAddProfileDialog();
              },
              style: IconButton.styleFrom(
                backgroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2E5C88).withOpacity(0.15)
                        : const Color(0xFF2E5C88).withOpacity(0.1),
                foregroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2E5C88)
                        : const Color(0xFF2E5C88),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  final profiles = provider.profiles;
                  final selectedProfile = provider.selectedProfile;

                  if (profiles.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(
                                        0xFF2E5C88,
                                      ).withOpacity(0.15)
                                      : const Color(
                                        0xFF2E5C88,
                                      ).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_outlined,
                              size: 64,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF2E5C88)
                                      : const Color(0xFF2E5C88),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No profiles found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add a profile to get started',
                            style: TextStyle(
                              fontSize: 15,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddProfileDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF2E5C88)
                                      : const Color(0xFF2E5C88),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: profiles.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                profile.isSelected
                                    ? [
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF2E5C88)
                                          : const Color(0xFF2E5C88),
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(0xFF15294D)
                                          : const Color(0xFF1E3D59),
                                    ]
                                    : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? [
                                      Colors.grey.shade800,
                                      Colors.grey.shade900,
                                    ]
                                    : [Colors.white, Colors.grey.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  profile.isSelected
                                      ? Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(
                                            0xFF2E5C88,
                                          ).withOpacity(0.3)
                                          : const Color(
                                            0xFF2E5C88,
                                          ).withOpacity(0.2)
                                      : Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                              spreadRadius: profile.isSelected ? 1 : 0,
                            ),
                          ],
                          border: Border.all(
                            color:
                                profile.isSelected
                                    ? Colors.transparent
                                    : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey.shade700
                                    : const Color(0xFF2E5C88).withOpacity(0.15),
                            width: 1.5,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                profile.isSelected
                                    ? Colors.white.withOpacity(0.25)
                                    : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? const Color(0xFF2E5C88).withOpacity(0.15)
                                    : const Color(0xFF2E5C88).withOpacity(0.1),
                            child: Icon(
                              _availableIcons[profile.iconName] ?? Icons.person,
                              color:
                                  profile.isSelected
                                      ? Colors.white
                                      : const Color(0xFF2E5C88),
                              size: 22,
                            ),
                          ),
                          title: Text(
                            profile.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color:
                                  profile.isSelected
                                      ? Colors.white
                                      : Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey.shade200
                                      : const Color(0xFF1E3D59),
                            ),
                          ),
                          subtitle:
                              profile.isSelected
                                  ? Text(
                                    'Active profile',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  )
                                  : Text(
                                    'Tap to activate',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey.shade400
                                              : const Color(
                                                0xFF2E5C88,
                                              ).withOpacity(0.7),
                                    ),
                                  ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      profile.isSelected
                                          ? Colors.white.withOpacity(0.2)
                                          : Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? const Color(
                                            0xFF2E5C88,
                                          ).withOpacity(0.1)
                                          : const Color(
                                            0xFF2E5C88,
                                          ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: InkWell(
                                  onTap: () => _showEditProfileDialog(profile),
                                  customBorder: const CircleBorder(),
                                  child: Icon(
                                    Icons.edit,
                                    color:
                                        profile.isSelected
                                            ? Colors.white
                                            : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF2E5C88)
                                            : const Color(0xFF2E5C88),
                                    size: 20,
                                  ),
                                ),
                              ),
                              if (profile.id != selectedProfile?.id)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        profile.isSelected
                                            ? Colors.white.withOpacity(0.2)
                                            : Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.redAccent.withOpacity(0.1)
                                            : Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: InkWell(
                                    onTap:
                                        () => _showDeleteConfirmation(profile),
                                    customBorder: const CircleBorder(),
                                    child: Icon(
                                      Icons.delete_outline,
                                      color:
                                          profile.isSelected
                                              ? Colors.white
                                              : Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.redAccent.shade100
                                              : Colors.redAccent,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            if (!profile.isSelected) {
                              provider.switchProfile(profile.id!);
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
