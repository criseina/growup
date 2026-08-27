import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'avatar_character_system.dart';
import 'avatar_object_sprite.dart';
import 'avatar_quality.dart';
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
  final _performanceMonitor = AvatarPerformanceMonitor();
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
  final List<String> _recentAutonomy = [];
  String _activityLabel = '무엇을 해볼지 둘러보는 중';

  AvatarRoom get _room => avatarRooms[_roomIndex];

  @override
  void initState() {
    super.initState();
    _performanceMonitor.start();
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
        final freshPlacements = _placements
            .where((placement) => !_recentAutonomy.contains(placement.id))
            .toList();
        final freshObjects = _room.fixedObjects
            .where((object) => !_recentAutonomy.contains(object.id))
            .toList();
        if (freshPlacements.isNotEmpty && _random.nextBool()) {
          final placement =
              freshPlacements[_random.nextInt(freshPlacements.length)];
          _approachAcquired(placement);
        } else if (freshObjects.isNotEmpty && _random.nextInt(4) == 0) {
          final object = freshObjects[_random.nextInt(freshObjects.length)];
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
      obstacles: _room.navigationCollisions,
    );
    if (path.isEmpty) {
      setState(() {
        _moving = false;
        _pose = _AvatarPose.front;
        _activeObject = null;
        _bubble = interactionTarget == null
            ? null
            : '${interactionTarget.name} 앞에는 지금 갈 수 없어요';
        _activityLabel = interactionTarget == null
            ? '잠깐 쉬고 있어요'
            : '${interactionTarget.name} 가까이 갈 수 없어요';
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
      _activityLabel = interactionTarget == null
          ? '방을 천천히 둘러보는 중'
          : '${interactionTarget.name} 쪽으로 가는 중';
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
        _activityLabel = interactionTarget == null
            ? '새로운 것을 찾는 중'
            : '${interactionTarget.name}${_interactionCopy(interactionTarget.interaction)}';
      });
      if (interactionTarget != null) {
        _interactionTimer = Timer(interactionTarget.interactionDuration, () {
          if (!mounted) return;
          setState(() {
            _pose = _AvatarPose.front;
            _activeObject = null;
            _bubble = null;
            _activityLabel = '다음 행동을 생각하는 중';
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

  void _approachFixed(RoomObject object) {
    _rememberAutonomy(object.id);
    _moveTo(object.approachPoint, interactionTarget: object);
  }

  void _approachAcquired(SpacePlacement placement) {
    final item = GrowthRewardRepository.items
        .where((candidate) => candidate.id == placement.itemId)
        .firstOrNull;
    if (item == null || item.spaceId != _room.id) return;
    _rememberAutonomy(placement.id);
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

  void _rememberAutonomy(String id) {
    _recentAutonomy.remove(id);
    _recentAutonomy.add(id);
    while (_recentAutonomy.length > 2) {
      _recentAutonomy.removeAt(0);
    }
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
      _activityLabel = '반갑게 인사하는 중';
    });
    _interactionTimer?.cancel();
    _interactionTimer = Timer(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      setState(() {
        _pose = _AvatarPose.front;
        _bubble = null;
        _activityLabel = '무엇을 해볼지 둘러보는 중';
      });
    });
  }

  @override
  void dispose() {
    _autonomyTimer?.cancel();
    _arrivalTimer?.cancel();
    _interactionTimer?.cancel();
    _performanceMonitor.stop();
    _motion.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 66,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '나의 성장 공간',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            '${_room.label} · ${_categoryLabel(_room.id)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff52705c),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        if (kDebugMode || avatarQcEnabled)
          IconButton(
            icon: const Icon(Icons.verified_outlined),
            tooltip: '아바타 공간 QC',
            onPressed: _openQualityPanel,
          ),
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
          _activityLabel = '새 공간을 둘러보는 중';
          _recentAutonomy.clear();
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
        activeObjectId: _activeObject?.id,
        activeObjectDepth: _activeObject?.visualDepth,
        placements: index == _roomIndex ? _placements : const [],
        roomIndex: index,
        roomCount: avatarRooms.length,
        activityLabel: _activityLabel,
        motion: _motion,
        equipped: _equipped,
        onFloorTap: (point) => _moveTo(point),
        onFixedTap: _approachFixed,
        onItemTap: _approachAcquired,
        onItemLongPress: () => _openDecoration(),
        onAvatarTap: _reactToAvatar,
        onDecorate: _openDecoration,
        onSelectRoom: (roomIndex) => _pageController.animateToPage(
          roomIndex,
          duration: const Duration(milliseconds: 360),
          curve: Curves.easeOutCubic,
        ),
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

  void _openQualityPanel() {
    final reports = AvatarQualityEvaluator.evaluateAll(avatarRooms);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AvatarQualitySheet(
        currentRoom: _room,
        reports: reports,
        performance: _performanceMonitor.snapshot,
        onResetPerformance: () {
          _performanceMonitor.reset();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _go(Widget page) => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
    (route) => false,
  );

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
    required this.activeObjectId,
    required this.activeObjectDepth,
    required this.placements,
    required this.roomIndex,
    required this.roomCount,
    required this.activityLabel,
    required this.motion,
    required this.equipped,
    required this.onFloorTap,
    required this.onFixedTap,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onAvatarTap,
    required this.onDecorate,
    required this.onSelectRoom,
  });

  final AvatarRoom room;
  final bool active;
  final RoomPoint position;
  final _AvatarPose pose;
  final bool moving;
  final Duration movementDuration;
  final String? bubble;
  final String? interactionAnimation;
  final String? activeObjectId;
  final double? activeObjectDepth;
  final List<SpacePlacement> placements;
  final int roomIndex;
  final int roomCount;
  final String activityLabel;
  final Animation<double> motion;
  final Map<String, String> equipped;
  final ValueChanged<RoomPoint> onFloorTap;
  final ValueChanged<RoomObject> onFixedTap;
  final ValueChanged<SpacePlacement> onItemTap;
  final VoidCallback onItemLongPress;
  final VoidCallback onAvatarTap;
  final VoidCallback onDecorate;
  final ValueChanged<int> onSelectRoom;

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
    // While interacting, keep the child visible in front of the selected
    // furniture. Navigation collisions handle ordinary walking occlusion.
    final avatarDepth = AvatarDepthSystem.renderDepth(
      floorY: position.y,
      interactionObjectDepth: activeObjectDepth,
    );
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
              depth: avatarDepth,
              order: 2,
              child: _AnimatedScenePosition(
                duration: movementDuration,
                left: foot.dx - 34 * depthScale,
                top: foot.dy - 7,
                width: 68 * depthScale,
                height: 12 * depthScale,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .20),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          if (active)
            (
              depth: avatarDepth,
              order: 3,
              child: _AnimatedScenePosition(
                duration: movementDuration,
                left: foot.dx - avatarWidth / 2,
                top: foot.dy - avatarHeight + spriteFootInset,
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
            active: object.id == activeObjectId,
            onTap: () => onFixedTap(object),
          ),
        Positioned(
          top: 10,
          left: 12,
          right: 12,
          child: _RoomStatusCard(
            room: room,
            activityLabel: activityLabel,
            placedCount: placements.length,
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _RoomDock(
            currentIndex: roomIndex,
            roomCount: roomCount,
            onSelectRoom: onSelectRoom,
            onDecorate: onDecorate,
          ),
        ),
      ],
    );
  }
}

class _AnimatedScenePosition extends StatelessWidget {
  const _AnimatedScenePosition({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.duration,
    required this.child,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    top: 0,
    child: TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(end: Offset(left, top)),
      duration: duration,
      // A constant world speed keeps the foot cycle synchronized with travel.
      // Easing each short path segment made the avatar look as if it slid.
      curve: Curves.linear,
      builder: (context, offset, child) =>
          Transform.translate(offset: offset, child: child),
      child: SizedBox(width: width, height: height, child: child),
    ),
  );
}

class _RoomStatusCard extends StatelessWidget {
  const _RoomStatusCard({
    required this.room,
    required this.activityLabel,
    required this.placedCount,
  });

  final AvatarRoom room;
  final String activityLabel;
  final int placedCount;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: '${room.label}, $activityLabel, 배치한 성장 물건 $placedCount개',
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xfff9fff5).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x3353945e)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xffe2f4dc),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _roomIcon(room.id),
                size: 18,
                color: const Color(0xff247342),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    activityLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff244c31),
                    ),
                  ),
                  const Text(
                    '물건을 누르면 가까이 가서 행동해요',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: Color(0xff607367)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xffffefbd),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '★ $placedCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xff805f13),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  IconData _roomIcon(String roomId) => switch (roomId) {
    'bathroom' => Icons.water_drop_outlined,
    'bedroom' => Icons.bed_outlined,
    'kitchen' => Icons.restaurant_outlined,
    'playroom' => Icons.toys_outlined,
    'entrance' => Icons.directions_walk_rounded,
    'toilet' => Icons.wc_outlined,
    _ => Icons.home_outlined,
  };
}

