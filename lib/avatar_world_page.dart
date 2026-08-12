import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'avatar_object_sprite.dart';
import 'avatar_room.dart';
import 'growth_reward_pages.dart';
import 'growth_reward_repository.dart';
import 'main.dart' show ActionLibraryPage, GrowthRecordPage, HomePage;

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
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  Timer? _autonomyTimer;
  Timer? _arrivalTimer;
  Timer? _interactionTimer;
  int _roomIndex = 0;
  RoomPoint _position = const RoomPoint(50, 77);
  _AvatarPose _pose = _AvatarPose.front;
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
      if (!mounted || _moving || _activeObject != null) return;
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
      _scheduleAutonomy();
    });
  }

  void _moveTo(RoomPoint wanted, {RoomObject? interactionTarget}) {
    final target = _room.walkableArea.clamp(wanted, _room.collisions);
    final dx = target.x - _position.x;
    final dy = target.y - _position.y;
    final pose = dx.abs() > dy.abs()
        ? (dx < 0 ? _AvatarPose.left : _AvatarPose.right)
        : (dy < 0 ? _AvatarPose.back : _AvatarPose.front);
    _arrivalTimer?.cancel();
    _interactionTimer?.cancel();
    setState(() {
      _position = target;
      _pose = pose;
      _moving = true;
      _bubble = null;
      _activeObject = null;
    });
    _arrivalTimer = Timer(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      setState(() {
        _moving = false;
        _pose = interactionTarget == null
            ? _AvatarPose.front
            : _poseFor(interactionTarget.interaction);
        _activeObject = interactionTarget;
        _bubble = interactionTarget == null
            ? null
            : '${interactionTarget.name}${_interactionCopy(interactionTarget.interaction)}';
      });
      if (interactionTarget != null) {
        _interactionTimer = Timer(const Duration(milliseconds: 2200), () {
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

  _AvatarPose _poseFor(RoomInteraction interaction) => switch (interaction) {
    RoomInteraction.dry || RoomInteraction.wash => _AvatarPose.wipe,
    RoomInteraction.organize || RoomInteraction.pickUp => _AvatarPose.organize,
    RoomInteraction.look ||
    RoomInteraction.stop ||
    RoomInteraction.askHelp => _AvatarPose.wave,
    _ => _AvatarPose.use,
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
  };

  void _approachFixed(RoomObject object) =>
      _moveTo(object.approachPoint, interactionTarget: object);

  void _approachAcquired(SpacePlacement placement) {
    final item = GrowthRewardRepository.items
        .where((candidate) => candidate.id == placement.itemId)
        .firstOrNull;
    if (item == null || item.spaceId != _room.id) return;
    final object = RoomObject(
      id: placement.id,
      name: item.name,
      kind: RoomObjectKind.acquired,
      itemId: item.id,
      position: RoomPoint(placement.x * 100, placement.y * 100),
      approachPoint: _room.walkableArea.clamp(
        RoomPoint(placement.x * 100, placement.y * 100 + 12),
        _room.collisions,
      ),
      interaction: _interactionForItem(item.id),
    );
    _moveTo(object.approachPoint, interactionTarget: object);
  }

  RoomInteraction _interactionForItem(String itemId) {
    if (itemId.contains('soap') || itemId.contains('shampoo')) {
      return RoomInteraction.wash;
    }
    if (itemId.contains('toothbrush')) return RoomInteraction.brush;
    if (itemId.contains('towel') || itemId.contains('cloth')) {
      return RoomInteraction.dry;
    }
    if (itemId.contains('cup') || itemId.contains('bottle')) {
      return RoomInteraction.drink;
    }
    if (itemId.contains('dishes') || itemId.contains('cutlery')) {
      return RoomInteraction.eat;
    }
    if (itemId.contains('cone') ||
        itemId.contains('stop') ||
        itemId.contains('crosswalk')) {
      return RoomInteraction.stop;
    }
    if (itemId.contains('contact')) return RoomInteraction.askHelp;
    if (itemId.contains('bag') ||
        itemId.contains('umbrella') ||
        itemId.contains('wipes')) {
      return RoomInteraction.prepare;
    }
    if (itemId.contains('rack') || itemId.contains('hat')) {
      return RoomInteraction.dress;
    }
    return RoomInteraction.organize;
  }

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
        setState(() {
          _roomIndex = index;
          _position = const RoomPoint(50, 77);
          _pose = _AvatarPose.front;
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
        bubble: _bubble,
        placements: index == _roomIndex ? _placements : const [],
        motion: _motion,
        equipped: _equipped,
        onFloorTap: (point) => _moveTo(point),
        onFixedTap: _approachFixed,
        onItemTap: _approachAcquired,
        onAvatarTap: _reactToAvatar,
        onDecorate: () => Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (_) => SpacePage(
                  profileId: widget.profileId,
                  initialSpaceId: _room.id,
                ),
              ),
            )
            .then((_) => _loadRoom()),
      ),
    ),
    bottomNavigationBar: _AvatarNavigation(
      onActions: () => _go(ActionLibraryPage(profileId: widget.profileId)),
      onHome: () => _go(const HomePage()),
      onRecords: () => _go(GrowthRecordPage(profileId: widget.profileId)),
    ),
  );

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
    required this.bubble,
    required this.placements,
    required this.motion,
    required this.equipped,
    required this.onFloorTap,
    required this.onFixedTap,
    required this.onItemTap,
    required this.onAvatarTap,
    required this.onDecorate,
  });

  final AvatarRoom room;
  final bool active;
  final RoomPoint position;
  final _AvatarPose pose;
  final bool moving;
  final String? bubble;
  final List<SpacePlacement> placements;
  final Animation<double> motion;
  final Map<String, String> equipped;
  final ValueChanged<RoomPoint> onFloorTap;
  final ValueChanged<RoomObject> onFixedTap;
  final ValueChanged<SpacePlacement> onItemTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onDecorate;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      final foot = position.toScreen(size);
      final depthScale = .78 + (position.y / 100) * .25;
      final avatarHeight = 210 * depthScale;
      final avatarWidth = 126 * depthScale;
      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          Image.asset(room.backgroundAsset, fit: BoxFit.cover),
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
          for (final object in room.fixedObjects)
            _FixedObjectHotspot(
              object: object,
              size: size,
              onTap: () => onFixedTap(object),
            ),
          for (final placement in placements)
            _AcquiredObject(
              placement: placement,
              size: size,
              onTap: () => onItemTap(placement),
            ),
          if (active)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 900),
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
          if (active)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOutCubic,
              left: (foot.dx - avatarWidth / 2).clamp(
                2,
                size.width - avatarWidth - 2,
              ),
              top: (foot.dy - avatarHeight).clamp(
                4,
                size.height - avatarHeight - 12,
              ),
              child: SizedBox(
                width: avatarWidth,
                height: avatarHeight,
                child: _AvatarSprite(
                  pose: pose,
                  moving: moving,
                  bubble: bubble,
                  motion: motion,
                  equipped: equipped,
                  onTap: onAvatarTap,
                ),
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
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
    },
  );

  String _categoryLabel(String roomId) => switch (roomId) {
    'bathroom' => '위생 · 화장실',
    'bedroom' => '옷 입기',
    'kitchen' => '식사',
    'playroom' => '물건과 집안일',
    'entrance' => '외출 준비',
    'safety' => '안전과 도움 요청',
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
    final point = object.position.toScreen(size);
    final rect = object.collision;
    final width = (rect?.width ?? 16) * size.width / 100;
    final height = (rect?.height ?? 16) * size.height / 100;
    return Positioned(
      left: point.dx - width / 2,
      top: point.dy - height / 2,
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
  });
  final SpacePlacement placement;
  final Size size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    left: placement.x * size.width - 31,
    top: placement.y * size.height - 31,
    child: Semantics(
      button: true,
      label: '획득 아이템과 상호작용',
      child: GestureDetector(
        onTap: onTap,
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
    required this.motion,
    required this.equipped,
    required this.onTap,
  });
  final _AvatarPose pose;
  final bool moving;
  final String? bubble;
  final Animation<double> motion;
  final Map<String, String> equipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: motion,
    builder: (context, _) {
      final bounce = moving ? sin(motion.value * pi) * 3 : 0.0;
      return Transform.translate(
        offset: Offset(0, -bounce),
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(child: _MotionCell(pose: pose)),
              if (equipped['hat'] != null)
                const Positioned(
                  top: 5,
                  child: Text('🧢', style: TextStyle(fontSize: 28)),
                ),
              if (equipped['accessory'] != null)
                const Positioned(
                  right: 3,
                  bottom: 35,
                  child: Text('🎒', style: TextStyle(fontSize: 25)),
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
}

class _MotionCell extends StatelessWidget {
  const _MotionCell({required this.pose});
  final _AvatarPose pose;

  @override
  Widget build(BuildContext context) {
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
    return LayoutBuilder(
      builder: (context, box) => ClipRect(
        child: OverflowBox(
          alignment: Alignment(-1 + column * (2 / 3), -1 + row * 2),
          minWidth: box.maxWidth * 4,
          maxWidth: box.maxWidth * 4,
          minHeight: box.maxHeight * 2,
          maxHeight: box.maxHeight * 2,
          child: Image.asset(
            'assets/avatars/avatar_motion_atlas.png',
            width: box.maxWidth * 4,
            height: box.maxHeight * 2,
            fit: BoxFit.fill,
          ),
        ),
      ),
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
