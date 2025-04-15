class Profile {
  final int? id;
  final String name;
  final bool isSelected;
  final String? iconName; // Stores the name of the Material icon

  Profile({
    this.id,
    required this.name,
    this.isSelected = false,
    this.iconName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_selected': isSelected ? 1 : 0,
      'icon_name': iconName,
    };
  }

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'],
      name: map['name'],
      isSelected: map['is_selected'] == 1,
      iconName: map['icon_name'],
    );
  }

  Profile copyWith({
    int? id,
    String? name,
    bool? isSelected,
    String? iconName,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      isSelected: isSelected ?? this.isSelected,
      iconName: iconName ?? this.iconName,
    );
  }
}