class _RoomDock extends StatelessWidget {
  const _RoomDock({
    required this.currentIndex,
    required this.roomCount,
    required this.onSelectRoom,
    required this.onDecorate,
  });

  final int currentIndex;
  final int roomCount;
  final ValueChanged<int> onSelectRoom;
  final VoidCallback onDecorate;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xff173f2a).withValues(alpha: .91),
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 5,
              children: List.generate(
                roomCount,
                (index) => Semantics(
                  button: true,
                  selected: index == currentIndex,
                  label: '${index + 1}번째 성장 공간',
                  child: InkWell(
                    onTap: () => onSelectRoom(index),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: index == currentIndex ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == currentIndex
                            ? const Color(0xffd8f2cf)
                            : const Color(0x88ffffff),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              backgroundColor: const Color(0xffeef9e9),
              foregroundColor: const Color(0xff1d6f3c),
            ),
            onPressed: onDecorate,
            icon: const Icon(Icons.chair_alt_outlined, size: 16),
            label: const Text(
              '꾸미기',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AvatarQualitySheet extends StatelessWidget {
  const _AvatarQualitySheet({
    required this.currentRoom,
    required this.reports,
    required this.performance,
    required this.onResetPerformance,
  });

  final AvatarRoom currentRoom;
  final List<AvatarQualityReport> reports;
  final AvatarPerformanceSnapshot performance;
  final VoidCallback onResetPerformance;

  @override
  Widget build(BuildContext context) {
    final current = reports.firstWhere(
      (report) => report.roomId == currentRoom.id,
    );
    final suiteScore =
        reports.fold<int>(0, (sum, report) => sum + report.overall) ~/
        reports.length;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '아바타 공간 QC',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _QualityBadge(score: suiteScore),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '6개 공간 통합 점수 $suiteScore점 · 현재 ${currentRoom.label} ${current.overall}점',
                style: const TextStyle(color: Color(0xff607367)),
              ),
              const SizedBox(height: 18),
              _QualityBar(label: '공간 좌표', score: current.spatialScore),
              _QualityBar(label: '상호작용', score: current.interactionScore),
              _QualityBar(label: '성장 연결', score: current.growthScore),
              _QualityBar(label: '접근성', score: current.accessibilityScore),
              _QualityBar(label: '구성 성능', score: current.performanceScore),
              const SizedBox(height: 14),
              const Text(
                'Critic 메모',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              if (current.issues.isEmpty)
                const Text('치명적인 구조 문제는 없어요. 실제 화면의 밀도와 움직임을 확인하세요.')
              else
                for (final issue in current.issues.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          issue.level == AvatarQualityLevel.fail
                              ? Icons.error_outline
                              : Icons.info_outline,
                          size: 17,
                          color: issue.level == AvatarQualityLevel.fail
                              ? const Color(0xffb94a48)
                              : const Color(0xff9a741c),
                        ),
                        const SizedBox(width: 7),
                        Expanded(child: Text(issue.message)),
                      ],
                    ),
                  ),
              const Divider(height: 28),
              const Text(
                '실행 성능',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 7),
              Text(
                performance.frameCount == 0
                    ? '아직 측정 프레임이 없어요. 방을 넘기고 캐릭터를 움직여 보세요.'
                    : '${performance.frameCount}프레임 · 큰 끊김 ${(performance.jankRate * 100).toStringAsFixed(1)}% · P90 ${performance.p90TotalMs.toStringAsFixed(1)}ms\n평균 Build ${performance.averageBuildMs.toStringAsFixed(1)}ms / Raster ${performance.averageRasterMs.toStringAsFixed(1)}ms',
              ),
              if (performance.frameCount >= 30) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        performance.jankRate <= .05 &&
                            performance.p90TotalMs <= 24
                        ? const Color(0xffe7f5e2)
                        : const Color(0xfffff1cf),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    performance.jankRate <= .05 && performance.p90TotalMs <= 24
                        ? '프레임 안정성 합격 · 큰 끊김 5% 이하, P90 24ms 이하예요.'
                        : '성능 확인 필요 · Profile 빌드에서 큰 끊김 5% 또는 P90 24ms를 넘으면 장면 요소와 애니메이션을 줄여 주세요.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (kDebugMode)
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Text(
                    '현재는 디버그 측정입니다. 최종 성능 판정은 Profile 빌드 값을 사용하세요.',
                    style: TextStyle(fontSize: 11, color: Color(0xff69726c)),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onResetPerformance,
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('성능 측정 다시 시작'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: score >= 90 ? const Color(0xffe1f4dc) : const Color(0xffffefbd),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text('$score점', style: const TextStyle(fontWeight: FontWeight.w900)),
  );
}

class _QualityBar extends StatelessWidget {
  const _QualityBar({required this.label, required this.score});
  final String label;
  final int score;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: score / 100,
              backgroundColor: const Color(0xffedf0ea),
              color: score >= 90
                  ? const Color(0xff4d9e62)
                  : const Color(0xffd5a534),
            ),
          ),
        ),
        const SizedBox(width: 9),
        SizedBox(width: 28, child: Text('$score')),
      ],
    ),
  );
}

