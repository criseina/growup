import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'avatar_character_system.dart';
import 'avatar_object_sprite.dart';
import 'avatar_room.dart';
import 'growth_reward_pages.dart';
import 'growth_reward_repository.dart';
import 'main.dart' show ActionLibraryPage, GrowthRecordPage, HomePage;
import 'room_object_sprite.dart';

enum _AvatarPose { front, back, left, right, use, wipe, organize, wave }

class AvatarWorldPage extends StatefulWidget {
  const AvatarWorldPage({super.key, required this.profileId});
  final String profileId;

  @override
  State<AvatarWorldPage> createState() => _AvatarWorldPageState();
}

class _AvatarWorldPageState extends State<AvatarWorldPage>
    with SingleTickerProviderStateMixin {
  final _repository = GrowthRewardRepository();
  final _pageController = PageController();
  final _random = Random();
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: AvatarMovementSystem.walkCycleDuration,
  )..repeat();

  Timer? _autonomyTimer;
  Timer? _arrivalTimer;
  Timer? _interactionTimer;
  int _roomIndex = 0;
  RoomPoint _position = avatarRooms.first.initialAvatarPosition;
  _AvatarPose _pose = _AvatarPose.front;
  Duration _movementDuration = const Duration(milliseconds: 1);
  int _movementSerial = 0;
  bool _moving = false;
  String? _bubble;
  RoomObject? _activeObject;
  List<SpacePlacement> _placements = [];
  Map<String, String> _equipped = {};

  AvatarRoom get _room => avatarRooms[_roomIndex];

  @override
  void initState() {
    super.initState();
    _loadRoom();
    _scheduleAutonomy();
  }

  Future<void> _loadRoom() async {
    final loaded = await Future.wait<Object>([
      _repository.loadPlacements(
        profileId: widget.profileId,
        spaceId: _room.id,
      ),
      _repository.loadAvatar(widget.profileId),
    ]);
    if (!mounted) return;
    setState(() {
      _placements = loaded[0] as List<SpacePlacement>;
      _equipped = loaded[1] as Map<String, String>;
    });
  }

  void _scheduleAutonomy() {
    _autonomyTimer?.cancel();
    _autonomyTimer = Timer(Duration(seconds: 4 + _random.nextInt(4)), () {
      if (!mounted) return;
      if (!_moving && _activeObject == null) {
        if (_placements.isNotEmpty && _random.nextBool()) {
          final placement = _placements[_random.nextInt(_placements.length)];
          _approachAcquired(placement);
        } else if (_random.nextInt(4) == 0) {
          final object =
              _room.fixedObjects[_random.nextInt(_room.fixedObjects.length)];
          _approachFixed(object);
        } else {
          _moveTo(
            RoomPoint(
              16 + _random.nextDouble() * 68,
              67 + _random.nextDouble() * 22,
            ),
          );
        }
      }
      _scheduleAutonomy();
    });
  }

  void _moveTo(RoomPoint wanted, {RoomObject? interactionTarget}) {
    _arrivalTimer?.cancel();
    _interactionTimer?.cancel();
    final serial = ++_movementSerial;
    final destination = interactionTarget?.resolvedInteractionPoint ?? wanted;
    final path = AvatarMovementSystem.path(
      from: _position,
      wanted: destination,
      walkableArea: _room.walkableArea,
      obstacles: _room.collisions,
    );
    if (path.isEmpty) {
      setState(() {
        _moving = false;
        _pose = _AvatarPose.front;
        _activeObject = null;
        _bubble = interactionTarget == null
            ? null
            : '${interactionTarget.name} 앞에는 지금 갈 수 없어요';
      });
      return;
    }
    final durations = AvatarMovementSystem.durations(_position, path);
    _moveAlong(
      path,
      durations: durations,
      interactionTarget: interactionTarget,
      serial: serial,
    );
  }

  void _moveAlong(
    List<RoomPoint> path, {
    required List<Duration> durations,
    required RoomObject? interactionTarget,
    required int serial,
  }) {
    if (path.isEmpty || serial != _movementSerial) return;
    final target = path.first;
    final duration = durations.first;
    final facing = AvatarMovementSystem.facing(_position, target);
    setState(() {
      _position = target;
      _pose = _poseForFacing(facing);
      _movementDuration = duration;
      _moving = true;
      _bubble = null;
      _activeObject = null;
    });
    _arrivalTimer = Timer(duration, () {
      if (!mounted || serial != _movementSerial) return;
      final remaining = path.skip(1).toList();
      if (remaining.isNotEmpty) {
        _moveAlong(
          remaining,
          durations: durations.skip(1).toList(),
          interactionTarget: interactionTarget,
          serial: serial,
        );
        return;
      }
      setState(() {
        _moving = false;
        _pose = interactionTarget == null
            ? _AvatarPose.front
            : _poseForRoomFacing(interactionTarget.interactionFacing);
        _activeObject = interactionTarget;
        _bubble = interactionTarget == null
            ? null
            : '${interactionTarget.name}${_interactionCopy(interactionTarget.interaction)}';
      });
      if (interactionTarget != null) {
        _interactionTimer = Timer(interactionTarget.interactionDuration, () {
          if (!mounted) return;
          setState(() {
            _pose = _AvatarPose.front;
            _activeObject = null;
            _bubble = null;
          });
        });
      }
    });
  }

  _AvatarPose _poseForFacing(AvatarFacing facing) => switch (facing) {
    AvatarFacing.front => _AvatarPose.front,
    AvatarFacing.back => _AvatarPose.back,
    AvatarFacing.left => _AvatarPose.left,
    AvatarFacing.right => _AvatarPose.right,
  };

  _AvatarPose _poseForRoomFacing(RoomFacing facing) => switch (facing) {
    RoomFacing.front => _AvatarPose.front,
    RoomFacing.back => _AvatarPose.back,
    RoomFacing.left => _AvatarPose.left,
    RoomFacing.right => _AvatarPose.right,
  };

  String _interactionCopy(RoomInteraction interaction) => switch (interaction) {
    RoomInteraction.look => '을 살펴봐요',
    RoomInteraction.wash => '에서 깨끗이 씻어요',
    RoomInteraction.brush => '로 이를 닦아요',
    RoomInteraction.bathe => '에서 씻어요',
    RoomInteraction.dry => '로 닦아요',
    RoomInteraction.dress => '에서 옷을 준비해요',
    RoomInteraction.organize => '에 정리해요',
    RoomInteraction.pickUp => '을 집어 들어요',
    RoomInteraction.eat => '에서 먹어요',
    RoomInteraction.drink => '으로 마셔요',
    RoomInteraction.prepare => '을 챙겨요',
    RoomInteraction.stop => ' 앞에서 멈춰 살펴요',
    RoomInteraction.askHelp => '로 도움을 요청해요',
    RoomInteraction.rest => '에서 잠시 쉬어요',
    RoomInteraction.useToilet => '에 앉아 봐요',
    RoomInteraction.flush => '을 눌러 물을 내려요',
  };

  void _approachFixed(RoomObject object) =>
      _moveTo(object.approachPoint, interactionTarget: object);

  void _approachAcquired(SpacePlacement placement) {
    final item = GrowthRewardRepository.items
        .where((candidate) => candidate.id == placement.itemId)
        .firstOrNull;
    if (item == null || item.spaceId != _room.id) return;
    final placementPoint = RoomPoint(placement.x * 100, placement.y * 100);
    final slot = _room.nearestAcceptingSlot(item.id, placementPoint);
    final object = RoomObject(
      id: placement.id,
      name: item.name,
      kind: RoomObjectKind.acquired,
      itemId: item.id,
      position: RoomPoint(placement.x * 100, placement.y * 100),
      approachPoint:
          slot?.approachPoint ??
          _room.walkableArea.clamp(
            RoomPoint(placement.x * 100, placement.y * 100 + 12),
            _room.collisions,
          ),
      interaction: _interactionForAnimation(item.interactionAnimation),
      interactionAnimation: item.interactionAnimation,
      interactionFacing: _facingForAcquired(item.interactionAnimation),
      relatedActionIds: item.relatedActionIds.toSet(),
    );
    _moveTo(object.approachPoint, interactionTarget: object);
  }

  RoomInteraction _interactionForAnimation(String animation) =>
      switch (animation) {
        'wash_hands' || 'wash_hair' => RoomInteraction.wash,
        'brush_teeth' => RoomInteraction.brush,
        'dry' || 'clean' || 'wipe' => RoomInteraction.dry,
        'drink' => RoomInteraction.drink,
        'eat' => RoomInteraction.eat,
        'stop_and_look' || 'check_traffic_light' => RoomInteraction.stop,
        'ask_for_help' => RoomInteraction.askHelp,
        'prepare_bag' ||
        'prepare_bottle' ||
        'prepare_small_items' ||
        'prepare_umbrella' => RoomInteraction.prepare,
        'wear_shirt' || 'wear_pants' || 'wear_shoes' => RoomInteraction.dress,
        _ => RoomInteraction.organize,
      };

  RoomFacing _facingForAcquired(String animation) => switch (animation) {
    'stop_and_look' ||
    'check_traffic_light' ||
    'ask_for_help' => RoomFacing.front,
    _ => RoomFacing.back,
  };

  void _reactToAvatar() {
    _arrivalTimer?.cancel();
    setState(() {
      _moving = false;
      _pose = _AvatarPose.wave;
      _bubble = '안녕! 같이 둘러볼까?';
    });
    _interactionTimer?.cancel();
    _interactionTimer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      setState(() {
        _pose = _AvatarPose.front;
        _bubble = null;
      });
    });
  }

  @override
  void dispose() {
    _autonomyTimer?.cancel();
    _arrivalTimer?.cancel();
    _interactionTimer?.cancel();
    _motion.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${_room.label}에서 놀아요'),
      actions: [
        IconButton(
          icon: const Icon(Icons.checkroom_outlined),
          tooltip: '아바타 꾸미기',
          onPressed: () => Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => AvatarPage(profileId: widget.profileId),
                ),
              )
              .then((_) => _loadRoom()),
        ),
      ],
    ),
    body: PageView.builder(
      controller: _pageController,
      itemCount: avatarRooms.length,
      onPageChanged: (index) {
        _arrivalTimer?.cancel();
        _interactionTimer?.cancel();
        setState(() {
          _roomIndex = index;
          _position = avatarRooms[index].initialAvatarPosition;
          _pose = _AvatarPose.front;
          _moving = false;
          _bubble = null;
          _activeObject = null;
        });
        _loadRoom();
      },
      itemBuilder: (context, index) => _RoomScene(
        room: avatarRooms[index],
        active: index == _roomIndex,
        position: _position,
        pose: _pose,
        moving: _moving,
        movementDuration: _movementDuration,
        bubble: _bubble,
        interactionAnimation: _activeObject?.interactionAnimation,
        placements: index == _roomIndex ? _placements : const [],
        motion: _motion,
        equipped: _equipped,
        onFloorTap: (point) => _moveTo(point),
        onFixedTap: _approachFixed,
        onItemTap: _approachAcquired,
        onItemLongPress: () => _openDecoration(),
        onAvatarTap: _reactToAvatar,
        onDecorate: _openDecoration,
      ),
    ),
    bottomNavigationBar: _AvatarNavigation(
      onActions: () => _go(ActionLibraryPage(profileId: widget.profileId)),
      onHome: () => _go(const HomePage()),
      onRecords: () => _go(GrowthRecordPage(profileId: widget.profileId)),
    ),
  );

  void _openDecoration() => Navigator.of(context)
      .push(
        MaterialPageRoute(
          builder: (_) =>
              SpacePage(profileId: widget.profileId, initialSpaceId: _room.id),
        ),
      )
      .then((_) => _loadRoom());

  void _go(Widget page) => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
    (route) => false,
  );
}

