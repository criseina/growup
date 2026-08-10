import 'package:flutter/material.dart';

import 'profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.activeProfile});
  final ChildProfile activeProfile;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _repository = ProfileRepository();
  List<ChildProfile> _profiles = [];
  String? _activeId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await _repository.loadProfiles();
    final active = await _repository.loadActiveProfile();
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _activeId = active.id;
      });
    }
  }

  Future<void> _select(ChildProfile profile) async {
    await _repository.setActiveProfile(profile.id);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _edit([ChildProfile? profile]) async {
    final nameController = TextEditingController(text: profile?.name ?? '');
    final yearController = TextEditingController(
      text: profile?.birthYear?.toString() ?? '',
    );
    final result = await showDialog<ChildProfile>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(profile == null ? '아이 프로필 추가' : '아이 프로필 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: '이름 또는 별명'),
            ),
            TextField(
              controller: yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '태어난 해 (선택)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(
                context,
                ChildProfile(
                  id:
                      profile?.id ??
                      'child-${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  birthYear: int.tryParse(yearController.text.trim()),
                ),
              );
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
    nameController.dispose();
    yearController.dispose();
    if (result == null) return;

    final index = _profiles.indexWhere((item) => item.id == result.id);
    final updated = [..._profiles];
    if (index == -1) {
      updated.add(result);
    } else {
      updated[index] = result;
    }
    await _repository.saveProfiles(updated);
    if (index == -1) await _repository.setActiveProfile(result.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('아이 프로필')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _edit,
      icon: const Icon(Icons.add),
      label: const Text('프로필 추가'),
    ),
    body: _profiles.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _profiles.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final profile = _profiles[index];
              final isActive = profile.id == _activeId;
              return Card(
                color: isActive ? const Color(0xffe5f5dc) : null,
                child: ListTile(
                  onTap: () => _select(profile),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xffffe9a9),
                    child: Text(profile.name.characters.first),
                  ),
                  title: Text(profile.name),
                  subtitle: Text(
                    profile.birthYear == null
                        ? '생년 정보 없음'
                        : '${profile.birthYear}년생',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isActive)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xff378b45),
                        ),
                      IconButton(
                        onPressed: () => _edit(profile),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: '프로필 수정',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
