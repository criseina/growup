import 'package:flutter/material.dart';

import 'backup_repository.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  final _backup = BackupRepository();
  var _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      await _backup.shareExport();
      if (mounted) _message('백업 파일을 만들었습니다. Google Drive 등 원하는 곳에 저장하세요.');
    } catch (_) {
      if (mounted) _message('백업 파일을 만들지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final source = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 불러오기'),
        content: TextField(
          controller: controller,
          minLines: 6,
          maxLines: 10,
          decoration: const InputDecoration(
            labelText: '백업 JSON 붙여넣기',
            hintText: '내보낸 백업 파일 내용을 복사해 붙여 넣으세요.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('불러오기'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (source == null || source.trim().isEmpty || !mounted) return;
    setState(() => _busy = true);
    try {
      await _backup.importFromJson(source);
      if (mounted) _message('백업을 불러왔어요. 홈으로 돌아가면 반영됩니다.');
    } on FormatException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('백업 파일을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('데이터 백업')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(
          Icons.cloud_done_outlined,
          size: 56,
          color: Color(0xff28753c),
        ),
        const SizedBox(height: 16),
        Text(
          '내 기록은 내가 보관해요',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          '백업 파일에는 아이 프로필, 행동 기록, 메모, 아바타와 공간 꾸미기 정보가 들어갑니다. 내보내기 후 Google Drive·파일·메일에 저장할 수 있어요.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _busy ? null : _export,
          icon: const Icon(Icons.ios_share),
          label: const Text('백업 파일 내보내기'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _import,
          icon: const Icon(Icons.file_open_outlined),
          label: const Text('복사한 백업 가져오기'),
        ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 28),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'GrowUp은 아이의 기록을 별도 서버에 자동 전송하지 않습니다. 클라우드 저장은 보호자가 공유 창에서 직접 선택합니다.',
            ),
          ),
        ),
      ],
    ),
  );
}