class _RoomScene extends StatelessWidget {
  const _RoomScene({
    required this.room,
    required this.active,
    required this.position,
    required this.pose,
    required this.moving,
    required this.movementDuration,
    required this.bubble,
    required this.interactionAnimation,
    required this.placements,
    required this.motion,
    required this.equipped,
    required this.onFloorTap,
    required this.onFixedTap,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onAvatarTap,
    required this.onDecorate,
  });

  final AvatarRoom room;
  final bool active;
  final RoomPoint position;
  final _AvatarPose pose;
  final bool moving;
  final Duration movementDuration;
  final String? bubble;
  final String? interactionAnimation;
  final List<SpacePlacement> placements;
  final Animation<double> motion;
  final Map<String, String> equipped;
  final ValueChanged<RoomPoint> onFloorTap;
  final ValueChanged<RoomObject> onFixedTap;
  final ValueChanged<SpacePlacement> onItemTap;
  final VoidCallback onItemLongPress;
  final VoidCallback onAvatarTap;
  final VoidCallback onDecorate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = Size(constraints.maxWidth, constraints.maxHeight);
      final size = AvatarViewportSystem.contain(available);
      return ColoredBox(
        color: const Color(0xfffffbf5),
        child: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: _buildViewport(size),
          ),
        ),
      );
    },
  );

  Widget _buildViewport(Size size) {
    final foot = position.toScreen(size);
    final depthScale = .78 + (position.y / 100) * .25;
    final avatarHeight = 210 * depthScale;
    final avatarWidth = 126 * depthScale;
    // 모션 그림 한 칸 아래에 남은 투명 여백을 보정해 보이는 발이
    // 논리적인 발 좌표와 그림자에 맞닿게 한다.
    final spriteFootInset =
        AvatarCharacterMetrics.visibleGroundInset /
        AvatarCharacterMetrics.frameHeight *
        avatarHeight;
    final depthChildren =
        <({double depth, int order, Widget child})>[
          for (final object in room.fixedObjects)
            if (object.shouldRenderAtlas &&
                object.visualLayer == RoomVisualLayer.depthSorted)
              (
                depth: object.visualDepth,
                order: 0,
                child: PositionedRoomObject(object: object, viewportSize: size),
              ),
          for (final placement in placements)
            (
              depth: placement.y * 100,
              order: 1,
              child: _AcquiredObject(
                placement: placement,
                size: size,
                onTap: () => onItemTap(placement),
                onLongPress: onItemLongPress,
              ),
            ),
          if (active)
            (
              depth: position.y,
              order: 2,
              child: AnimatedPositioned(
                duration: movementDuration,
                curve: Curves.easeInOutCubic,
                left: foot.dx - 34 * depthScale,
                top: foot.dy - 7,
                child: Container(
                  width: 68 * depthScale,
                  height: 12 * depthScale,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .20),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          if (active)
            (
              depth: position.y,
              order: 3,
              child: AnimatedPositioned(
                duration: movementDuration,
                curve: Curves.easeInOutCubic,
                left: foot.dx - avatarWidth / 2,
                top: foot.dy - avatarHeight + spriteFootInset,
                child: SizedBox(
                  width: avatarWidth,
                  height: avatarHeight,
                  child: _AvatarSprite(
                    pose: pose,
                    moving: moving,
                    bubble: bubble,
                    interactionAnimation: interactionAnimation,
                    motion: motion,
                    equipped: equipped,
                    onTap: onAvatarTap,
                  ),
                ),
              ),
            ),
        ]..sort((a, b) {
          final byDepth = a.depth.compareTo(b.depth);
          return byDepth == 0 ? a.order.compareTo(b.order) : byDepth;
        });
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Image.asset(room.backgroundAsset, fit: BoxFit.fill),
        for (final object in room.fixedObjects)
          if (object.shouldRenderAtlas &&
              object.visualLayer == RoomVisualLayer.back)
            PositionedRoomObject(object: object, viewportSize: size),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapDown: (details) => onFloorTap(
              RoomPoint(
                details.localPosition.dx / size.width * 100,
                details.localPosition.dy / size.height * 100,
              ),
            ),
          ),
        ),
        for (final entry in depthChildren) entry.child,
        for (final object in room.fixedObjects)
          if (object.shouldRenderAtlas &&
              object.visualLayer == RoomVisualLayer.front)
            PositionedRoomObject(object: object, viewportSize: size),
        for (final object in room.fixedObjects)
          _FixedObjectHotspot(
            object: object,
            size: size,
            onTap: () => onFixedTap(object),
          ),
        Positioned(
          top: 10,
          left: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .90),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Text(
                '${room.label}  ${_categoryLabel(room.id)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 14,
          child: Center(
            child: FilledButton.icon(
              onPressed: onDecorate,
              icon: const Icon(Icons.home_outlined),
              label: const Text('공간 꾸미기'),
            ),
          ),
        ),
      ],
    );
  }

  String _categoryLabel(String roomId) => switch (roomId) {
    'bathroom' => '위생',
    'bedroom' => '옷 입기',
    'kitchen' => '식사',
    'playroom' => '물건과 집안일',
    'entrance' => '외출 준비 · 안전',
    'toilet' => '화장실',
    _ => '',
  };
}

