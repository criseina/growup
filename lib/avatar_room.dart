import 'dart:math' as math;

import 'package:flutter/material.dart';

enum RoomObjectKind { fixed, acquired }

enum RoomVisualLayer { back, depthSorted, front }

enum RoomObjectAnchor { floorBottomCenter, wallCenter, surfaceCenter }

enum RoomObjectVisualSource { atlas, backgroundStructure }

enum RoomFacing { front, back, left, right }

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

  double get right => left + width;
  double get bottom => top + height;
  double get area => width * height;

  double overlapRatio(RoomRect other) {
    final overlapWidth = math.max(
      0,
      math.min(right, other.right) - math.max(left, other.left),
    );
    final overlapHeight = math.max(
      0,
      math.min(bottom, other.bottom) - math.max(top, other.top),
    );
    final smallerArea = math.min(area, other.area);
    if (smallerArea <= 0) return 0;
    return overlapWidth * overlapHeight / smallerArea;
  }

  bool contains(RoomPoint point) =>
      point.x >= left &&
      point.x <= left + width &&
      point.y >= top &&
      point.y <= top + height;

  RoomRect inflate(double horizontal, double vertical) => RoomRect(
    left - horizontal,
    top - vertical,
    width + horizontal * 2,
    height + vertical * 2,
  );

  RoomRect union(RoomRect other) {
    final unionLeft = math.min(left, other.left);
    final unionTop = math.min(top, other.top);
    final unionRight = math.max(right, other.right);
    final unionBottom = math.max(bottom, other.bottom);
    return RoomRect(
      unionLeft,
      unionTop,
      unionRight - unionLeft,
      unionBottom - unionTop,
    );
  }

  RoomRect clampToViewport() {
    final clampedLeft = left.clamp(0, 100).toDouble();
    final clampedTop = top.clamp(0, 100).toDouble();
    final clampedRight = right.clamp(0, 100).toDouble();
    final clampedBottom = bottom.clamp(0, 100).toDouble();
    return RoomRect(
      clampedLeft,
      clampedTop,
      math.max(0, clampedRight - clampedLeft),
      math.max(0, clampedBottom - clampedTop),
    );
  }
}

class RoomSize {
  const RoomSize(this.width, this.height);
  final double width;
  final double height;
}

