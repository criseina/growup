import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_repository.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  final _nameController = TextEditingController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final repository = ProfileRepository();
    final profiles = await repository.loadProfiles();
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final index = profiles.indexWhere(
        (profile) => profile.id == ProfileRepository.defaultProfileId,
      );
      if (index != -1) {
        profiles[index] = profiles[index].copyWith(name: name);
        await repository.saveProfiles(profiles);
      }
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_completed_v1', true);
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _finish, child: const Text('건너뛰기')),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  const _OnboardingPanel(
                    icon: Icons.spa_outlined,
                    title: '작은 시도를 함께 기록해요',
                    body: 'GrowUp은 아이가 행동을 스스로 해보는 과정을 살펴보는 앱이에요.',
                  ),
                  const _OnboardingPanel(
                    icon: Icons.favorite_outline,
                    title: '잘했는지 평가하지 않아요',
                    body: '혼자 했어요, 같이 했어요, 아직 해보지 않았어요. 세 가지로 가볍게 남겨요.',
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.face_outlined,
                        size: 76,
                        color: Color(0xff378b45),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '아이를 어떻게 부를까요?',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      const Text('이름 대신 편한 별명을 써도 괜찮아요.'),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: '예: 하늘이',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _page
                        ? const Color(0xff378b45)
                        : const Color(0xffd9e6d3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _page == 2
                  ? _finish
                  : () => _controller.nextPage(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                    ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(_page == 2 ? 'GrowUp 시작하기' : '다음'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 82, color: const Color(0xff378b45)),
        const SizedBox(height: 28),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 14),
        Text(body, textAlign: TextAlign.center),
      ],
    ),
  );
}