class _FixedObjectHotspot extends StatelessWidget {
  const _FixedObjectHotspot({
    required this.object,
    required this.size,
    required this.onTap,
  });
  final RoomObject object;
  final Size size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rect = object.interactionArea;
    final width = rect.width * size.width / 100;
    final height = rect.height * size.height / 100;
    return Positioned(
      left: rect.left * size.width / 100,
      top: rect.top * size.height / 100,
      width: width,
      height: height,
      child: Semantics(
        button: true,
        label: '${object.name}과 상호작용',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0x443e9657),
        ),
      ),
    );
  }
}

class _AcquiredObject extends StatelessWidget {
  const _AcquiredObject({
    required this.placement,
    required this.size,
    required this.onTap,
    required this.onLongPress,
  });
  final SpacePlacement placement;
  final Size size;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => Positioned(
    left: placement.x * size.width - 31,
    // SpacePlacement stores the object's floor contact point. Acquired
    // objects therefore use the same bottom-center anchor as floor objects.
    top: placement.y * size.height - 62,
    child: Semantics(
      button: true,
      label: '획득 아이템과 상호작용',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AvatarObjectSprite(itemId: placement.itemId, size: 62),
      ),
    ),
  );
}

class _AvatarSprite extends StatelessWidget {
  const _AvatarSprite({
    required this.pose,
    required this.moving,
    required this.bubble,
    required this.interactionAnimation,
    required this.motion,
    required this.equipped,
    required this.onTap,
  });
  final _AvatarPose pose;
  final bool moving;
  final String? bubble;
  final String? interactionAnimation;
  final Animation<double> motion;
  final Map<String, String> equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    builder: (context, _) {
      // All states share a normalized 360x600 canvas, bottom-center ground
      // anchor and a single runtime scale. No direction/state correction.
      const runtimeScale = AvatarCharacterMetrics.runtimeScale;
      return Transform.scale(
        scale: runtimeScale,
        alignment: AvatarCharacterMetrics.groundAnchor,
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                child: interactionAnimation != null && !moving
                    ? _InteractionCell(animation: interactionAnimation!)
                    : equipped['top'] == 'avatar_top_01' &&
                          pose == _AvatarPose.front &&
                          !moving
                    ? Image.asset(
                        'assets/avatars/normalized/avatar_blue_top.png',
                        fit: BoxFit.fill,
                        alignment: AvatarCharacterMetrics.groundAnchor,
                      )
                    : _MotionCell(
                        pose: pose,
                        walkFrame: moving
                            ? (motion.value * 4).floor().clamp(0, 3)
                            : 1,
                        walking: moving,
                      ),
              ),
              if (equipped['hat'] != null)
                Positioned(
                  top: 1,
                  child: AvatarRewardItemSprite(
                    itemId: equipped['hat']!,
                    size: 42,
                  ),
                ),
              if (equipped['accessory'] != null)
                Positioned(
                  right: 1,
                  bottom: 30,
                  child: AvatarRewardItemSprite(
                    itemId: equipped['accessory']!,
                    size: 36,
                  ),
                ),
              if (_feedbackIcon(interactionAnimation) case final icon?)
                Positioned(
                  right: 8,
                  top: 42,
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              if (bubble != null)
                Positioned(
                  top: -38,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 170),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      bubble!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  String? _feedbackIcon(String? animation) => switch (animation) {
    'wash_hands' || 'wash_hair' || 'take_shower' => '🫧',
    'brush_teeth' => '✨',
    'dry' || 'clean' || 'wipe' => '🧽',
    'drink' => '💧',
    'eat' => '😋',
    'stop_and_look' || 'check_traffic_light' => '👀',
    'ask_for_help' => '💬',
    'use_toilet' || 'flush_toilet' => '✨',
    'prepare_bag' ||
    'prepare_bottle' ||
    'prepare_small_items' ||
    'prepare_umbrella' => '✓',
    null => null,
    _ => '✨',
  };
}

class _InteractionCell extends StatelessWidget {
  const _InteractionCell({required this.animation});

  final String animation;

  @override
  Widget build(BuildContext context) {
    final extraIndex = switch (animation) {
      'wear_shoes' => 0,
      'prepare_bag' || 'prepare_to_go_out' => 1,
      'prepare_umbrella' => 2,
      'wash_hair' || 'take_shower' => 3,
      'clean' => 4,
      'organize_books' => 5,
      'dry' => 6,
      'wash_hands' => 7,
      _ => null,
    };
    if (extraIndex != null) {
      return AvatarAtlasCell(
        asset: AvatarAnimationRegistry.interactionExtraAsset,
        columns: 4,
        rows: 2,
        column: extraIndex % 4,
        row: extraIndex ~/ 4,
      );
    }
    final index = switch (animation) {
      'look_in_mirror' => 0,
      'wash_hands' || 'wash_hair' || 'take_shower' || 'take_bath' => 1,
      'brush_teeth' => 2,
      'dry' || 'clean' || 'wipe' => 4,
      'wear_shirt' || 'wear_pants' || 'wear_shoes' || 'wear_outerwear' => 5,
      'organize' ||
      'organize_clothes' ||
      'organize_dishes' ||
      'organize_books' ||
      'organize_shoes' => 6,
      'eat' => 8,
      'drink' => 9,
      'prepare_bag' ||
      'prepare_bottle' ||
      'prepare_small_items' ||
      'prepare_umbrella' ||
      'prepare_to_go_out' ||
      'prepare_food' ||
      'choose_clothes' => 10,
      'stop_and_look' || 'check_traffic_light' => 11,
      'ask_for_help' => 12,
      'rest_on_bed' => 13,
      'use_toilet' => 14,
      'flush_toilet' => 15,
      _ => 7,
    };
    final column = index % 4;
    final row = index ~/ 4;
    return AvatarAtlasCell(
      asset: AvatarAnimationRegistry.interactionAsset,
      columns: 4,
      rows: 4,
      column: column,
      row: row,
    );
  }
}

class _MotionCell extends StatelessWidget {
  const _MotionCell({
    required this.pose,
    required this.walkFrame,
    required this.walking,
  });
  final _AvatarPose pose;
  final int walkFrame;
  final bool walking;

  @override
  Widget build(BuildContext context) {
    if (walking &&
        (pose == _AvatarPose.front ||
            pose == _AvatarPose.back ||
            pose == _AvatarPose.left ||
            pose == _AvatarPose.right)) {
      final row = switch (pose) {
        _AvatarPose.front => 0,
        _AvatarPose.back => 1,
        _AvatarPose.left => 2,
        _AvatarPose.right => 3,
        _ => 0,
      };
      return AvatarAtlasCell(
        asset: AvatarAnimationRegistry.walkAsset,
        columns: 4,
        rows: 4,
        column: walkFrame,
        row: row,
      );
    }
    final (column, row) = switch (pose) {
      _AvatarPose.front => (0, 0),
      _AvatarPose.back => (1, 0),
      _AvatarPose.left => (2, 0),
      _AvatarPose.right => (3, 0),
      _AvatarPose.use => (0, 1),
      _AvatarPose.wipe => (1, 1),
      _AvatarPose.organize => (2, 1),
      _AvatarPose.wave => (3, 1),
    };
    return AvatarAtlasCell(
      asset: AvatarAnimationRegistry.idleAsset,
      columns: 4,
      rows: 2,
      column: column,
      row: row,
    );
  }
}

class _AvatarNavigation extends StatelessWidget {
  const _AvatarNavigation({
    required this.onActions,
    required this.onHome,
    required this.onRecords,
  });
  final VoidCallback onActions;
  final VoidCallback onHome;
  final VoidCallback onRecords;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xfffffbf5),
        border: Border(top: BorderSide(color: Color(0xffe8e4dc))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Nav(
            icon: Icons.auto_awesome_outlined,
            label: '행동',
            onTap: onActions,
          ),
          _Nav(icon: Icons.home_rounded, label: '홈', onTap: onHome),
          const _Nav(
            icon: Icons.face_retouching_natural,
            label: '아바타',
            selected: true,
          ),
          _Nav(icon: Icons.menu_book_outlined, label: '기록', onTap: onRecords),
        ],
      ),
    ),
  );
}

class _Nav extends StatelessWidget {
  const _Nav({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xffe0f2dc) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: selected ? 30 : 23,
            color: selected ? const Color(0xff176a36) : const Color(0xff7b867d),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected
                  ? const Color(0xff176a36)
                  : const Color(0xff7b867d),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
