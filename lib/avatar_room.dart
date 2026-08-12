import 'package:flutter/material.dart';

/// A logical position inside every avatar room. Values are intentionally kept
/// in the 0–100 room coordinate system, never in device pixels.
class RoomPoint {
  const RoomPoint(this.x, this.y);
  final double x;
  final double y;

  Offset toOffset(Size size) =>
      Offset(size.width * x / 100, size.height * y / 100);
  RoomPoint copyWith({double? x, double? y}) =>
      RoomPoint(x ?? this.x, y ?? this.y);
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

/// Supports non-rectangular floor plans so future themes can use a different
/// shaped walkable floor without changing the movement implementation.
class WalkableArea {
  const WalkableArea(this.points);
  final List<RoomPoint> points;

  bool contains(RoomPoint point) {
    var inside = false;
    for (var i = 0, j = points.length - 1; i < points.length; j = i++) {
      final a = points[i];
      final b = points[j];
      final crosses =
          (a.y > point.y) != (b.y > point.y) &&
          point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
      if (crosses) inside = !inside;
    }
    return inside;
  }

  RoomPoint nearestAllowed(
    RoomPoint wanted, {
    List<RoomRect> blocked = const [],
  }) {
    if (_allows(wanted, blocked)) return wanted;
    // A short radial search preserves an intuitive destination while keeping
    // the character safely on the floor and outside furniture.
    for (var radius = 1.0; radius <= 55; radius += 1) {
      for (var step = 0; step < 16; step++) {
        final angle = step * 6.283185 / 16;
        final point = RoomPoint(
          (wanted.x + radius * _cos(angle)).clamp(0, 100).toDouble(),
          (wanted.y + radius * _sin(angle)).clamp(0, 100).toDouble(),
        );
        if (_allows(point, blocked)) return point;
      }
    }
    return points.last;
  }

  bool _allows(RoomPoint point, List<RoomRect> blocked) =>
      contains(point) && !blocked.any((boundary) => boundary.contains(point));

  // Avoid importing dart:math solely for two tiny coordinate helpers.
  static double _sin(double value) => value == 0
      ? 0
      : value == 1.57079625
      ? 1
      : value == 3.1415925
      ? 0
      : value == 4.71238875
      ? -1
      :
        // The search only needs a stable ring; these sampled directions are fine.
        const <double>[
          0,
          .3827,
          .7071,
          .9239,
          1,
          .9239,
          .7071,
          .3827,
          0,
          -.3827,
          -.7071,
          -.9239,
          -1,
          -.9239,
          -.7071,
          -.3827,
        ][((value / 6.283185 * 16).round()) % 16];
  static double _cos(double value) => _sin(value + 1.57079625);
}

class InteractiveObject {
  const InteractiveObject({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.interactionRadius,
    required this.interactionType,
    this.depth = 0,
    this.enabled = true,
    this.collision,
  });
  final String id;
  final String type;
  final RoomPoint position;
  final Size size;
  final double interactionRadius;
  final String interactionType;
  final double depth;
  final bool enabled;
  final RoomRect? collision;

  bool isNearby(RoomPoint point) {
    final dx = point.x - position.x;
    final dy = point.y - position.y;
    return dx * dx + dy * dy <= interactionRadius * interactionRadius;
  }
}

class DecorationSlot {
  const DecorationSlot(this.itemId, this.position, {this.layer = 0});
  final String itemId;
  final RoomPoint position;
  final int layer;
}

class AvatarRoom {
  const AvatarRoom({
    required this.id,
    required this.label,
    required this.backgroundAsset,
    required this.walkableArea,
    required this.objects,
    required this.decorationSlots,
  });
  final String id;
  final String label;
  final String backgroundAsset;
  final WalkableArea walkableArea;
  final List<InteractiveObject> objects;
  final List<DecorationSlot> decorationSlots;

  List<RoomRect> get collisions =>
      objects.map((item) => item.collision).whereType<RoomRect>().toList();
  InteractiveObject? nearby(RoomPoint point) {
    for (final item in objects) {
      if (item.enabled && item.isNearby(point)) return item;
    }
    return null;
  }

