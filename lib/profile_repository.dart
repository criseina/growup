import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ChildProfile {
  const ChildProfile({
    required this.id,
    required this.name,
    required this.birthYear,
  });

  final String id;
  final String name;
  final int? birthYear;

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
    id: json['id'] as String,
    name: json['name'] as String,
    birthYear: json['birthYear'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'birthYear': birthYear,
  };

  ChildProfile copyWith({String? name, int? birthYear}) => ChildProfile(
    id: id,
    name: name ?? this.name,
    birthYear: birthYear ?? this.birthYear,
  );
}

class ProfileRepository {
  static const defaultProfileId = 'default-child';
  static const _profilesKey = 'child_profiles_v1';
  static const _activeProfileKey = 'active_child_profile_v1';

  static const defaultProfile = ChildProfile(
    id: defaultProfileId,
    name: '우리 아이',
    birthYear: null,
  );

  Future<List<ChildProfile>> loadProfiles() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_profilesKey);
    if (raw == null) {
      await preferences.setString(
        _profilesKey,
        jsonEncode([defaultProfile.toJson()]),
      );
      return [defaultProfile];
    }
    return (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ChildProfile.fromJson)
        .toList();
  }

  Future<ChildProfile> loadActiveProfile() async {
    final profiles = await loadProfiles();
    final preferences = await SharedPreferences.getInstance();
    final activeId = preferences.getString(_activeProfileKey);
    return profiles.firstWhere(
      (profile) => profile.id == activeId,
      orElse: () => profiles.first,
    );
  }

  Future<void> setActiveProfile(String profileId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_activeProfileKey, profileId);
  }

  Future<void> saveProfiles(List<ChildProfile> profiles) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _profilesKey,
      jsonEncode(profiles.map((profile) => profile.toJson()).toList()),
    );
  }
}
