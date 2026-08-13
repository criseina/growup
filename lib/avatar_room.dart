import 'dart:math' as math;

import 'package:flutter/material.dart';

enum RoomObjectKind { fixed, acquired }

enum RoomInteraction {
  look,
  wash,
  brush,
  bathe,
  dry,
  dress,
  organize,
  pickUp,
  eat,
  drink,
  prepare,
  stop,
  askHelp,
  rest,
  useToilet,
  flush,
}

class RoomPoint {
  const RoomPoint(this.x, this.y);
  final double x;
  final double y;

  Offset toScreen(Size size) =>
      Offset(size.width * x / 100, size.height * y / 100);

  double distanceTo(RoomPoint other) => math.sqrt(
    math.pow(x - other.x, 2).toDouble() + math.pow(y - other.y, 2).toDouble(),
  );
}

class RoomRect {
  const RoomRect(this.left, this.top, this.width, this.height);
  final double left;
  final double top;
  final double width;
  final double height;

  bool contains(RoomPoint point) =>
      point.x >= left &&
      point.x <= left + width &&
      point.y >= top &&
      point.y <= top + height;
}

class WalkableArea {
  const WalkableArea(this.polygon);
  final List<RoomPoint> polygon;

  bool contains(RoomPoint point) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i];
      final b = polygon[j];
      if ((a.y > point.y) != (b.y > point.y) &&
          point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x) {
        inside = !inside;
      }
    }
    return inside;
  }

  RoomPoint clamp(RoomPoint wanted, List<RoomRect> collisions) {
    if (_isAllowed(wanted, collisions)) return wanted;
    for (var radius = 1.0; radius <= 60; radius += 1) {
      for (var step = 0; step < 24; step++) {
        final angle = step * math.pi * 2 / 24;
        final candidate = RoomPoint(
          (wanted.x + math.cos(angle) * radius).clamp(0, 100).toDouble(),
          (wanted.y + math.sin(angle) * radius).clamp(0, 100).toDouble(),
        );
        if (_isAllowed(candidate, collisions)) return candidate;
      }
    }
    return const RoomPoint(50, 75);
  }

  bool _isAllowed(RoomPoint point, List<RoomRect> collisions) =>
      contains(point) && !collisions.any((rect) => rect.contains(point));
}

class RoomObject {
  const RoomObject({
    required this.id,
    required this.name,
    required this.kind,
    required this.position,
    required this.approachPoint,
    required this.interaction,
    required this.interactionAnimation,
    this.relatedActionIds = const <String>{},
    this.itemId,
    this.collision,
    this.interactionRadius = 13,
    this.hitWidth = 12,
    this.hitHeight = 12,
  });

  final String id;
  final String name;
  final RoomObjectKind kind;
  final RoomPoint position;
  final RoomPoint approachPoint;
  final RoomInteraction interaction;
  final String interactionAnimation;
  final Set<String> relatedActionIds;
  final String? itemId;
  final RoomRect? collision;
  final double interactionRadius;
  final double hitWidth;
  final double hitHeight;

  bool isNear(RoomPoint point) =>
      approachPoint.distanceTo(point) <= interactionRadius;
}

class DecorationSlot {
  const DecorationSlot({
    required this.id,
    required this.position,
    required this.allowedItemIds,
    required this.label,
    required this.approachPoint,
  });
  final String id;
  final RoomPoint position;
  final Set<String> allowedItemIds;
  final String label;
  final RoomPoint approachPoint;

  bool accepts(String itemId) => allowedItemIds.contains(itemId);
}

class AvatarRoom {
  const AvatarRoom({
    required this.id,
    required this.label,
    required this.categoryIds,
    required this.backgroundAsset,
    required this.backgroundAnchors,
    required this.walkableArea,
    required this.initialAvatarPosition,
    required this.fixedObjects,
    required this.slots,
  });

  final String id;
  final String label;
  final Set<String> categoryIds;
  final String backgroundAsset;
  final List<String> backgroundAnchors;
  final WalkableArea walkableArea;
  final RoomPoint initialAvatarPosition;
  final List<RoomObject> fixedObjects;
  final List<DecorationSlot> slots;

  List<RoomRect> get collisions => fixedObjects
      .map((object) => object.collision)
      .whereType<RoomRect>()
      .toList();

  DecorationSlot? nearestAcceptingSlot(String itemId, RoomPoint wanted) {
    final available = slots.where((slot) => slot.accepts(itemId)).toList();
    if (available.isEmpty) return null;
    available.sort(
      (a, b) => a.position
          .distanceTo(wanted)
          .compareTo(b.position.distanceTo(wanted)),
    );
    return available.first;
  }
}

