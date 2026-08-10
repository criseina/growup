import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum UnlockableItemType { avatarItem, spaceItem }

class UnlockableItem {
  const UnlockableItem({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.icon,
    required this.spaceId,
  });

  final String id;
  final String name;
  final UnlockableItemType type;
  final String category;
  final String icon;
  final String? spaceId;
}

class GrowthEvent {
  const GrowthEvent({
    required this.id,
    required this.profileId,
    required this.cardId,
    required this.itemId,
    required this.occurredAt,
  });

  final String id;
  final String profileId;
  final String cardId;
  final String itemId;
  final DateTime occurredAt;

  factory GrowthEvent.fromJson(Map<String, dynamic> json) => GrowthEvent(
    id: json['id'] as String,
    profileId: json['profileId'] as String,
    cardId: json['cardId'] as String,
    itemId: json['itemId'] as String,
    occurredAt: DateTime.parse(json['occurredAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'profileId': profileId,
    'cardId': cardId,
    'itemId': itemId,
    'occurredAt': occurredAt.toIso8601String(),
  };
}

class GrowthUnlockResult {
  const GrowthUnlockResult({required this.event, required this.item});
  final GrowthEvent event;
  final UnlockableItem item;
}

class GrowthRewardRepository {
  static const _eventsKey = 'growth_events_v1';
  static const _unlockedKey = 'unlocked_items_v1';
  static const _avatarKey = 'avatar_state_v1';
  static const _spaceKey = 'space_state_v1';

  static const items = <UnlockableItem>[
    UnlockableItem(
      id: 'bathroom_soap_01',
      name: '거품 비누',
      type: UnlockableItemType.spaceItem,
      category: 'bathroom',
      icon: '🧼',
      spaceId: 'bathroom',
    ),
    UnlockableItem(
      id: 'bathroom_toothbrush_01',
      name: '칫솔 컵',
      type: UnlockableItemType.spaceItem,
      category: 'bathroom',
      icon: '🪥',
      spaceId: 'bathroom',
    ),
    UnlockableItem(
      id: 'bathroom_towel_01',
      name: '수건',
      type: UnlockableItemType.spaceItem,
      category: 'bathroom',
      icon: '🧻',
      spaceId: 'bathroom',
    ),
    UnlockableItem(
      id: 'bathroom_bubble_01',
      name: '목욕 거품',
      type: UnlockableItemType.spaceItem,
      category: 'bathroom',
      icon: '🫧',
      spaceId: 'bathroom',
    ),
    UnlockableItem(
      id: 'avatar_top_01',
      name: '파란 상의',
      type: UnlockableItemType.avatarItem,
      category: 'top',
      icon: '👕',
      spaceId: null,
    ),
    UnlockableItem(
      id: 'avatar_bottom_01',
      name: '편한 바지',
      type: UnlockableItemType.avatarItem,
      category: 'bottom',
      icon: '👖',
      spaceId: null,
    ),
    UnlockableItem(
      id: 'avatar_shoes_01',
      name: '운동화',
      type: UnlockableItemType.avatarItem,
      category: 'shoes',
      icon: '👟',
      spaceId: null,
    ),
    UnlockableItem(
      id: 'avatar_hat_01',
      name: '모자',
      type: UnlockableItemType.avatarItem,
      category: 'hat',
      icon: '🧢',
      spaceId: null,
    ),
    UnlockableItem(
      id: 'avatar_accessory_01',
      name: '반짝이 가방',
      type: UnlockableItemType.avatarItem,
      category: 'accessory',
      icon: '🎒',
      spaceId: null,
    ),
    UnlockableItem(
      id: 'playroom_toybox_01',
      name: '장난감 상자',
      type: UnlockableItemType.spaceItem,
      category: 'playroom',
      icon: '🧸',
      spaceId: 'playroom',
    ),
    UnlockableItem(
      id: 'playroom_shelf_01',
      name: '정리 선반',
      type: UnlockableItemType.spaceItem,
      category: 'playroom',
      icon: '🗄️',
      spaceId: 'playroom',
    ),
    UnlockableItem(
      id: 'kitchen_cup_01',
      name: '컵',
      type: UnlockableItemType.spaceItem,
      category: 'kitchen',
      icon: '🥛',
      spaceId: 'kitchen',
    ),
    UnlockableItem(
      id: 'kitchen_table_01',
      name: '식탁 매트',
      type: UnlockableItemType.spaceItem,
      category: 'kitchen',
      icon: '🍽️',
      spaceId: 'kitchen',
    ),
    UnlockableItem(
      id: 'entrance_shoe_rack_01',
      name: '신발장',
      type: UnlockableItemType.spaceItem,
      category: 'entrance',
      icon: '👟',
      spaceId: 'entrance',
    ),
    UnlockableItem(
      id: 'entrance_bag_01',
      name: '외출 가방',
      type: UnlockableItemType.spaceItem,
      category: 'entrance',
      icon: '👜',
      spaceId: 'entrance',
    ),
    UnlockableItem(
      id: 'safety_car_01',
      name: '안전 자동차',
      type: UnlockableItemType.spaceItem,
      category: 'safety',
      icon: '🚗',
      spaceId: 'safety',
    ),
    UnlockableItem(
      id: 'safety_cone_01',
      name: '안전 표지판',
      type: UnlockableItemType.spaceItem,
      category: 'safety',
      icon: '🚸',
      spaceId: 'safety',
    ),
  ];

  static const rewardByCardId = <String, String>{
    'H-01': 'bathroom_soap_01',
    'H-02': 'bathroom_toothbrush_01',
    'H-03': 'bathroom_towel_01',
    'H-04': 'bathroom_bubble_01',
    'C-01': 'avatar_top_01',
    'C-02': 'avatar_bottom_01',
    'C-03': 'avatar_shoes_01',
    'C-04': 'entrance_shoe_rack_01',
    'C-05': 'avatar_hat_01',
    'M-01': 'kitchen_cup_01',
    'M-02': 'kitchen_table_01',
    'M-03': 'avatar_accessory_01',
    'M-04': 'kitchen_table_01',
    'B-01': 'playroom_shelf_01',
    'B-02': 'playroom_toybox_01',
    'B-03': 'playroom_shelf_01',
    'B-04': 'playroom_toybox_01',
    'B-05': 'playroom_shelf_01',
    'O-01': 'avatar_top_01',
    'O-02': 'entrance_bag_01',
    'O-03': 'entrance_shoe_rack_01',
    'S-01': 'safety_car_01',
    'S-02': 'safety_cone_01',
    'S-03': 'safety_cone_01',
    'S-04': 'safety_car_01',
    'S-05': 'safety_cone_01',
  };

  UnlockableItem? itemForCard(String cardId) {
    final id = rewardByCardId[cardId];
    return id == null ? null : items.where((item) => item.id == id).first;
  }

  Future<GrowthUnlockResult?> unlockFirstIndependent({
    required String profileId,
    required String cardId,
  }) async {
    final item = itemForCard(cardId);
    if (item == null) return null;
    final preferences = await SharedPreferences.getInstance();
    final events = await loadEvents(profileId);
    if (events.any((event) => event.cardId == cardId)) return null;
    final event = GrowthEvent(
      id: 'growth-$profileId-$cardId',
      profileId: profileId,
      cardId: cardId,
      itemId: item.id,
      occurredAt: DateTime.now(),
    );
    final allEvents = _decodeEvents(preferences.getString(_eventsKey))
      ..add(event);
    await preferences.setString(
      _eventsKey,
      jsonEncode(allEvents.map((item) => item.toJson()).toList()),
    );
    final unlocked = _decodeStringMap(preferences.getString(_unlockedKey));
    final profileItems = {...?unlocked[profileId], item.id}.toList();
    unlocked[profileId] = profileItems;
    await preferences.setString(_unlockedKey, jsonEncode(unlocked));
    return GrowthUnlockResult(event: event, item: item);
  }

  Future<List<GrowthEvent>> loadEvents(String profileId) async {
    final preferences = await SharedPreferences.getInstance();
    return _decodeEvents(
        preferences.getString(_eventsKey),
      ).where((event) => event.profileId == profileId).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }

  Future<List<UnlockableItem>> unlockedItems(String profileId) async {
    final preferences = await SharedPreferences.getInstance();
    final ids =
        _decodeStringMap(preferences.getString(_unlockedKey))[profileId] ??
        const <String>[];
    return items.where((item) => ids.contains(item.id)).toList();
  }

  Future<Map<String, String>> loadAvatar(String profileId) async {
    final preferences = await SharedPreferences.getInstance();
    final decoded = _decodeNestedMap(preferences.getString(_avatarKey));
    return {...?decoded[profileId]};
  }

  Future<void> equipAvatarItem(String profileId, UnlockableItem item) async {
    final preferences = await SharedPreferences.getInstance();
    final decoded = _decodeNestedMap(preferences.getString(_avatarKey));
    final avatar = {...?decoded[profileId]};
    avatar[item.category] = item.id;
    decoded[profileId] = avatar;
    await preferences.setString(_avatarKey, jsonEncode(decoded));
  }

  Future<Map<String, List<String>>> loadSpaces(String profileId) async {
    final preferences = await SharedPreferences.getInstance();
    final decoded = _decodeStringMap(preferences.getString(_spaceKey));
    final result = <String, List<String>>{};
    for (final entry in decoded.entries) {
      if (entry.key.startsWith('$profileId:')) {
        result[entry.key.substring(profileId.length + 1)] = entry.value;
      }
    }
    return result;
  }

  Future<void> toggleSpaceItem(String profileId, UnlockableItem item) async {
    if (item.spaceId == null) return;
    final preferences = await SharedPreferences.getInstance();
    final decoded = _decodeStringMap(preferences.getString(_spaceKey));
    final key = '$profileId:${item.spaceId}';
    final placed = {...?decoded[key]};
    if (!placed.add(item.id)) placed.remove(item.id);
    decoded[key] = placed.toList();
    await preferences.setString(_spaceKey, jsonEncode(decoded));
  }

  List<GrowthEvent> _decodeEvents(String? raw) => raw == null
      ? <GrowthEvent>[]
      : (jsonDecode(raw) as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(GrowthEvent.fromJson)
            .toList();

  Map<String, List<String>> _decodeStringMap(String? raw) {
    if (raw == null) return {};
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data.map(
      (key, value) => MapEntry(key, List<String>.from(value as List<dynamic>)),
    );
  }

  Map<String, Map<String, String>> _decodeNestedMap(String? raw) {
    if (raw == null) return {};
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data.map(
      (key, value) => MapEntry(
        key,
        Map<String, String>.from(value as Map<String, dynamic>),
      ),
    );
  }
}
