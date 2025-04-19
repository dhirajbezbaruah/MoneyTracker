import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../models/profile.dart';

class ProfileScreen extends StatefulWidget {
  final Profile? profile;
  final bool isEditing;

  const ProfileScreen({
    super.key,
    this.profile,
    this.isEditing = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  String _selectedIcon = 'person';

  // Keep the same icons as in onboarding dialog
  final _icons = {
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

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _nameController.text = widget.profile!.name;
      _selectedIcon = widget.profile!.iconName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Profile' : 'New Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: 'Profile Name',
                hintText: 'Enter name or nickname',
                counterText: '', // Hide the counter
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedIcon,
              decoration: const InputDecoration(
                labelText: 'Profile Icon',
              ),
              items: _icons.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Row(
                    children: [
                      Icon(entry.value),
                      const SizedBox(width: 8),
                      Text(entry.key.replaceAll('_', ' ').toTitleCase()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedIcon = value);
                }
              },
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a profile name'),
                    ),
                  );
                  return;
                }

                final provider = context.read<TransactionProvider>();
                if (widget.isEditing && widget.profile != null) {
                  final updatedProfile = widget.profile!.copyWith(
                    name: name,
                    iconName: _selectedIcon,
                  );
                  provider.updateProfile(updatedProfile);
                } else {
                  final profile = Profile(
                    name: name,
                    iconName: _selectedIcon,
                    createdAt: DateTime.now(),
                  );
                  provider.createProfile(profile);
                }

                Navigator.pop(context);
              },
              child: Text(widget.isEditing ? 'Save Changes' : 'Create Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
