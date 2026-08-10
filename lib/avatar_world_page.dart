import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'growth_reward_pages.dart';

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

  static const _worlds = <({String name, String asset})>[
    (name: '욕실', asset: 'assets/avatar_backgrounds/bathroom.png'),
    (name: '놀이방', asset: 'assets/avatar_backgrounds/playroom.png'),
    (name: '주방', asset: 'assets/avatar_backgrounds/kitchen.png'),
    (name: '현관', asset: 'assets/avatar_backgrounds/entrance.png'),
  ];

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
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AvatarPage(profileId: widget.profileId),
            ),
          ),
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
            itemBuilder: (context, index) => Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(_worlds[index].asset, fit: BoxFit.cover),
                Align(
                  alignment: const Alignment(0, 0.38),
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
                            if (_smiling)
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Text('헤헤! 반가워요 😊'),
                              ),
                            AnimatedScale(
                              duration: const Duration(milliseconds: 180),
                              scale: _smiling ? 1.13 : 1,
                              child: Image.asset(
                                'assets/avatars/starter_child.png',
                                height: 290,
                                fit: BoxFit.contain,
                              ),
                            ),
                            Text(
                              _smiling ? '웃고 있어요!' : '톡 하고 인사해 보세요',
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
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Text('← 밀어서 ${_worlds[_page].name} 공간을 바꿔요 →'),
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpacePage(profileId: widget.profileId),
                    ),
                  ),
                  icon: const Icon(Icons.weekend_outlined),
                  label: const Text('내 공간 꾸미기'),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