const avatarRooms = <AvatarRoom>[
  AvatarRoom(
    id: 'bathroom',
    label: '욕실',
    categoryIds: {'hygiene'},
    backgroundAsset: 'assets/avatar_backgrounds/bathroom-v2.png',
    backgroundAnchors: ['열린 선반', '수건 걸이대', '문', '타일 벽', '바닥'],
    walkableArea: WalkableArea([
      RoomPoint(10, 61),
      RoomPoint(88, 61),
      RoomPoint(96, 94),
      RoomPoint(5, 94),
    ]),
    initialAvatarPosition: RoomPoint(50, 79),
    fixedObjects: [
      RoomObject(
        id: 'bathroom_mirror',
        name: '거울',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(86, 22),
        approachPoint: RoomPoint(73, 66),
        interaction: RoomInteraction.look,
        interactionAnimation: 'look_in_mirror',
      ),
      RoomObject(
        id: 'bathroom_sink',
        name: '세면대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(87, 48),
        approachPoint: RoomPoint(73, 67),
        interaction: RoomInteraction.wash,
        interactionAnimation: 'wash_hands',
        relatedActionIds: {'H-01', 'H-04'},
        collision: RoomRect(76, 38, 24, 25),
      ),
      RoomObject(
        id: 'bathroom_bathtub',
        name: '욕조',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(15, 51),
        approachPoint: RoomPoint(29, 72),
        interaction: RoomInteraction.bathe,
        interactionAnimation: 'take_bath',
        relatedActionIds: {'H-02', 'H-05', 'H-06'},
        collision: RoomRect(0, 55, 22, 24),
      ),
      RoomObject(
        id: 'bathroom_shower',
        name: '샤워기',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(18, 27),
        approachPoint: RoomPoint(29, 72),
        interaction: RoomInteraction.bathe,
        interactionAnimation: 'take_shower',
        relatedActionIds: {'H-05', 'H-06'},
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'sink_left',
        position: RoomPoint(69, 48),
        label: '세면대 왼쪽',
        allowedItemIds: {'bathroom_soap_01'},
        approachPoint: RoomPoint(73, 67),
      ),
      DecorationSlot(
        id: 'open_shelf',
        position: RoomPoint(91, 55),
        label: '욕실 선반',
        allowedItemIds: {'bathroom_toothbrush_01', 'bathroom_shampoo_01'},
        approachPoint: RoomPoint(73, 67),
      ),
      DecorationSlot(
        id: 'towel_rail',
        position: RoomPoint(68, 32),
        label: '수건 걸이대',
        allowedItemIds: {'bathroom_towel_01'},
        approachPoint: RoomPoint(72, 65),
      ),
    ],
  ),
  AvatarRoom(
    id: 'bedroom',
    label: '침실',
    categoryIds: {'dressing'},
    backgroundAsset: 'assets/avatar_backgrounds/bedroom-v2.png',
    backgroundAnchors: ['벽 선반', '옷걸이 공간', '바닥 러그', '침대 옆 공간'],
    walkableArea: WalkableArea([
      RoomPoint(7, 59),
      RoomPoint(90, 59),
      RoomPoint(96, 95),
      RoomPoint(4, 95),
    ]),
    initialAvatarPosition: RoomPoint(49, 80),
    fixedObjects: [
      RoomObject(
        id: 'bedroom_bed',
        name: '침대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(80, 45),
        approachPoint: RoomPoint(67, 66),
        interaction: RoomInteraction.rest,
        interactionAnimation: 'rest_on_bed',
        collision: RoomRect(66, 32, 34, 27),
      ),
      RoomObject(
        id: 'bedroom_mirror',
        name: '전신 거울',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(33, 35),
        approachPoint: RoomPoint(39, 66),
        interaction: RoomInteraction.look,
        interactionAnimation: 'look_in_mirror',
      ),
      RoomObject(
        id: 'bedroom_wardrobe',
        name: '옷장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(12, 34),
        approachPoint: RoomPoint(28, 66),
        interaction: RoomInteraction.dress,
        interactionAnimation: 'choose_clothes',
        relatedActionIds: {'C-01', 'C-02', 'C-09', 'C-13'},
        collision: RoomRect(0, 9, 25, 48),
      ),
      RoomObject(
        id: 'bedroom_drawer',
        name: '서랍장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(53, 43),
        approachPoint: RoomPoint(53, 66),
        interaction: RoomInteraction.organize,
        interactionAnimation: 'organize_clothes',
        relatedActionIds: {'C-12'},
        collision: RoomRect(43, 35, 22, 23),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'clothes_rack',
        position: RoomPoint(13, 31),
        label: '옷걸이 공간',
        allowedItemIds: {'bedroom_rack_01'},
        approachPoint: RoomPoint(28, 66),
      ),
      DecorationSlot(
        id: 'basket_floor',
        position: RoomPoint(30, 59),
        label: '바구니 자리',
        allowedItemIds: {'bedroom_basket_01'},
        approachPoint: RoomPoint(36, 68),
      ),
      DecorationSlot(
        id: 'folded_shelf',
        position: RoomPoint(12, 22),
        label: '옷장 선반',
        allowedItemIds: {'bedroom_folded_01'},
        approachPoint: RoomPoint(28, 66),
      ),
      DecorationSlot(
        id: 'hat_shelf',
        position: RoomPoint(53, 36),
        label: '서랍장 위',
        allowedItemIds: {'bedroom_hat_01'},
        approachPoint: RoomPoint(53, 66),
      ),
    ],
  ),
  AvatarRoom(
    id: 'kitchen',
    label: '주방',
    categoryIds: {'meals'},
    backgroundAsset: 'assets/avatar_backgrounds/kitchen-v2.png',
    backgroundAnchors: ['벽 선반', '식기장', '식탁 위', '바닥'],
    walkableArea: WalkableArea([
      RoomPoint(7, 63),
      RoomPoint(91, 63),
      RoomPoint(97, 95),
      RoomPoint(4, 95),
    ]),
    initialAvatarPosition: RoomPoint(49, 80),
    fixedObjects: [
      RoomObject(
        id: 'kitchen_table',
        name: '식탁',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(84, 48),
        approachPoint: RoomPoint(62, 72),
        interaction: RoomInteraction.eat,
        interactionAnimation: 'eat',
        relatedActionIds: {'M-01', 'M-02', 'M-03'},
        collision: RoomRect(70, 37, 30, 24),
      ),
      RoomObject(
        id: 'kitchen_cabinet',
        name: '식기장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(17, 51),
        approachPoint: RoomPoint(29, 70),
        interaction: RoomInteraction.organize,
        interactionAnimation: 'organize_dishes',
        relatedActionIds: {'M-04'},
        collision: RoomRect(0, 39, 32, 24),
      ),
      RoomObject(
        id: 'kitchen_sink',
        name: '싱크대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(8, 38),
        approachPoint: RoomPoint(34, 67),
        interaction: RoomInteraction.wash,
        interactionAnimation: 'clean',
        relatedActionIds: {'M-05', 'B-04'},
        collision: RoomRect(0, 29, 22, 24),
      ),
      RoomObject(
        id: 'kitchen_fridge',
        name: '냉장고',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(39, 34),
        approachPoint: RoomPoint(43, 66),
        interaction: RoomInteraction.prepare,
        interactionAnimation: 'prepare_food',
        collision: RoomRect(29, 20, 20, 35),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'table_drink',
        position: RoomPoint(83, 42),
        label: '식탁 위',
        allowedItemIds: {'kitchen_cup_01'},
        approachPoint: RoomPoint(62, 72),
      ),
      DecorationSlot(
        id: 'table_cutlery',
        position: RoomPoint(76, 43),
        label: '식탁 위',
        allowedItemIds: {'kitchen_cutlery_01'},
        approachPoint: RoomPoint(62, 72),
      ),
      DecorationSlot(
        id: 'table_dishes',
        position: RoomPoint(90, 43),
        label: '식탁 위',
        allowedItemIds: {'kitchen_dishes_01'},
        approachPoint: RoomPoint(62, 72),
      ),
      DecorationSlot(
        id: 'counter_cloth',
        position: RoomPoint(20, 34),
        label: '조리대',
        allowedItemIds: {'kitchen_cloth_01'},
        approachPoint: RoomPoint(34, 67),
      ),
    ],
  ),
  AvatarRoom(
    id: 'playroom',
    label: '생활 공간',
    categoryIds: {'belongings_home'},
    backgroundAsset: 'assets/avatar_backgrounds/playroom.png',
    backgroundAnchors: ['낮은 선반', '빈 벽', '바닥 러그', '수납장 옆 공간'],
    walkableArea: WalkableArea([
      RoomPoint(6, 61),
      RoomPoint(91, 61),
      RoomPoint(97, 95),
      RoomPoint(3, 95),
    ]),
    initialAvatarPosition: RoomPoint(50, 80),
    fixedObjects: [
      RoomObject(
        id: 'playroom_low_shelf',
        name: '낮은 선반',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(13, 54),
        approachPoint: RoomPoint(28, 68),
        interaction: RoomInteraction.organize,
        interactionAnimation: 'organize',
        relatedActionIds: {'B-01', 'B-02'},
        collision: RoomRect(0, 43, 24, 22),
      ),
      RoomObject(
        id: 'playroom_bookshelf',
        name: '큰 책장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(89, 42),
        approachPoint: RoomPoint(75, 67),
        interaction: RoomInteraction.organize,
        interactionAnimation: 'organize_books',
        relatedActionIds: {'B-06'},
        collision: RoomRect(79, 25, 21, 38),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'toybox_floor',
        position: RoomPoint(69, 65),
        label: '러그 옆',
        allowedItemIds: {'playroom_toybox_01'},
        approachPoint: RoomPoint(65, 72),
      ),
      DecorationSlot(
        id: 'books_floor',
        position: RoomPoint(30, 59),
        label: '낮은 선반',
        allowedItemIds: {'playroom_shelf_01'},
        approachPoint: RoomPoint(30, 68),
      ),
      DecorationSlot(
        id: 'laundry_floor',
        position: RoomPoint(44, 67),
        label: '바구니 자리',
        allowedItemIds: {'playroom_laundry_01'},
        approachPoint: RoomPoint(44, 73),
      ),
      DecorationSlot(
        id: 'trash_floor',
        position: RoomPoint(57, 66),
        label: '휴지통 자리',
        allowedItemIds: {'playroom_trash_01'},
        approachPoint: RoomPoint(57, 73),
      ),
    ],
  ),
  AvatarRoom(
    id: 'entrance',
    label: '현관',
    categoryIds: {'outing', 'safety_help'},
    backgroundAsset: 'assets/avatar_backgrounds/entrance-v2.png',
    backgroundAnchors: ['벽걸이', '신발장 위', '우산꽂이', '현관 매트', '바깥 횡단보도'],
    walkableArea: WalkableArea([
      RoomPoint(7, 62),
      RoomPoint(91, 62),
      RoomPoint(97, 94),
      RoomPoint(4, 94),
    ]),
    initialAvatarPosition: RoomPoint(50, 80),
    fixedObjects: [
      RoomObject(
        id: 'entrance_shoe_rack',
        name: '신발장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(16, 56),
        approachPoint: RoomPoint(31, 69),
        interaction: RoomInteraction.prepare,
        interactionAnimation: 'organize_shoes',
        relatedActionIds: {'O-01', 'O-02', 'O-03'},
        collision: RoomRect(0, 43, 27, 24),
      ),
      RoomObject(
        id: 'entrance_door',
        name: '현관문',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(90, 42),
        approachPoint: RoomPoint(75, 69),
        interaction: RoomInteraction.prepare,
        interactionAnimation: 'prepare_to_go_out',
        relatedActionIds: {'O-07', 'O-08'},
        collision: RoomRect(83, 15, 17, 47),
      ),
      RoomObject(
        id: 'entrance_hooks',
        name: '벽걸이',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(13, 28),
        approachPoint: RoomPoint(30, 67),
        interaction: RoomInteraction.dress,
        interactionAnimation: 'wear_outerwear',
        relatedActionIds: {'O-07', 'O-12'},
      ),
      RoomObject(
        id: 'entrance_traffic_light',
        name: '신호등',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(58, 30),
        approachPoint: RoomPoint(67, 65),
        interaction: RoomInteraction.stop,
        interactionAnimation: 'check_traffic_light',
        relatedActionIds: {'S-01', 'S-02'},
      ),
      RoomObject(
        id: 'entrance_crosswalk',
        name: '횡단보도',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(69, 49),
        approachPoint: RoomPoint(68, 65),
        interaction: RoomInteraction.stop,
        interactionAnimation: 'stop_and_look',
        relatedActionIds: {'S-01', 'S-02'},
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'bag_hook',
        position: RoomPoint(29, 43),
        label: '벽걸이',
        allowedItemIds: {'entrance_bag_01'},
        approachPoint: RoomPoint(31, 69),
      ),
      DecorationSlot(
        id: 'bottle_shelf',
        position: RoomPoint(31, 52),
        label: '신발장 위',
        allowedItemIds: {'entrance_bottle_01'},
        approachPoint: RoomPoint(31, 69),
      ),
      DecorationSlot(
        id: 'small_goods',
        position: RoomPoint(43, 53),
        label: '신발장 위',
        allowedItemIds: {'entrance_wipes_01'},
        approachPoint: RoomPoint(38, 69),
      ),
      DecorationSlot(
        id: 'umbrella_stand',
        position: RoomPoint(78, 59),
        label: '우산꽂이',
        allowedItemIds: {'entrance_umbrella_01'},
        approachPoint: RoomPoint(72, 69),
      ),
      DecorationSlot(
        id: 'safety_cone_floor',
        position: RoomPoint(53, 62),
        label: '현관 안전 연습 자리',
        allowedItemIds: {'safety_cone_01'},
        approachPoint: RoomPoint(53, 70),
      ),
      DecorationSlot(
        id: 'safety_stop_floor',
        position: RoomPoint(62, 60),
        label: '멈춤 연습 자리',
        allowedItemIds: {'safety_stop_01'},
        approachPoint: RoomPoint(62, 70),
      ),
      DecorationSlot(
        id: 'safety_crosswalk_floor',
        position: RoomPoint(70, 59),
        label: '횡단보도 연습 자리',
        allowedItemIds: {'safety_crosswalk_01'},
        approachPoint: RoomPoint(69, 68),
      ),
      DecorationSlot(
        id: 'help_card_hook',
        position: RoomPoint(39, 43),
        label: '도움 카드 걸이',
        allowedItemIds: {'safety_contact_01'},
        approachPoint: RoomPoint(40, 68),
      ),
    ],
  ),
  AvatarRoom(
    id: 'toilet',
    label: '화장실',
    categoryIds: {'toilet'},
    backgroundAsset: 'assets/avatar_backgrounds/toilet.png',
    backgroundAnchors: ['열린 선반', '휴지걸이', '수건 걸이대', '문', '바닥'],
    walkableArea: WalkableArea([
      RoomPoint(8, 60),
      RoomPoint(91, 60),
      RoomPoint(97, 95),
      RoomPoint(3, 95),
    ]),
    initialAvatarPosition: RoomPoint(50, 81),
    fixedObjects: [
      RoomObject(
        id: 'toilet_bowl',
        name: '변기',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(17, 50),
        approachPoint: RoomPoint(34, 66),
        interaction: RoomInteraction.useToilet,
        interactionAnimation: 'use_toilet',
        relatedActionIds: {'T-01', 'T-02', 'T-03', 'T-04'},
        collision: RoomRect(2, 34, 29, 28),
      ),
      RoomObject(
        id: 'toilet_sink',
        name: '작은 세면대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(82, 48),
        approachPoint: RoomPoint(68, 66),
        interaction: RoomInteraction.wash,
        interactionAnimation: 'wash_hands',
        relatedActionIds: {'T-06'},
        collision: RoomRect(72, 37, 25, 25),
      ),
      RoomObject(
        id: 'toilet_flush',
        name: '물 내림 손잡이',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(25, 41),
        approachPoint: RoomPoint(35, 66),
        interaction: RoomInteraction.flush,
        interactionAnimation: 'flush_toilet',
        relatedActionIds: {'T-06'},
        hitWidth: 9,
        hitHeight: 8,
      ),
      RoomObject(
        id: 'toilet_paper_holder',
        name: '휴지걸이',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(40, 43),
        approachPoint: RoomPoint(45, 66),
        interaction: RoomInteraction.pickUp,
        interactionAnimation: 'wipe',
        relatedActionIds: {'T-05'},
        hitWidth: 10,
        hitHeight: 9,
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'toilet_paper_anchor',
        position: RoomPoint(40, 42),
        label: '휴지걸이',
        allowedItemIds: {'toilet_paper_01'},
        approachPoint: RoomPoint(45, 66),
      ),
      DecorationSlot(
        id: 'toilet_shelf',
        position: RoomPoint(75, 16),
        label: '열린 선반',
        allowedItemIds: {'toilet_wipes_01'},
        approachPoint: RoomPoint(67, 66),
      ),
      DecorationSlot(
        id: 'toilet_sink_counter',
        position: RoomPoint(76, 42),
        label: '세면대',
        allowedItemIds: {'toilet_soap_01'},
        approachPoint: RoomPoint(68, 66),
      ),
      DecorationSlot(
        id: 'toilet_towel_rail',
        position: RoomPoint(76, 31),
        label: '수건 걸이대',
        allowedItemIds: {'toilet_towel_01'},
        approachPoint: RoomPoint(68, 66),
      ),
    ],
  ),
];

AvatarRoom roomById(String id) =>
    avatarRooms.firstWhere((room) => room.id == id);
