import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'growth_reward_pages.dart';
import 'growth_reward_repository.dart';
import 'main.dart' show ActionLibraryPage, GrowthRecordPage, HomePage;

enum _AvatarAction {
  lookAround,
  walk,
  rest,
  wave,
  celebrate,
  washHands,
  brushTeeth,
  dryHands,
  play,
  drink,
  packBag,
  stargaze,
  safetyStop,
  touchJump,
}

class AvatarWorldPage extends StatefulWidget {
  const AvatarWorldPage({super.key, required this.profileId});
  final String profileId;

  @override
  State<AvatarWorldPage> createState() => _AvatarWorldPageState();
}

class _AvatarWorldPageState extends State<AvatarWorldPage>
    with TickerProviderStateMixin {
  final _repository = GrowthRewardRepository();
  final _random = Random();
  final _controller = PageController();
  final _recent = <_AvatarAction>[];
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  Timer? _timer;
  int _page = 0;
  _AvatarAction _action = _AvatarAction.lookAround;
  bool _isTouchReaction = false;
  double _x = .50;
  double _y = .68;
  List<SpacePlacement> _placements = [];
  Map<String, String> _equipped = {};

  static const _spaces = <({String id, String label, String asset})>[
    (id: 'bathroom', label: '\uC695\uC2E4', asset: 'assets/avatar_backgrounds/bathroom.png'),
    (id: 'playroom', label: '\uB180\uC774\uBC29', asset: 'assets/avatar_backgrounds/playroom.png'),
    (id: 'kitchen', label: '\uC8FC\uBC29', asset: 'assets/avatar_backgrounds/kitchen.png'),
    (id: 'entrance', label: '\uD604\uAD00', asset: 'assets/avatar_backgrounds/entrance.png'),
    (id: 'bedroom', label: '\uCE68\uC2E4', asset: 'assets/avatar_backgrounds/bedroom.png'),
    (id: 'safety', label: '\uC548\uC804 \uD65C\uB3D9', asset: 'assets/avatar_backgrounds/safety.png'),
  ];

  String get _spaceId => _spaces[_page].id;

  @override
  void initState() {
    super.initState();
    _load();
    _schedule();
  }

  Future<void> _load() async {
    final result = await Future.wait<Object>([
      _repository.loadPlacements(profileId: widget.profileId, spaceId: _spaceId),
      _repository.loadAvatar(widget.profileId),
    ]);
    if (!mounted) return;
    setState(() {
      _placements = result[0] as List<SpacePlacement>;
      _equipped = result[1] as Map<String, String>;
    });
  }

  void _schedule({bool quick = false}) {
    _timer?.cancel();
    final seconds = quick ? 1 + _random.nextInt(2) : 3 + _random.nextInt(5);
    _timer = Timer(Duration(seconds: seconds), _selectAction);
  }

  void _selectAction() {
    if (!mounted || _isTouchReaction) return;
    final candidates = <_AvatarAction>[
      _AvatarAction.lookAround,
      _AvatarAction.walk,
      _AvatarAction.rest,
      _AvatarAction.wave,
      _AvatarAction.celebrate,
      ..._itemActions(),
    ].where((action) => !_recent.contains(action)).toList();
    final next = candidates.isEmpty
        ? _AvatarAction.lookAround
        : candidates[_random.nextInt(candidates.length)];
    _recent.add(next);
    if (_recent.length > 2) _recent.removeAt(0);
    _moveFor(next);
    setState(() => _action = next);
    _schedule();
  }

  List<_AvatarAction> _itemActions() {
    final itemIds = _placements.map((item) => item.itemId).toSet();
    return [
      if (itemIds.contains('bathroom_soap_01')) _AvatarAction.washHands,
      if (itemIds.contains('bathroom_toothbrush_01')) _AvatarAction.brushTeeth,
      if (itemIds.contains('bathroom_towel_01')) _AvatarAction.dryHands,
      if (itemIds.contains('playroom_toybox_01')) _AvatarAction.play,
      if (itemIds.contains('kitchen_cup_01')) _AvatarAction.drink,
      if (itemIds.contains('entrance_bag_01')) _AvatarAction.packBag,
      if (itemIds.contains('bedroom_lamp_01') || itemIds.contains('bedroom_star_01')) _AvatarAction.stargaze,
      if (itemIds.contains('safety_car_01') || itemIds.contains('safety_cone_01')) _AvatarAction.safetyStop,
    ];
  }

  void _moveFor(_AvatarAction action) {
    final itemId = switch (action) {
      _AvatarAction.washHands => 'bathroom_soap_01',
      _AvatarAction.brushTeeth => 'bathroom_toothbrush_01',
      _AvatarAction.dryHands => 'bathroom_towel_01',
      _AvatarAction.play => 'playroom_toybox_01',
      _AvatarAction.drink => 'kitchen_cup_01',
      _AvatarAction.packBag => 'entrance_bag_01',
      _AvatarAction.stargaze => 'bedroom_star_01',
      _AvatarAction.safetyStop => 'safety_cone_01',
      _ => null,
    };
    final matches = itemId == null
        ? const <SpacePlacement>[]
        : _placements.where((item) => item.itemId == itemId).toList();
    final target = matches.isEmpty ? null : matches.first;
    setState(() {
      _x = target?.x ?? (action == _AvatarAction.walk ? .19 + _random.nextDouble() * .62 : .39 + _random.nextDouble() * .22);
      _y = target?.y ?? .68;
    });
  }

  void _reactToTouch() {
    _timer?.cancel();
    const reactions = [_AvatarAction.wave, _AvatarAction.celebrate, _AvatarAction.touchJump];
    setState(() {
      _isTouchReaction = true;
      _action = reactions[_random.nextInt(reactions.length)];
    });
    Timer(Duration(milliseconds: 1100 + _random.nextInt(700)), () {
      if (!mounted) return;
      setState(() => _isTouchReaction = false);
      _schedule(quick: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _motion.dispose();
    _controller.dispose();
    super.dispose();
  }

  String get _bubble => switch (_action) {
    _AvatarAction.lookAround => '\uBB34\uC5C7\uC744 \uD574\uBCFC\uAE4C?',
    _AvatarAction.walk => '\uCC9C\uCC9C\uD788 \uAC78\uC5B4\uBCFC\uB798!',
    _AvatarAction.rest => '\uC7A0\uC2DC \uC26C\uC5B4\uC694.',
    _AvatarAction.wave => '\uC548\uB155! \uC62C \uAC70\uC9C0?',
    _AvatarAction.celebrate => '\uC7AC\uBBF8\uC788\uB2E4!',
    _AvatarAction.washHands => '\uBE44\uB204\uB85C \uC190\uC744 \uC53B\uC5B4\uC694!',
    _AvatarAction.brushTeeth => '\uCE58\uCE74\uCE58\uCE74!',
    _AvatarAction.dryHands => '\uC190\uC744 \uB2E6\uC544\uC694.',
    _AvatarAction.play => '\uAC19\uC774 \uB180\uC544\uC694!',
    _AvatarAction.drink => '\uBB3C \uD55C \uBAA8\uAE08!',
    _AvatarAction.packBag => '\uAC00\uBC29\uC744 \uCC59\uAE30\uC790!',
    _AvatarAction.stargaze => '\uBCC4\uC774 \uBC18\uC9DD\uBC18\uC9DD!',
    _AvatarAction.safetyStop => '\uBA48\uCDB0\uC11C \uC0B4\uD3B4\uBD10\uC694.',
    _AvatarAction.touchJump => '\uBC18\uAC00\uC6CC\uC694!',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('${_spaces[_page].label}\uC5D0\uC11C \uB180\uC544\uC694'),
          actions: [
            IconButton(
              icon: const Icon(Icons.checkroom_outlined),
              tooltip: '\uC544\uBC14\uD0C0 \uAFB8\uBBF8\uAE30',
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => AvatarPage(profileId: widget.profileId)))
                  .then((_) => _load()),
            ),
            IconButton(
              icon: const Icon(Icons.dashboard_customize_outlined),
              tooltip: '\uACF5\uAC04 \uAFB8\uBBF8\uAE30',
              onPressed: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => SpacePage(profileId: widget.profileId)))
                  .then((_) => _load()),
            ),
          ],
        ),
        body: PageView.builder(
          controller: _controller,
          itemCount: _spaces.length,
          onPageChanged: (value) {
            setState(() {
              _page = value;
              _x = .50;
              _y = .68;
              _action = _AvatarAction.lookAround;
            });
            _load();
            _schedule();
          },
          itemBuilder: (context, index) => _WorldScene(
            space: _spaces[index],
            visible: index == _page,
            placements: index == _page ? _placements : const [],
            action: _action,
            x: _x,
            y: _y,
            motion: _motion,
            bubble: _bubble,
            touchReaction: _isTouchReaction,
            blueTop: _equipped['top'] == 'avatar_top_01',
            hasHat: _equipped['hat'] != null,
            hasBag: _equipped['accessory'] != null,
            onTap: _reactToTouch,
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

class _WorldScene extends StatelessWidget {
  const _WorldScene({required this.space, required this.visible, required this.placements, required this.action, required this.x, required this.y, required this.motion, required this.bubble, required this.touchReaction, required this.blueTop, required this.hasHat, required this.hasBag, required this.onTap});
  final ({String id, String label, String asset}) space;
  final bool visible;
  final List<SpacePlacement> placements;
  final _AvatarAction action;
  final double x;
  final double y;
  final Animation<double> motion;
  final String bubble;
  final bool touchReaction;
  final bool blueTop;
  final bool hasHat;
  final bool hasBag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          final height = box.maxHeight;
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              Image.asset(space.asset, fit: BoxFit.cover),
              for (final placement in placements)
                Positioned(
                  left: (placement.x * (width - 56)).clamp(4, width - 60).toDouble(),
                  top: (placement.y * (height - 56)).clamp(height * .18, height - 70).toDouble(),
                  child: _PlacedVisual(placement: placement),
                ),
              if (visible)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                  left: (x * width - 78).clamp(6, width - 156).toDouble(),
                  top: (y * height - 205).clamp(height * .20, height - 300).toDouble(),
                  child: _LivingAvatar(
                    action: action,
                    motion: motion,
                    bubble: bubble,
                    touchReaction: touchReaction,
                    blueTop: blueTop,
                    hasHat: hasHat,
                    hasBag: hasBag,
                    onTap: onTap,
                  ),
                ),
            ],
          );
        },
      );
}

