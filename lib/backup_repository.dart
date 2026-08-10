import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A portable, user-owned snapshot. Sharing this file to Drive, Files or mail
/// is deliberately opt-in; GrowUp does not send a child's data to our server.
class BackupRepository {
  static const _keys = <String>[
    'onboarding_completed_v1',
    'child_profiles_v1',
    'active_child_profile_v1',
    'action_observations_v1',
    'growth_events_v1',
    'unlocked_items_v1',
    'avatar_state_v1',
    'space_state_v1',
  ];

  Future<File> createExport() async {
    final preferences = await SharedPreferences.getInstance();
    final values = <String, Object?>{};
    for (final key in _keys) {
      values[key] = preferences.get(key);
    }
    for (final key in preferences.getKeys()) {
      if (key.startsWith('action_card_levels_v1_')) {
        values[key] = preferences.get(key);
      }
    }
    final document = <String, Object?>{
      'format': 'growup-backup',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'values': values,
    };
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/growup-backup-${DateTime.now().millisecondsSinceEpoch}.json',
    );
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(document),
    );
  }

  Future<void> shareExport() async {
    final file = await createExport();
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'application/json'),
    ], text: 'GrowUp 성장 기록 백업');
  }

  Future<void> importFromJson(String source) async {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    if (decoded['format'] != 'growup-backup' || decoded['values'] is! Map) {
      throw const FormatException('GrowUp 백업 파일이 아닙니다.');
    }
    final values = Map<String, dynamic>.from(decoded['values'] as Map);
    final preferences = await SharedPreferences.getInstance();
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) {
        await preferences.remove(entry.key);
      } else if (value is bool) {
        await preferences.setBool(entry.key, value);
      } else if (value is int) {
        await preferences.setInt(entry.key, value);
      } else if (value is double) {
        await preferences.setDouble(entry.key, value);
      } else if (value is String) {
        await preferences.setString(entry.key, value);
      } else if (value is List) {
        await preferences.setStringList(entry.key, value.cast<String>());
      }
    }
  }
}
