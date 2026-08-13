import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'avatar_room.dart';

enum AvatarFacing { front, back, left, right }

enum AvatarCharacterState { idle, walking, interacting, reacting }

class AvatarCharacterMetrics {
  const AvatarCharacterMetrics._();

  static const frameWidth = 360.0;
  static const frameHeight = 600.0;
  static const groundAnchor = Alignment.bottomCenter;
  static const runtimeScale = 1.0;
  static const visibleGroundInset = 20.0;
}

class AvatarMovementSystem {
  const AvatarMovementSystem._();

  /// The previous implementation completed every requested journey in 1.2s.
  /// A 20% speed multiplier means the same journey now takes exactly 6s.
  static const previousJourneyDuration = Duration(milliseconds: 1200);
  static const speedMultiplier = 0.2;
  static const journeyDuration = Duration(milliseconds: 6000);
  static const walkCycleDuration = Duration(milliseconds: 1200);

  static List<Duration> durations(RoomPoint from, List<RoomPoint> path) {
    if (path.isEmpty) return const [];
    final lengths = <double>[];
    var cursor = from;
    for (final point in path) {
      lengths.add(cursor.distanceTo(point));
      cursor = point;
    }
    final total = lengths.fold<double>(0, (sum, length) => sum + length);
    if (total == 0) return List.filled(path.length, Duration.zero);
    var assigned = 0;
    final result = <Duration>[];
    for (var index = 0; index < lengths.length; index++) {
      final milliseconds = index == lengths.length - 1
          ? journeyDuration.inMilliseconds - assigned
          : math.max(
              1,
              (journeyDuration.inMilliseconds * lengths[index] / total).round(),
            );
      result.add(Duration(milliseconds: milliseconds));
      assigned += milliseconds;
    }
    return result;
  }

  static AvatarFacing facing(RoomPoint from, RoomPoint to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    return dx.abs() > dy.abs()
        ? (dx < 0 ? AvatarFacing.left : AvatarFacing.right)
        : (dy < 0 ? AvatarFacing.back : AvatarFacing.front);
  }

  static List<RoomPoint> path({
    required RoomPoint from,
    required RoomPoint wanted,
    required WalkableArea walkableArea,
    required List<RoomRect> obstacles,
  }) {
    final target = walkableArea.clamp(wanted, obstacles);
    if (_segmentIsClear(from, target, walkableArea, obstacles)) {
      return [target];
    }
    // Build a small visibility graph around expanded obstacle corners. This
    // keeps navigation theme-independent while guaranteeing that a fallback
    // route never cuts through furniture.
    final nodes = <RoomPoint>[from, target];
    const clearance = 1.5;
    for (final obstacle in obstacles) {
      final right = obstacle.left + obstacle.width;
      final bottom = obstacle.top + obstacle.height;
      for (final corner in [
        RoomPoint(obstacle.left - clearance, obstacle.top - clearance),
        RoomPoint(right + clearance, obstacle.top - clearance),
        RoomPoint(obstacle.left - clearance, bottom + clearance),
        RoomPoint(right + clearance, bottom + clearance),
      ]) {
        if (walkableArea.contains(corner) &&
            !obstacles.any((obstacle) => obstacle.contains(corner))) {
          nodes.add(corner);
        }
      }
    }

    final distance = List<double>.filled(nodes.length, double.infinity);
    final previous = List<int>.filled(nodes.length, -1);
    final visited = List<bool>.filled(nodes.length, false);
    distance[0] = 0;
    for (var step = 0; step < nodes.length; step++) {
      var current = -1;
      for (var index = 0; index < nodes.length; index++) {
        if (!visited[index] &&
            (current == -1 || distance[index] < distance[current])) {
          current = index;
        }
      }
      if (current == -1 || distance[current].isInfinite) break;
      if (current == 1) break;
      visited[current] = true;
      for (var next = 0; next < nodes.length; next++) {
        if (next == current || visited[next]) continue;
        if (!_segmentIsClear(
          nodes[current],
          nodes[next],
          walkableArea,
          obstacles,
        )) {
          continue;
        }
        final candidate =
            distance[current] + nodes[current].distanceTo(nodes[next]);
        if (candidate < distance[next]) {
          distance[next] = candidate;
          previous[next] = current;
        }
      }
    }
    if (previous[1] == -1) return const [];
    final route = <RoomPoint>[];
    for (var cursor = 1; cursor != 0; cursor = previous[cursor]) {
      route.add(nodes[cursor]);
    }
    return route.reversed.toList();
  }

  static bool _segmentIsClear(
    RoomPoint from,
    RoomPoint to,
    WalkableArea walkableArea,
    List<RoomRect> obstacles,
  ) {
    final distance = from.distanceTo(to);
    final samples = math.max(1, distance.ceil());
    for (var index = 0; index <= samples; index++) {
      final ratio = index / samples;
      final point = RoomPoint(
        from.x + (to.x - from.x) * ratio,
        from.y + (to.y - from.y) * ratio,
      );
      if (!walkableArea.contains(point) ||
          obstacles.any((obstacle) => obstacle.contains(point))) {
        return false;
      }
    }
    return true;
  }
}

class AvatarAnimationRegistry {
  const AvatarAnimationRegistry._();

  static const idleAsset = 'assets/avatars/normalized/avatar_idle_action.png';
  static const walkAsset = 'assets/avatars/normalized/avatar_walk.png';
  static const interactionAsset =
      'assets/avatars/normalized/avatar_interaction.png';
  static const interactionExtraAsset =
      'assets/avatars/normalized/avatar_interaction_extra.png';
  static const walkFramesPerDirection = 4;

  static int directionRow(AvatarFacing facing) => switch (facing) {
    AvatarFacing.front => 0,
    AvatarFacing.back => 1,
    AvatarFacing.left => 2,
    AvatarFacing.right => 3,
  };
}

class AvatarAtlasCell extends StatelessWidget {
  const AvatarAtlasCell({
    super.key,
    required this.asset,
    required this.columns,
    required this.rows,
    required this.column,
    required this.row,
  });

  final String asset;
  final int columns;
  final int rows;
  final int column;
  final int row;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => ClipRect(
      child: OverflowBox(
        alignment: Alignment(
          columns == 1 ? 0 : -1 + column * (2 / (columns - 1)),
          rows == 1 ? 0 : -1 + row * (2 / (rows - 1)),
        ),
        minWidth: box.maxWidth * columns,
        maxWidth: box.maxWidth * columns,
        minHeight: box.maxHeight * rows,
        maxHeight: box.maxHeight * rows,
        child: Image.asset(
          asset,
          width: box.maxWidth * columns,
          height: box.maxHeight * rows,
          fit: BoxFit.fill,
          alignment: AvatarCharacterMetrics.groundAnchor,
          filterQuality: FilterQuality.medium,
        ),
      ),
    ),
  );
}