  DecorationSlot? slotFor(String itemId) {
    for (final slot in decorationSlots) {
      if (slot.itemId == itemId) return slot;
    }
    return null;
  }
}

const avatarRooms = <AvatarRoom>[
  AvatarRoom(
    id: 'bathroom',
    label: '욕실',
    backgroundAsset: 'assets/avatar_backgrounds/bathroom.png',
    walkableArea: WalkableArea([
      RoomPoint(12, 53),
      RoomPoint(88, 53),
      RoomPoint(95, 91),
      RoomPoint(8, 91),
    ]),
    objects: [
      InteractiveObject(
        id: 'bathroom_sink',
        type: 'sink',
        position: RoomPoint(68, 57),
        size: Size(18, 13),
        interactionRadius: 13,
        interactionType: 'wash',
        collision: RoomRect(58, 42, 25, 14),
      ),
      InteractiveObject(
        id: 'bathroom_towel',
        type: 'towel',
        position: RoomPoint(84, 43),
        size: Size(8, 14),
        interactionRadius: 10,
        interactionType: 'dry',
      ),
    ],
    decorationSlots: [
      DecorationSlot('bathroom_soap_01', RoomPoint(67, 47)),
      DecorationSlot('bathroom_toothbrush_01', RoomPoint(76, 47)),
      DecorationSlot('bathroom_towel_01', RoomPoint(85, 36)),
      DecorationSlot('bathroom_bubble_01', RoomPoint(36, 65)),
    ],
  ),
  AvatarRoom(
    id: 'playroom',
    label: '놀이방',
    backgroundAsset: 'assets/avatar_backgrounds/playroom.png',
    walkableArea: WalkableArea([
      RoomPoint(8, 52),
      RoomPoint(92, 52),
      RoomPoint(96, 91),
      RoomPoint(5, 91),
    ]),
    objects: [
      InteractiveObject(
        id: 'playroom_toy_box',
        type: 'toyBox',
        position: RoomPoint(31, 67),
        size: Size(18, 13),
        interactionRadius: 14,
        interactionType: 'play',
        collision: RoomRect(22, 56, 20, 13),
      ),
      InteractiveObject(
        id: 'playroom_shelf',
        type: 'shelf',
        position: RoomPoint(74, 40),
        size: Size(18, 18),
        interactionRadius: 12,
        interactionType: 'organize',
        collision: RoomRect(67, 24, 20, 30),
      ),
    ],
    decorationSlots: [
      DecorationSlot('playroom_toybox_01', RoomPoint(31, 67)),
      DecorationSlot('playroom_shelf_01', RoomPoint(74, 40)),
    ],
  ),
  AvatarRoom(
    id: 'kitchen',
    label: '주방',
    backgroundAsset: 'assets/avatar_backgrounds/kitchen.png',
    walkableArea: WalkableArea([
      RoomPoint(8, 56),
      RoomPoint(91, 56),
      RoomPoint(96, 91),
      RoomPoint(5, 91),
    ]),
    objects: [
      InteractiveObject(
        id: 'kitchen_table',
        type: 'table',
        position: RoomPoint(55, 59),
        size: Size(24, 13),
        interactionRadius: 14,
        interactionType: 'drink',
        collision: RoomRect(43, 50, 27, 15),
      ),
      InteractiveObject(
        id: 'kitchen_shelf',
        type: 'cabinet',
        position: RoomPoint(82, 42),
        size: Size(15, 22),
        interactionRadius: 10,
        interactionType: 'look',
        collision: RoomRect(75, 25, 20, 27),
      ),
    ],
    decorationSlots: [
      DecorationSlot('kitchen_cup_01', RoomPoint(61, 53)),
      DecorationSlot('kitchen_table_01', RoomPoint(52, 58)),
    ],
  ),
  AvatarRoom(
    id: 'entrance',
    label: '현관',
    backgroundAsset: 'assets/avatar_backgrounds/entrance.png',
    walkableArea: WalkableArea([
      RoomPoint(9, 54),
      RoomPoint(91, 54),
      RoomPoint(94, 91),
      RoomPoint(6, 91),
    ]),
    objects: [
      InteractiveObject(
        id: 'entrance_bag_hook',
        type: 'bagHook',
        position: RoomPoint(27, 55),
        size: Size(12, 15),
        interactionRadius: 12,
        interactionType: 'pack',
      ),
      InteractiveObject(
        id: 'entrance_shoe_rack',
        type: 'shoeRack',
        position: RoomPoint(72, 62),
        size: Size(18, 13),
        interactionRadius: 12,
        interactionType: 'prepare',
        collision: RoomRect(64, 53, 20, 14),
      ),
    ],
    decorationSlots: [
      DecorationSlot('entrance_bag_01', RoomPoint(27, 56)),
      DecorationSlot('entrance_shoe_rack_01', RoomPoint(72, 61)),
    ],
  ),
  AvatarRoom(
    id: 'bedroom',
    label: '침실',
    backgroundAsset: 'assets/avatar_backgrounds/bedroom.png',
    walkableArea: WalkableArea([
      RoomPoint(8, 56),
      RoomPoint(92, 56),
      RoomPoint(96, 91),
      RoomPoint(5, 91),
    ]),
    objects: [
      InteractiveObject(
        id: 'bedroom_lamp',
        type: 'lamp',
        position: RoomPoint(73, 43),
        size: Size(10, 15),
        interactionRadius: 13,
        interactionType: 'rest',
      ),
      InteractiveObject(
        id: 'bedroom_bed',
        type: 'bed',
        position: RoomPoint(35, 58),
        size: Size(29, 18),
        interactionRadius: 13,
        interactionType: 'rest',
        collision: RoomRect(18, 47, 35, 20),
      ),
    ],
    decorationSlots: [
      DecorationSlot('bedroom_lamp_01', RoomPoint(72, 43)),
      DecorationSlot('bedroom_star_01', RoomPoint(58, 23)),
    ],
  ),
  AvatarRoom(
    id: 'safety',
    label: '안전 활동',
    backgroundAsset: 'assets/avatar_backgrounds/safety.png',
    walkableArea: WalkableArea([
      RoomPoint(9, 55),
      RoomPoint(91, 55),
      RoomPoint(95, 91),
      RoomPoint(5, 91),
    ]),
    objects: [
      InteractiveObject(
        id: 'safety_crosswalk',
        type: 'crosswalk',
        position: RoomPoint(52, 67),
        size: Size(38, 15),
        interactionRadius: 14,
        interactionType: 'stop',
      ),
      InteractiveObject(
        id: 'safety_car',
        type: 'car',
        position: RoomPoint(75, 61),
        size: Size(20, 13),
        interactionRadius: 10,
        interactionType: 'observe',
        collision: RoomRect(65, 51, 27, 14),
      ),
    ],
    decorationSlots: [
      DecorationSlot('safety_car_01', RoomPoint(74, 62)),
      DecorationSlot('safety_cone_01', RoomPoint(51, 67)),
    ],
  ),
];
