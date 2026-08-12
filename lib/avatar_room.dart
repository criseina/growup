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
    this.itemId,
    this.collision,
    this.interactionRadius = 13,
  });

  final String id;
  final String name;
  final RoomObjectKind kind;
  final RoomPoint position;
  final RoomPoint approachPoint;
  final RoomInteraction interaction;
  final String? itemId;
  final RoomRect? collision;
  final double interactionRadius;

  bool isNear(RoomPoint point) =>
      approachPoint.distanceTo(point) <= interactionRadius;
}

class DecorationSlot {
  const DecorationSlot({
    required this.id,
    required this.position,
    required this.allowedItemIds,
    required this.label,
  });
  final String id;
  final RoomPoint position;
  final Set<String> allowedItemIds;
  final String label;

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
    required this.fixedObjects,
    required this.slots,
  });

  final String id;
  final String label;
  final Set<String> categoryIds;
  final String backgroundAsset;
  final List<String> backgroundAnchors;
  final WalkableArea walkableArea;
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
    categoryIds: {'hygiene', 'toilet'},
    backgroundAsset: 'assets/avatar_backgrounds/bathroom.png',
    backgroundAnchors: ['열린 선반', '수건 걸이대', '문', '타일 벽', '바닥'],
    walkableArea: WalkableArea([
      RoomPoint(10, 61),
      RoomPoint(88, 61),
      RoomPoint(96, 94),
      RoomPoint(5, 94),
    ]),
    fixedObjects: [
      RoomObject(
        id: 'bathroom_mirror',
        name: '거울',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(86, 22),
        approachPoint: RoomPoint(73, 66),
        interaction: RoomInteraction.look,
      ),
      RoomObject(
        id: 'bathroom_sink',
        name: '세면대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(87, 48),
        approachPoint: RoomPoint(73, 67),
        interaction: RoomInteraction.wash,
        collision: RoomRect(76, 38, 24, 25),
      ),
      RoomObject(
        id: 'bathroom_bathtub',
        name: '욕조',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(15, 67),
        approachPoint: RoomPoint(29, 72),
        interaction: RoomInteraction.bathe,
        collision: RoomRect(0, 55, 22, 24),
      ),
      RoomObject(
        id: 'bathroom_toilet',
        name: '변기',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(25, 50),
        approachPoint: RoomPoint(36, 66),
        interaction: RoomInteraction.wash,
        collision: RoomRect(12, 43, 23, 20),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'sink_left',
        position: RoomPoint(69, 48),
        label: '세면대 왼쪽',
        allowedItemIds: {'bathroom_soap_01'},
      ),
      DecorationSlot(
        id: 'open_shelf',
        position: RoomPoint(25, 42),
        label: '열린 선반',
        allowedItemIds: {'bathroom_toothbrush_01', 'bathroom_shampoo_01'},
      ),
      DecorationSlot(
        id: 'towel_rail',
        position: RoomPoint(68, 32),
        label: '수건 걸이대',
        allowedItemIds: {'bathroom_towel_01'},
      ),
    ],
  ),
  AvatarRoom(
    id: 'bedroom',
    label: '침실',
    categoryIds: {'dressing'},
    backgroundAsset: 'assets/avatar_backgrounds/bedroom.png',
    backgroundAnchors: ['벽 선반', '옷걸이 공간', '바닥 러그', '침대 옆 공간'],
    walkableArea: WalkableArea([
      RoomPoint(7, 59),
      RoomPoint(90, 59),
      RoomPoint(96, 95),
      RoomPoint(4, 95),
    ]),
    fixedObjects: [
      RoomObject(
        id: 'bedroom_bed',
        name: '침대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(70, 51),
        approachPoint: RoomPoint(63, 70),
        interaction: RoomInteraction.rest,
        collision: RoomRect(52, 43, 42, 23),
      ),
      RoomObject(
        id: 'bedroom_mirror',
        name: '전신 거울',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(13, 42),
        approachPoint: RoomPoint(25, 68),
        interaction: RoomInteraction.look,
      ),
      RoomObject(
        id: 'bedroom_wardrobe',
        name: '옷장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(25, 34),
        approachPoint: RoomPoint(35, 66),
        interaction: RoomInteraction.dress,
        collision: RoomRect(9, 20, 26, 38),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'clothes_rack',
        position: RoomPoint(21, 52),
        label: '옷걸이 공간',
        allowedItemIds: {'bedroom_rack_01'},
      ),
      DecorationSlot(
        id: 'basket_floor',
        position: RoomPoint(38, 65),
        label: '바구니 자리',
        allowedItemIds: {'bedroom_basket_01'},
      ),
      DecorationSlot(
        id: 'folded_shelf',
        position: RoomPoint(27, 43),
        label: '옷장 선반',
        allowedItemIds: {'bedroom_folded_01'},
      ),
      DecorationSlot(
        id: 'hat_shelf',
        position: RoomPoint(42, 35),
        label: '모자 선반',
        allowedItemIds: {'bedroom_hat_01'},
      ),
    ],
  ),
  AvatarRoom(
    id: 'kitchen',
    label: '주방',
    categoryIds: {'meals'},
    backgroundAsset: 'assets/avatar_backgrounds/kitchen.png',
    backgroundAnchors: ['벽 선반', '식기장', '식탁 위', '바닥'],
    walkableArea: WalkableArea([
      RoomPoint(7, 63),
      RoomPoint(91, 63),
      RoomPoint(97, 95),
      RoomPoint(4, 95),
    ]),
    fixedObjects: [
      RoomObject(
        id: 'kitchen_table',
        name: '식탁',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(77, 66),
        approachPoint: RoomPoint(62, 72),
        interaction: RoomInteraction.eat,
        collision: RoomRect(65, 56, 35, 25),
      ),
      RoomObject(
        id: 'kitchen_cabinet',
        name: '식기장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(12, 57),
        approachPoint: RoomPoint(29, 70),
        interaction: RoomInteraction.organize,
        collision: RoomRect(0, 45, 23, 27),
      ),
      RoomObject(
        id: 'kitchen_sink',
        name: '싱크대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(18, 48),
        approachPoint: RoomPoint(34, 67),
        interaction: RoomInteraction.wash,
        collision: RoomRect(0, 37, 26, 25),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'table_drink',
        position: RoomPoint(79, 56),
        label: '식탁 위',
        allowedItemIds: {'kitchen_cup_01'},
      ),
      DecorationSlot(
        id: 'table_cutlery',
        position: RoomPoint(70, 57),
        label: '식탁 위',
        allowedItemIds: {'kitchen_cutlery_01'},
      ),
      DecorationSlot(
        id: 'table_dishes',
        position: RoomPoint(87, 57),
        label: '식탁 위',
        allowedItemIds: {'kitchen_dishes_01'},
      ),
      DecorationSlot(
        id: 'counter_cloth',
        position: RoomPoint(24, 52),
        label: '조리대',
        allowedItemIds: {'kitchen_cloth_01'},
      ),
    ],
  ),
  AvatarRoom(
    id: 'playroom',
    label: '놀이방',
    categoryIds: {'belongings_home'},
    backgroundAsset: 'assets/avatar_backgrounds/playroom.png',
    backgroundAnchors: ['낮은 선반', '빈 벽', '바닥 러그', '수납장 옆 공간'],
    walkableArea: WalkableArea([
      RoomPoint(6, 61),
      RoomPoint(91, 61),
      RoomPoint(97, 95),
      RoomPoint(3, 95),
    ]),
    fixedObjects: [
      RoomObject(
        id: 'playroom_low_shelf',
        name: '낮은 선반',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(13, 54),
        approachPoint: RoomPoint(28, 68),
        interaction: RoomInteraction.organize,
        collision: RoomRect(0, 43, 24, 22),
      ),
      RoomObject(
        id: 'playroom_bookshelf',
        name: '큰 책장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(89, 42),
        approachPoint: RoomPoint(75, 67),
        interaction: RoomInteraction.organize,
        collision: RoomRect(79, 25, 21, 38),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'toybox_floor',
        position: RoomPoint(69, 65),
        label: '러그 옆',
        allowedItemIds: {'playroom_toybox_01'},
      ),
      DecorationSlot(
        id: 'books_floor',
        position: RoomPoint(30, 59),
        label: '낮은 선반',
        allowedItemIds: {'playroom_shelf_01'},
      ),
      DecorationSlot(
        id: 'laundry_floor',
        position: RoomPoint(44, 67),
        label: '바구니 자리',
        allowedItemIds: {'playroom_laundry_01'},
      ),
      DecorationSlot(
        id: 'trash_floor',
        position: RoomPoint(57, 66),
        label: '휴지통 자리',
        allowedItemIds: {'playroom_trash_01'},
      ),
    ],
  ),
  AvatarRoom(
    id: 'entrance',
    label: '현관',
    categoryIds: {'outing'},
    backgroundAsset: 'assets/avatar_backgrounds/entrance.png',
    backgroundAnchors: ['벽걸이 선반', '신발장 위', '우산꽂이 옆', '현관 매트'],
    walkableArea: WalkableArea([
      RoomPoint(7, 62),
      RoomPoint(91, 62),
      RoomPoint(97, 94),
      RoomPoint(4, 94),
    ]),
    fixedObjects: [
      RoomObject(
        id: 'entrance_shoe_rack',
        name: '신발장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(16, 56),
        approachPoint: RoomPoint(31, 69),
        interaction: RoomInteraction.prepare,
        collision: RoomRect(0, 43, 27, 24),
      ),
      RoomObject(
        id: 'entrance_door',
        name: '현관문',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(90, 42),
        approachPoint: RoomPoint(75, 69),
        interaction: RoomInteraction.prepare,
        collision: RoomRect(83, 15, 17, 47),
      ),
      RoomObject(
        id: 'entrance_hooks',
        name: '벽걸이',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(13, 28),
        approachPoint: RoomPoint(30, 67),
        interaction: RoomInteraction.dress,
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'bag_hook',
        position: RoomPoint(29, 43),
        label: '벽걸이',
        allowedItemIds: {'entrance_bag_01'},
      ),
      DecorationSlot(
        id: 'bottle_shelf',
        position: RoomPoint(31, 52),
        label: '신발장 위',
        allowedItemIds: {'entrance_bottle_01'},
      ),
      DecorationSlot(
        id: 'small_goods',
        position: RoomPoint(43, 53),
        label: '신발장 위',
        allowedItemIds: {'entrance_wipes_01'},
      ),
      DecorationSlot(
        id: 'umbrella_stand',
        position: RoomPoint(78, 59),
        label: '우산꽂이',
        allowedItemIds: {'entrance_umbrella_01'},
      ),
    ],
  ),
  AvatarRoom(
    id: 'safety',
    label: '안전 공간',
    categoryIds: {'safety_help'},
    backgroundAsset: 'assets/avatar_backgrounds/safety.png',
    backgroundAnchors: ['도로 배경', '울타리', '보행 공간', '표지판 자리'],
    walkableArea: WalkableArea([
      RoomPoint(7, 60),
      RoomPoint(91, 60),
      RoomPoint(96, 93),
      RoomPoint(4, 93),
    ]),
    fixedObjects: [
      RoomObject(
        id: 'safety_traffic_light',
        name: '신호등',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(72, 42),
        approachPoint: RoomPoint(63, 68),
        interaction: RoomInteraction.stop,
        collision: RoomRect(68, 25, 9, 34),
      ),
      RoomObject(
        id: 'safety_crosswalk',
        name: '횡단보도',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(49, 67),
        approachPoint: RoomPoint(49, 69),
        interaction: RoomInteraction.stop,
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'cone_ground',
        position: RoomPoint(29, 68),
        label: '안전선 옆',
        allowedItemIds: {'safety_cone_01'},
      ),
      DecorationSlot(
        id: 'stop_ground',
        position: RoomPoint(72, 59),
        label: '표지판 자리',
        allowedItemIds: {'safety_stop_01'},
      ),
      DecorationSlot(
        id: 'crosswalk_ground',
        position: RoomPoint(50, 66),
        label: '보행 연습 공간',
        allowedItemIds: {'safety_crosswalk_01'},
      ),
      DecorationSlot(
        id: 'contact_board',
        position: RoomPoint(18, 46),
        label: '안전 게시판',
        allowedItemIds: {'safety_contact_01'},
      ),
    ],
  ),
];

AvatarRoom roomById(String id) =>
    avatarRooms.firstWhere((room) => room.id == id);
