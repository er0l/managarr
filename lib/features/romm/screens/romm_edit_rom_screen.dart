import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/romm_rom.dart';
import '../providers/romm_providers.dart';

class RommEditRomScreen extends ConsumerStatefulWidget {
  const RommEditRomScreen(
      {super.key, required this.rom, required this.instance});

  final RommRom rom;
  final Instance instance;

  @override
  ConsumerState<RommEditRomScreen> createState() => _RommEditRomScreenState();
}

class _RommEditRomScreenState extends ConsumerState<RommEditRomScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _summaryCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.rom.name);
    _summaryCtrl = TextEditingController(text: widget.rom.summary ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _summaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(rommApiProvider(widget.instance));
      await api.updateRom(widget.rom.id, {
        'name': _nameCtrl.text.trim(),
        'summary': _summaryCtrl.text.trim(),
      });
      ref.invalidate(rommRomDetailProvider(
          (instance: widget.instance, romId: widget.rom.id)));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.statusOffline,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text('Edit ROM',
            style: TextStyle(color: AppColors.textOnPrimary)),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.textOnPrimary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _summaryCtrl,
            decoration: const InputDecoration(
              labelText: 'Summary',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            minLines: 3,
          ),
        ],
      ),
    );
  }
}
