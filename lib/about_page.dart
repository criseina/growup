import 'package:flutter/material.dart';

import 'backup_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('GrowUp 안내')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'GrowUp 프로토타입',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('버전 1.0.0'),
        SizedBox(height: 28),
        _AboutSection(
          title: '이 앱은 무엇을 하나요?',
          body:
              '아이의 일상 행동을 혼자 했어요, 같이 했어요, 아직 해보지 않았어요로 가볍게 기록하고 성장 과정을 돌아볼 수 있어요.',
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const BackupPage())),
          icon: const Icon(Icons.cloud_done_outlined),
          label: const Text('데이터 백업 및 가져오기'),
        ),
        const SizedBox(height: 28),
        _AboutSection(
          title: '기록은 어디에 저장되나요?',
          body:
              '현재 프로토타입의 프로필, 행동 상태, 관찰 기록과 메모는 이 기기 안에만 저장됩니다. 계정 생성이나 서버 전송 기능은 사용하지 않습니다.',
        ),
        _AboutSection(
          title: '사용할 때 기억해 주세요',
          body:
              '이 앱은 아이를 평가하거나 비교하는 도구가 아니에요. 아이의 발달 속도와 안전을 먼저 살피고, 필요한 경우 전문가와 상담해 주세요.',
        ),
      ],
    ),
  );
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff28753c),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(body),
      ],
    ),
  );
}