class WalkableArea {
  const WalkableArea(this.polygon);
  static const avatarHorizontalMargin = 18.0;
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
      point.x >= avatarHorizontalMargin &&
      point.x <= 100 - avatarHorizontalMargin &&
      contains(point) &&
      !collisions.any((rect) => rect.contains(point));
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
    this.assetId,
    this.visualSize = const RoomSize(20, 20),
    this.depth,
    this.relatedActionIds = const <String>{},
    this.itemId,
    this.collision,
    this.interactionRadius = 13,
    this.hitWidth = 12,
    this.hitHeight = 12,
    this.visualLayer = RoomVisualLayer.depthSorted,
    this.anchor = RoomObjectAnchor.floorBottomCenter,
    this.visualSource = RoomObjectVisualSource.atlas,
    this.interactionBounds,
    this.interactionPoint,
    this.interactionFacing = RoomFacing.back,
    this.interactionDuration = const Duration(milliseconds: 2200),
  });

  final String id;
  final String name;
  final RoomObjectKind kind;
  final RoomPoint position;
  final RoomPoint approachPoint;
  final RoomInteraction interaction;
  final String interactionAnimation;
  final String? assetId;
  final RoomSize visualSize;
  final double? depth;
  final RoomVisualLayer visualLayer;
  final RoomObjectAnchor anchor;
  final RoomObjectVisualSource visualSource;
  final RoomRect? interactionBounds;
  final RoomPoint? interactionPoint;
  final RoomFacing interactionFacing;
  final Duration interactionDuration;
  final Set<String> relatedActionIds;
  final String? itemId;
  final RoomRect? collision;
  final double interactionRadius;
  final double hitWidth;
  final double hitHeight;

  static const minimumHitWidth = 18.0;
  static const minimumHitHeight = 14.0;

  bool isNear(RoomPoint point) =>
      approachPoint.distanceTo(point) <= interactionRadius;

  String get visualAssetId => assetId ?? id;
  bool get shouldRenderAtlas => visualSource == RoomObjectVisualSource.atlas;
  double get visualDepth => depth ?? position.y;
  String get objectId => id;
  String get objectType => kind.name;
  String get themeId => id.split('_').first;
  RoomRect get visualBounds => switch (anchor) {
    RoomObjectAnchor.floorBottomCenter => RoomRect(
      position.x - visualSize.width / 2,
      position.y - visualSize.height,
      visualSize.width,
      visualSize.height,
    ),
    RoomObjectAnchor.wallCenter || RoomObjectAnchor.surfaceCenter => RoomRect(
      position.x - visualSize.width / 2,
      position.y - visualSize.height / 2,
      visualSize.width,
      visualSize.height,
    ),
  };
  RoomRect get interactionArea {
    final requested =
        interactionBounds ??
        RoomRect(
          position.x - hitWidth / 2,
          position.y - hitHeight / 2,
          hitWidth,
          hitHeight,
        );
    final minimum = RoomRect(
      position.x - math.max(hitWidth, minimumHitWidth) / 2,
      position.y - math.max(hitHeight, minimumHitHeight) / 2,
      math.max(hitWidth, minimumHitWidth),
      math.max(hitHeight, minimumHitHeight),
    );
    // A visible object should be tappable across its body, not only through a
    // small invisible hotspot near the anchor.
    return requested.union(minimum).union(visualBounds).clampToViewport();
  }

  RoomPoint get resolvedInteractionPoint => interactionPoint ?? approachPoint;
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

  List<RoomRect> get navigationCollisions => collisions
      .map((collision) => collision.inflate(4.5, 2.5))
      .toList(growable: false);

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
    backgroundAsset: 'assets/avatar_layers/backgrounds/bathroom.png',
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
        interactionFacing: RoomFacing.right,
        visualSize: RoomSize(18, 24),
        visualLayer: RoomVisualLayer.back,
        anchor: RoomObjectAnchor.wallCenter,
      ),
      RoomObject(
        id: 'bathroom_sink',
        name: '세면대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(84, 64),
        approachPoint: RoomPoint(73, 70),
        interaction: RoomInteraction.wash,
        interactionAnimation: 'wash_hands',
        interactionFacing: RoomFacing.right,
        visualSize: RoomSize(30, 28),
        depth: 64,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'H-01', 'H-04'},
        collision: RoomRect(76, 50, 24, 15),
      ),
      RoomObject(
        id: 'bathroom_bathtub',
        name: '욕조',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(21, 64),
        approachPoint: RoomPoint(29, 72),
        interaction: RoomInteraction.bathe,
        interactionAnimation: 'take_bath',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(42, 27),
        depth: 64,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'H-02', 'H-05', 'H-06'},
        collision: RoomRect(0, 51, 22, 14),
      ),
      RoomObject(
        id: 'bathroom_shower',
        name: '샤워기',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(18, 27),
        approachPoint: RoomPoint(29, 72),
        interaction: RoomInteraction.bathe,
        interactionAnimation: 'take_shower',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(15, 30),
        visualLayer: RoomVisualLayer.back,
        anchor: RoomObjectAnchor.wallCenter,
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
    backgroundAsset: 'assets/avatar_layers/backgrounds/bedroom.png',
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
        position: RoomPoint(84, 62),
        approachPoint: RoomPoint(70, 70),
        interaction: RoomInteraction.rest,
        interactionAnimation: 'rest_on_bed',
        interactionFacing: RoomFacing.right,
        visualSize: RoomSize(31, 25),
        depth: 62,
        anchor: RoomObjectAnchor.floorBottomCenter,
        collision: RoomRect(69, 48, 30, 15),
      ),
      RoomObject(
        id: 'bedroom_mirror',
        name: '전신 거울',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(61, 34),
        approachPoint: RoomPoint(61, 70),
        interaction: RoomInteraction.look,
        interactionAnimation: 'look_in_mirror',
        interactionFacing: RoomFacing.back,
        visualSize: RoomSize(18, 34),
        visualLayer: RoomVisualLayer.back,
        anchor: RoomObjectAnchor.wallCenter,
      ),
      RoomObject(
        id: 'bedroom_wardrobe',
        name: '옷장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(42, 62),
        approachPoint: RoomPoint(54, 70),
        interaction: RoomInteraction.dress,
        interactionAnimation: 'choose_clothes',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(22, 38),
        depth: 62,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'C-01', 'C-02', 'C-09', 'C-13'},
        collision: RoomRect(31, 45, 22, 18),
      ),
      RoomObject(
        id: 'bedroom_drawer',
        name: '서랍장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(61, 62),
        approachPoint: RoomPoint(61, 70),
        interaction: RoomInteraction.organize,
        interactionAnimation: 'organize_clothes',
        visualSize: RoomSize(17, 20),
        depth: 62,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'C-12'},
        collision: RoomRect(53, 51, 17, 12),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'clothes_rack',
        position: RoomPoint(36, 74),
        label: '옷걸이 공간',
        allowedItemIds: {'bedroom_rack_01'},
        approachPoint: RoomPoint(36, 80),
      ),
      DecorationSlot(
        id: 'basket_floor',
        position: RoomPoint(50, 76),
        label: '바구니 자리',
        allowedItemIds: {'bedroom_basket_01'},
        approachPoint: RoomPoint(50, 82),
      ),
      DecorationSlot(
        id: 'folded_shelf',
        position: RoomPoint(42, 49),
        label: '옷장 선반',
        allowedItemIds: {'bedroom_folded_01'},
        approachPoint: RoomPoint(54, 70),
      ),
      DecorationSlot(
        id: 'hat_shelf',
        position: RoomPoint(61, 52),
        label: '서랍장 위',
        allowedItemIds: {'bedroom_hat_01'},
        approachPoint: RoomPoint(61, 70),
      ),
    ],
  ),
  AvatarRoom(
    id: 'kitchen',
    label: '주방',
    categoryIds: {'meals'},
    backgroundAsset: 'assets/avatar_layers/backgrounds/kitchen.png',
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
        position: RoomPoint(82, 76),
        approachPoint: RoomPoint(62, 73),
        interaction: RoomInteraction.eat,
        interactionAnimation: 'eat',
        interactionFacing: RoomFacing.right,
        visualSize: RoomSize(18, 19),
        depth: 76,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'M-01', 'M-02', 'M-03'},
        collision: RoomRect(74, 64, 16, 12),
      ),
      RoomObject(
        id: 'kitchen_sink',
        name: '싱크대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(20, 64),
        approachPoint: RoomPoint(34, 67),
        interaction: RoomInteraction.wash,
        interactionAnimation: 'clean',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(30, 24),
        depth: 64,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'M-04', 'M-05', 'B-04'},
        collision: RoomRect(5, 50, 30, 14),
      ),
      RoomObject(
        id: 'kitchen_fridge',
        name: '냉장고',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(69, 65),
        approachPoint: RoomPoint(58, 68),
        interaction: RoomInteraction.prepare,
        interactionAnimation: 'prepare_food',
        interactionFacing: RoomFacing.back,
        visualSize: RoomSize(20, 36),
        depth: 65,
        anchor: RoomObjectAnchor.floorBottomCenter,
        collision: RoomRect(59, 46, 20, 19),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'table_drink',
        position: RoomPoint(83, 58),
        label: '식탁 위',
        allowedItemIds: {'kitchen_cup_01'},
        approachPoint: RoomPoint(62, 72),
      ),
      DecorationSlot(
        id: 'table_cutlery',
        position: RoomPoint(76, 59),
        label: '식탁 위',
        allowedItemIds: {'kitchen_cutlery_01'},
        approachPoint: RoomPoint(62, 72),
      ),
      DecorationSlot(
        id: 'table_dishes',
        position: RoomPoint(90, 59),
        label: '식탁 위',
        allowedItemIds: {'kitchen_dishes_01'},
        approachPoint: RoomPoint(62, 72),
      ),
      DecorationSlot(
        id: 'counter_cloth',
        position: RoomPoint(20, 39),
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
    backgroundAsset: 'assets/avatar_layers/backgrounds/playroom.png',
    backgroundAnchors: ['낮은 선반', '빈 벽', '바닥 러그', '수납장 옆 공간'],
    walkableArea: WalkableArea([
      RoomPoint(18, 73),
      RoomPoint(82, 73),
      RoomPoint(97, 95),
      RoomPoint(3, 95),
    ]),
    initialAvatarPosition: RoomPoint(50, 80),
    fixedObjects: [
      RoomObject(
        id: 'playroom_low_shelf',
        name: '낮은 선반',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(15, 72),
        approachPoint: RoomPoint(30, 77),
        interaction: RoomInteraction.organize,
        interactionAnimation: 'organize',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(29, 25),
        depth: 72,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'B-01', 'B-02'},
        collision: RoomRect(1, 58, 28, 15),
      ),
      RoomObject(
        id: 'playroom_bookshelf',
        name: '큰 책장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(87, 72),
        approachPoint: RoomPoint(74, 77),
        interaction: RoomInteraction.organize,
        interactionAnimation: 'organize_books',
        interactionFacing: RoomFacing.right,
        visualSize: RoomSize(23, 36),
        depth: 72,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'B-06'},
        collision: RoomRect(76, 54, 23, 19),
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'toybox_floor',
        position: RoomPoint(69, 82),
        label: '러그 옆',
        allowedItemIds: {'playroom_toybox_01'},
        approachPoint: RoomPoint(65, 84),
      ),
      DecorationSlot(
        id: 'books_floor',
        position: RoomPoint(30, 82),
        label: '낮은 선반',
        allowedItemIds: {'playroom_shelf_01'},
        approachPoint: RoomPoint(30, 84),
      ),
      DecorationSlot(
        id: 'laundry_floor',
        position: RoomPoint(44, 82),
        label: '바구니 자리',
        allowedItemIds: {'playroom_laundry_01'},
        approachPoint: RoomPoint(44, 85),
      ),
      DecorationSlot(
        id: 'trash_floor',
        position: RoomPoint(57, 82),
        label: '휴지통 자리',
        allowedItemIds: {'playroom_trash_01'},
        approachPoint: RoomPoint(57, 85),
      ),
    ],
  ),
  AvatarRoom(
    id: 'entrance',
    label: '현관',
    categoryIds: {'outing', 'safety_help'},
    backgroundAsset: 'assets/avatar_layers/backgrounds/entrance.png',
    backgroundAnchors: ['벽걸이', '신발장 위', '우산꽂이', '현관 매트', '현관문'],
    walkableArea: WalkableArea([
      RoomPoint(18, 70),
      RoomPoint(82, 70),
      RoomPoint(97, 94),
      RoomPoint(4, 94),
    ]),
    initialAvatarPosition: RoomPoint(50, 80),
    fixedObjects: [
      RoomObject(
        id: 'entrance_shoe_rack',
        name: '신발장',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(16, 78),
        approachPoint: RoomPoint(31, 79),
        interaction: RoomInteraction.prepare,
        interactionAnimation: 'organize_shoes',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(29, 31),
        depth: 78,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'O-01', 'O-02', 'O-03'},
        collision: RoomRect(1, 61, 29, 18),
      ),
      RoomObject(
        id: 'entrance_door',
        name: '현관문',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(90, 42),
        approachPoint: RoomPoint(75, 74),
        interaction: RoomInteraction.prepare,
        interactionAnimation: 'prepare_to_go_out',
        interactionFacing: RoomFacing.right,
        visualSize: RoomSize(19, 49),
        visualLayer: RoomVisualLayer.back,
        anchor: RoomObjectAnchor.wallCenter,
        visualSource: RoomObjectVisualSource.backgroundStructure,
        relatedActionIds: {'O-07', 'O-08'},
        collision: RoomRect(83, 15, 17, 47),
      ),
      RoomObject(
        id: 'entrance_hooks',
        name: '벽걸이',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(14, 28),
        approachPoint: RoomPoint(32, 74),
        interaction: RoomInteraction.dress,
        interactionAnimation: 'wear_outerwear',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(27, 25),
        visualLayer: RoomVisualLayer.back,
        anchor: RoomObjectAnchor.wallCenter,
        relatedActionIds: {'O-07', 'O-12'},
      ),
    ],
    slots: [
      DecorationSlot(
        id: 'bag_hook',
        position: RoomPoint(29, 43),
        label: '벽걸이',
        allowedItemIds: {'entrance_bag_01'},
        approachPoint: RoomPoint(31, 79),
      ),
      DecorationSlot(
        id: 'bottle_shelf',
        position: RoomPoint(31, 48),
        label: '신발장 위',
        allowedItemIds: {'entrance_bottle_01'},
        approachPoint: RoomPoint(31, 79),
      ),
      DecorationSlot(
        id: 'small_goods',
        position: RoomPoint(43, 48),
        label: '신발장 위',
        allowedItemIds: {'entrance_wipes_01'},
        approachPoint: RoomPoint(38, 79),
      ),
      DecorationSlot(
        id: 'umbrella_stand',
        position: RoomPoint(78, 78),
        label: '우산꽂이',
        allowedItemIds: {'entrance_umbrella_01'},
        approachPoint: RoomPoint(72, 80),
      ),
      DecorationSlot(
        id: 'safety_cone_floor',
        position: RoomPoint(53, 79),
        label: '현관 안전 연습 자리',
        allowedItemIds: {'safety_cone_01'},
        approachPoint: RoomPoint(53, 82),
      ),
      DecorationSlot(
        id: 'safety_stop_floor',
        position: RoomPoint(62, 79),
        label: '멈춤 연습 자리',
        allowedItemIds: {'safety_stop_01'},
        approachPoint: RoomPoint(62, 82),
      ),
      DecorationSlot(
        id: 'safety_crosswalk_floor',
        position: RoomPoint(70, 80),
        label: '횡단보도 연습 자리',
        allowedItemIds: {'safety_crosswalk_01'},
        approachPoint: RoomPoint(69, 83),
      ),
      DecorationSlot(
        id: 'help_card_hook',
        position: RoomPoint(39, 43),
        label: '도움 카드 걸이',
        allowedItemIds: {'safety_contact_01'},
        approachPoint: RoomPoint(40, 78),
      ),
    ],
  ),
  AvatarRoom(
    id: 'toilet',
    label: '화장실',
    categoryIds: {'toilet'},
    backgroundAsset: 'assets/avatar_layers/backgrounds/toilet.png',
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
        position: RoomPoint(17, 62),
        approachPoint: RoomPoint(34, 66),
        interaction: RoomInteraction.useToilet,
        interactionAnimation: 'use_toilet',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(29, 32),
        depth: 63,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'T-01', 'T-02', 'T-03', 'T-04'},
        collision: RoomRect(2, 48, 29, 15),
      ),
      RoomObject(
        id: 'toilet_sink',
        name: '작은 세면대',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(82, 62),
        approachPoint: RoomPoint(68, 66),
        interaction: RoomInteraction.wash,
        interactionAnimation: 'wash_hands',
        interactionFacing: RoomFacing.right,
        visualSize: RoomSize(27, 29),
        depth: 62,
        anchor: RoomObjectAnchor.floorBottomCenter,
        relatedActionIds: {'T-06'},
        collision: RoomRect(70, 49, 27, 14),
      ),
      RoomObject(
        id: 'toilet_flush',
        name: '물 내림 손잡이',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(25, 41),
        approachPoint: RoomPoint(35, 66),
        interaction: RoomInteraction.flush,
        interactionAnimation: 'flush_toilet',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(12, 10),
        visualLayer: RoomVisualLayer.back,
        anchor: RoomObjectAnchor.wallCenter,
        relatedActionIds: {'T-06'},
        hitWidth: 14,
        hitHeight: 14,
      ),
      RoomObject(
        id: 'toilet_paper_holder',
        name: '휴지걸이',
        kind: RoomObjectKind.fixed,
        position: RoomPoint(40, 43),
        approachPoint: RoomPoint(45, 66),
        interaction: RoomInteraction.pickUp,
        interactionAnimation: 'wipe',
        interactionFacing: RoomFacing.left,
        visualSize: RoomSize(13, 13),
        visualLayer: RoomVisualLayer.back,
        anchor: RoomObjectAnchor.wallCenter,
        relatedActionIds: {'T-05'},
        hitWidth: 14,
        hitHeight: 14,
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
