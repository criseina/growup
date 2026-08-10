import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'growth_reward_pages.dart';
import 'growth_reward_repository.dart';

class AvatarWorldPage extends StatefulWidget {
  const AvatarWorldPage({super.key, required this.profileId});
  final String profileId;

  @override
  State<AvatarWorldPage> createState() => _AvatarWorldPageState();
}

class _AvatarWorldPageState extends State<AvatarWorldPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController = PageController();
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat(reverse: true);
  var _page = 0;
  var _smiling = false;
  Map<String, List<String>> _placed = {};

  static const _worlds = <({String id, String name, String asset})>[
    (
      id: 'bathroom',
      name: '욕실',
      asset: 'assets/avatar_backgrounds/bathroom.png',
    ),
    (
      id: 'playroom',
      name: '놀이방',
      asset: 'assets/avatar_backgrounds/playroom.png',
    ),
    (id: 'kitchen', name: '주방', asset: 'assets/avatar_backgrounds/kitchen.png'),
    (
      id: 'entrance',
      name: '현관',
      asset: 'assets/avatar_backgrounds/entrance.png',
    ),
    (id: 'bedroom', name: '침실', asset: 'assets/avatar_backgrounds/bedroom.png'),
    (
      id: 'safety',
      name: '안전 활동',
      asset: 'assets/avatar_backgrounds/safety.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPlacedItems();
  }

  Future<void> _loadPlacedItems() async {
    final placed = await GrowthRewardRepository().loadSpaces(widget.profileId);
    if (mounted) setState(() => _placed = placed);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _greet() async {
    setState(() => _smiling = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (mounted) setState(() => _smiling = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('나의 성장 공간'),
      actions: [
        IconButton(
          tooltip: '아바타 꾸미기',
          onPressed: () => Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => AvatarPage(profileId: widget.profileId),
                ),
              )
              .then((_) => _loadPlacedItems()),
          icon: const Icon(Icons.checkroom_outlined),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _worlds.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              final world = _worlds[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(world.asset, fit: BoxFit.cover),
                  _PlacedItemOverlay(itemIds: _placed[world.id] ?? const []),
                  Align(
                    alignment: const Alignment(0, .40),
                    child: AnimatedBuilder(
                      animation: _bounceController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(
                          0,
                          -8 * math.sin(_bounceController.value * math.pi),
                        ),
                        child: child,
                      ),
                      child: GestureDetector(
                        onTap: _greet,
                        child: Semantics(
                          button: true,
                          label: '아이 아바타',
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_smiling) _SpeechBubble(text: '헤헤! 반가워요 😊'),
                              AnimatedScale(
                                duration: const Duration(milliseconds: 180),
                                scale: _smiling ? 1.13 : 1,
                                child: Image.asset(
                                  'assets/avatars/starter_child.png',
                                  height: 290,
                                ),
                              ),
                              Text(
                                _smiling ? '웃고 있어요!' : '터치하고 인사해 보세요',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Text('좌우로 밀어 ${_worlds[_page].name} 공간을 바꿔 보세요'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _worlds.length,
                    (index) => Container(
                      width: index == _page ? 22 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index == _page
                            ? const Color(0xff28753c)
                            : const Color(0xffd8dfd4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) =>
                              SpacePage(profileId: widget.profileId),
                        ),
                      )
                      .then((_) => _loadPlacedItems()),
                  icon: const Icon(Icons.chair_alt_outlined),
                  label: const Text('공간 꾸미기'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(text),
  );
}

class _PlacedItemOverlay extends StatelessWidget {
  const _PlacedItemOverlay({required this.itemIds});
  final List<String> itemIds;

  @override
  Widget build(BuildContext context) {
    final items = GrowthRewardRepository.items
        .where((item) => itemIds.contains(item.id))
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Positioned(
      top: 20,
      right: 12,
      child: Wrap(
        spacing: 6,
        children: items
            .map(
              (item) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .82),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(item.icon, style: const TextStyle(fontSize: 26)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
