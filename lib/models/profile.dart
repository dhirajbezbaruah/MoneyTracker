class Profile {
  final int? id;
  final String name;
  final String iconName;
  final DateTime createdAt;
  final bool isSelected;

  Profile({
    this.id,
    required this.name,
    required this.iconName,
    required this.createdAt,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'created_at': createdAt.toIso8601String(),
      'is_selected': isSelected ? 1 : 0,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconName: map['icon_name'] as String? ?? 'person',
      createdAt: DateTime.parse(
          map['created_at'] as String? ?? DateTime.now().toIso8601String()),
      isSelected: (map['is_selected'] as int?) == 1,
    );
  }

  Profile copyWith({
    int? id,
    String? name,
    String? iconName,
    DateTime? createdAt,
    bool? isSelected,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
