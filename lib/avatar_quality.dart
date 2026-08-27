import 'package:flutter/scheduler.dart';

import 'avatar_room.dart';

const avatarQcEnabled = bool.fromEnvironment('AVATAR_QC');

enum AvatarQualityLevel { pass, watch, fail }

class AvatarQualityIssue {
  const AvatarQualityIssue({
    required this.code,
    required this.message,
    required this.level,
  });

  final String code;
  final String message;
  final AvatarQualityLevel level;
}

class AvatarQualityReport {
  const AvatarQualityReport({
    required this.roomId,
    required this.spatialScore,
    required this.interactionScore,
    required this.growthScore,
    required this.accessibilityScore,
    required this.performanceScore,
    required this.issues,
  });

  final String roomId;
  final int spatialScore;
  final int interactionScore;
  final int growthScore;
  final int accessibilityScore;
  final int performanceScore;
  final List<AvatarQualityIssue> issues;

  int get overall =>
      ((spatialScore * .28) +
              (interactionScore * .24) +
              (growthScore * .20) +
              (accessibilityScore * .14) +
              (performanceScore * .14))
          .round();

  AvatarQualityLevel get level => overall >= 90
      ? AvatarQualityLevel.pass
      : overall >= 75
      ? AvatarQualityLevel.watch
      : AvatarQualityLevel.fail;
}

class AvatarQualityEvaluator {
  const AvatarQualityEvaluator._();

  static AvatarQualityReport evaluate(AvatarRoom room) {
    var spatial = 100;
    var interaction = 100;
    var growth = 100;
    var accessibility = 100;
    var performance = 100;
    final issues = <AvatarQualityIssue>[];

    void issue(
      String code,
      String message,
      AvatarQualityLevel level, {
      required int penalty,
      required String dimension,
    }) {
      issues.add(
        AvatarQualityIssue(code: code, message: message, level: level),
      );
      switch (dimension) {
        case 'spatial':
          spatial -= penalty;
          break;
        case 'interaction':
          interaction -= penalty;
          break;
        case 'growth':
          growth -= penalty;
          break;
        case 'accessibility':
          accessibility -= penalty;
          break;
        case 'performance':
          performance -= penalty;
          break;
      }
    }

    if (!room.walkableArea.contains(room.initialAvatarPosition)) {
      issue(
        'SPATIAL_INITIAL_OUTSIDE',
        '처음 위치가 이동 가능한 바닥 밖에 있어요.',
        AvatarQualityLevel.fail,
        penalty: 45,
        dimension: 'spatial',
      );
    }
    for (final object in room.fixedObjects) {
      final bounds = object.visualBounds;
      if (bounds.left < 0 ||
          bounds.top < 0 ||
          bounds.right > 100 ||
          bounds.bottom > 100) {
        issue(
          'SPATIAL_OBJECT_BOUNDS',
          '${object.name} 그림이 공간 밖으로 벗어날 수 있어요.',
          AvatarQualityLevel.fail,
          penalty: 18,
          dimension: 'spatial',
        );
      }
      final point = object.resolvedInteractionPoint;
      if (!room.walkableArea.contains(point) ||
          room.collisions.any((collision) => collision.contains(point))) {
        issue(
          'INTERACTION_POINT_BLOCKED',
          '${object.name} 앞에 캐릭터가 설 수 있는 자리를 확인해 주세요.',
          AvatarQualityLevel.fail,
          penalty: 22,
          dimension: 'interaction',
        );
      }
      if (object.interactionAnimation.trim().isEmpty) {
        issue(
          'INTERACTION_MOTION_MISSING',
          '${object.name}의 행동 모션이 비어 있어요.',
          AvatarQualityLevel.fail,
          penalty: 30,
          dimension: 'interaction',
        );
      }
      if (object.interactionArea.width < RoomObject.minimumHitWidth ||
          object.interactionArea.height < RoomObject.minimumHitHeight) {
        issue(
          'A11Y_SMALL_TARGET',
          '${object.name}의 터치 영역이 작아요.',
          AvatarQualityLevel.watch,
          penalty: 10,
          dimension: 'accessibility',
        );
      }
    }
    if (room.fixedObjects.length < 2) {
      issue(
        'INTERACTION_TOO_FEW',
        '방 안에서 바로 해볼 수 있는 행동이 부족해요.',
        AvatarQualityLevel.watch,
        penalty: 18,
        dimension: 'interaction',
      );
    }
    if (room.categoryIds.isEmpty) {
      issue(
        'GROWTH_CATEGORY_MISSING',
        '이 공간과 연결된 행동 카테고리가 없어요.',
        AvatarQualityLevel.fail,
        penalty: 40,
        dimension: 'growth',
      );
    }
    if (room.slots.isEmpty) {
      issue(
        'GROWTH_SLOT_MISSING',
        '행동으로 얻은 물건을 둘 자리가 없어요.',
        AvatarQualityLevel.fail,
        penalty: 40,
        dimension: 'growth',
      );
    }
    for (final slot in room.slots) {
      if (slot.allowedItemIds.isEmpty) {
        issue(
          'GROWTH_SLOT_EMPTY',
          '${slot.label}에 연결된 보상 물건이 없어요.',
          AvatarQualityLevel.watch,
          penalty: 12,
          dimension: 'growth',
        );
      }
      if (!room.walkableArea.contains(slot.approachPoint)) {
        issue(
          'GROWTH_SLOT_UNREACHABLE',
          '${slot.label} 가까이 갈 수 없어요.',
          AvatarQualityLevel.fail,
          penalty: 18,
          dimension: 'growth',
        );
      }
    }
    if (room.backgroundAnchors.length < 3) {
      issue(
        'SPATIAL_ANCHOR_THIN',
        '배경과 오브젝트를 맞추는 기준점이 부족해요.',
        AvatarQualityLevel.watch,
        penalty: 10,
        dimension: 'spatial',
      );
    }
    final sceneNodes = room.fixedObjects.length + room.slots.length + 2;
    if (sceneNodes > 18) {
      issue(
        'PERF_SCENE_DENSE',
        '한 화면의 움직이는 요소가 많아 저사양 기기에서 느려질 수 있어요.',
        AvatarQualityLevel.watch,
        penalty: 18,
        dimension: 'performance',
      );
    }

    return AvatarQualityReport(
      roomId: room.id,
      spatialScore: spatial.clamp(0, 100),
      interactionScore: interaction.clamp(0, 100),
      growthScore: growth.clamp(0, 100),
      accessibilityScore: accessibility.clamp(0, 100),
      performanceScore: performance.clamp(0, 100),
      issues: issues,
    );
  }