class _LivingAvatar extends StatelessWidget {
  const _LivingAvatar({required this.action, required this.motion, required this.bubble, required this.touchReaction, required this.blueTop, required this.hasHat, required this.hasBag, required this.onTap});
  final _AvatarAction action;
  final Animation<double> motion;
  final String bubble;
  final bool touchReaction;
  final bool blueTop;
  final bool hasHat;
  final bool hasBag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: motion,
        builder: (context, _) {
          final beat = sin(motion.value * pi);
          final jump = action == _AvatarAction.touchJump ? -22 * beat : 0.0;
          final rotation = action == _AvatarAction.wave ? .08 * beat : action == _AvatarAction.lookAround ? .035 * beat : 0.0;
          final scale = touchReaction ? 1.10 + .05 * beat : action == _AvatarAction.celebrate ? 1.03 + .05 * beat : 1.0;
          return Transform.translate(
            offset: Offset(0, jump),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(
                scale: scale,
                child: GestureDetector(
                  onTap: onTap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(top: -48, child: _Bubble(text: bubble)),
                      Image.asset(blueTop ? 'assets/avatars/avatar_blue_top.png' : 'assets/avatars/starter_child.png', height: 235),
                      if (hasHat) const Positioned(top: 0, child: Text('\uD83E\uDDE2', style: TextStyle(fontSize: 35))),
                      if (hasBag || action == _AvatarAction.packBag) const Positioned(right: 5, bottom: 35, child: Text('\uD83C\uDF92', style: TextStyle(fontSize: 35))),
                      if (action == _AvatarAction.washHands) const Positioned(left: 4, top: 94, child: Text('\uD83E\uDDFC', style: TextStyle(fontSize: 30))),
                      if (action == _AvatarAction.brushTeeth) const Positioned(right: 12, top: 105, child: Text('\uD83E\uDEA5', style: TextStyle(fontSize: 26))),
                      if (action == _AvatarAction.dryHands) const Positioned(left: 2, top: 110, child: Text('\uD83E\uDDFB', style: TextStyle(fontSize: 26))),
                      if (action == _AvatarAction.play) const Positioned(right: 2, top: 115, child: Text('\uD83E\uDDF8', style: TextStyle(fontSize: 27))),
                      if (action == _AvatarAction.drink) const Positioned(right: 4, top: 116, child: Text('\uD83E\uDD64', style: TextStyle(fontSize: 27))),
                      if (action == _AvatarAction.stargaze) const Positioned(right: -2, top: 35, child: Text('\u2B50', style: TextStyle(fontSize: 27))),
                      if (action == _AvatarAction.safetyStop) const Positioned(left: -2, top: 115, child: Text('\uD83D\uDED1', style: TextStyle(fontSize: 27))),
                      if (action == _AvatarAction.wave) const Positioned(right: 0, top: 70, child: Text('\uD83D\uDC4B', style: TextStyle(fontSize: 30))),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class _PlacedVisual extends StatelessWidget {
  const _PlacedVisual({required this.placement});
  final SpacePlacement placement;
  @override
  Widget build(BuildContext context) {
    final matches = GrowthRewardRepository.items.where((item) => item.id == placement.itemId).toList();
    final item = matches.isEmpty ? null : matches.first;
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .86), borderRadius: BorderRadius.circular(12)),
      child: Padding(padding: const EdgeInsets.all(6), child: Text(item?.icon ?? '\uD83D\uDCE6', style: const TextStyle(fontSize: 26))),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(14)),
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      );
}

class _AvatarNavigation extends StatelessWidget {
  const _AvatarNavigation({required this.onActions, required this.onHome, required this.onRecords});
  final VoidCallback onActions;
  final VoidCallback onHome;
  final VoidCallback onRecords;
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(color: Color(0xfffffbf5), border: Border(top: BorderSide(color: Color(0xffe8e4dc)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Nav(icon: Icons.auto_awesome_outlined, label: '\uD589\uB3D9', onTap: onActions),
              _Nav(icon: Icons.home_rounded, label: '\uD648', onTap: onHome),
              const _Nav(icon: Icons.face_retouching_natural, label: '\uC544\uBC14\uD0C0', selected: true),
              _Nav(icon: Icons.menu_book_outlined, label: '\uAE30\uB85D', onTap: onRecords),
            ],
          ),
        ),
      );
}

class _Nav extends StatelessWidget {
  const _Nav({required this.icon, required this.label, this.selected = false, this.onTap});
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
          decoration: BoxDecoration(color: selected ? const Color(0xffe0f2dc) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: selected ? 30 : 23, color: selected ? const Color(0xff176a36) : const Color(0xff7b867d)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: selected ? const Color(0xff176a36) : const Color(0xff7b867d), fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
          ]),
        ),
      );
}