class _FixedObjectHotspot extends StatelessWidget {
  const _FixedObjectHotspot({
    required this.object,
    required this.size,
    required this.active,
    required this.onTap,
  });
  final RoomObject object;
  final Size size;
  final bool active;
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: active
                ? Border.all(color: const Color(0xff57a66a), width: 2)
                : null,
            color: active ? const Color(0x2257a66a) : Colors.transparent,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: const Color(0x443e9657),
          ),
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

class _AvatarSprite extends StatefulWidget {
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
  State<_AvatarSprite> createState() => _AvatarSpriteState();
}

class _AvatarSpriteState extends State<_AvatarSprite> {
  int _walkFrame = 1;

  @override
  void initState() {
    super.initState();
    widget.motion.addListener(_updateWalkFrame);
  }

  @override
  void didUpdateWidget(covariant _AvatarSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion) {
      oldWidget.motion.removeListener(_updateWalkFrame);
      widget.motion.addListener(_updateWalkFrame);
    }
    if (!widget.moving && _walkFrame != 1) {
      _walkFrame = 1;
    }
  }

  void _updateWalkFrame() {
    if (!widget.moving) return;
    final next = (widget.motion.value * 4).floor().clamp(0, 3);
    if (next != _walkFrame && mounted) {
      setState(() => _walkFrame = next);
    }
  }

  @override
  void dispose() {
    widget.motion.removeListener(_updateWalkFrame);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The sprite now rebuilds only when its discrete walking frame changes,
    // rather than on every display refresh. This keeps the living-room motion
    // while avoiding continuous atlas rasterization.
    const runtimeScale = AvatarCharacterMetrics.runtimeScale;
    return Transform.scale(
      scale: runtimeScale,
      alignment: AvatarCharacterMetrics.groundAnchor,
      child: GestureDetector(
        onTap: widget.onTap,
        child: RepaintBoundary(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                child: widget.interactionAnimation != null && !widget.moving
                    ? _InteractionCell(animation: widget.interactionAnimation!)
                    : widget.equipped['top'] == 'avatar_top_01' &&
                          widget.pose == _AvatarPose.front &&
                          !widget.moving
                    ? Image.asset(
                        'assets/avatars/normalized/avatar_blue_top.png',
                        fit: BoxFit.fill,
                        alignment: AvatarCharacterMetrics.groundAnchor,
                      )
                    : _MotionCell(
                        pose: widget.pose,
                        walkFrame: widget.moving ? _walkFrame : 1,
                        walking: widget.moving,
                      ),
              ),
              if (widget.equipped['hat'] != null)
                Positioned(
                  top: 1,
                  child: AvatarRewardItemSprite(
                    itemId: widget.equipped['hat']!,
                    size: 42,
                  ),
                ),
              if (widget.equipped['accessory'] != null)
                Positioned(
                  right: 1,
                  bottom: 30,
                  child: AvatarRewardItemSprite(
                    itemId: widget.equipped['accessory']!,
                    size: 36,
                  ),
                ),
              if (_feedbackIcon(widget.interactionAnimation) case final icon?)
                Positioned(
                  right: 8,
                  top: 42,
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              if (widget.bubble != null)
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
                      widget.bubble!,
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
      ),
    );
  }

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