  static List<AvatarQualityReport> evaluateAll(List<AvatarRoom> rooms) =>
      rooms.map(evaluate).toList(growable: false);
}

class AvatarPerformanceSnapshot {
  const AvatarPerformanceSnapshot({
    required this.frameCount,
    required this.jankyFrameCount,
    required this.averageBuildMs,
    required this.averageRasterMs,
    required this.p90TotalMs,
  });

  final int frameCount;
  final int jankyFrameCount;
  final double averageBuildMs;
  final double averageRasterMs;
  final double p90TotalMs;

  double get jankRate => frameCount == 0 ? 0 : jankyFrameCount / frameCount;
}

class AvatarPerformanceMonitor {
  static const severeJankBudgetMs = 33.3;
  final List<FrameTiming> _samples = [];

  void start() => SchedulerBinding.instance.addTimingsCallback(record);

  void stop() => SchedulerBinding.instance.removeTimingsCallback(record);

  void reset() => _samples.clear();

  void record(List<FrameTiming> timings) {
    _samples.addAll(timings);
    if (_samples.length > 240) {
      _samples.removeRange(0, _samples.length - 240);
    }
  }

  AvatarPerformanceSnapshot get snapshot {
    if (_samples.isEmpty) {
      return const AvatarPerformanceSnapshot(
        frameCount: 0,
        jankyFrameCount: 0,
        averageBuildMs: 0,
        averageRasterMs: 0,
        p90TotalMs: 0,
      );
    }
    final totals =
        _samples
            .map(
              (sample) =>
                  (sample.buildDuration + sample.rasterDuration)
                      .inMicroseconds /
                  1000,
            )
            .toList()
          ..sort();
    final build = _samples.fold<double>(
      0,
      (sum, sample) => sum + sample.buildDuration.inMicroseconds / 1000,
    );
    final raster = _samples.fold<double>(
      0,
      (sum, sample) => sum + sample.rasterDuration.inMicroseconds / 1000,
    );
    return AvatarPerformanceSnapshot(
      frameCount: _samples.length,
      jankyFrameCount: totals
          .where((value) => value > severeJankBudgetMs)
          .length,
      averageBuildMs: build / _samples.length,
      averageRasterMs: raster / _samples.length,
      p90TotalMs: totals[((totals.length - 1) * .9).round()],
    );
  }
}
