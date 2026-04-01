import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/spacing.dart';
import '../repositories/instance_repository.dart';

// ---------------------------------------------------------------------------
// Connection test state
// ---------------------------------------------------------------------------

enum _TestStatus { idle, testing, success, failure }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AddEditInstanceScreen extends ConsumerStatefulWidget {
  const AddEditInstanceScreen({super.key, this.existingInstance});

  /// When non-null the screen operates in edit mode.
  final Instance? existingInstance;

  @override
  ConsumerState<AddEditInstanceScreen> createState() =>
      _AddEditInstanceScreenState();
}

class _AddEditInstanceScreenState
    extends ConsumerState<AddEditInstanceScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _portCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;

  ServiceType _serviceType = ServiceType.radarr;
  String _protocol = 'http';
  bool _enabled = true;

  bool get _useUserPass =>
      _serviceType == ServiceType.rtorrent || _serviceType == ServiceType.nzbget;

  _TestStatus _testStatus = _TestStatus.idle;
  String? _testMessage;

  bool get _isEdit => widget.existingInstance != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existingInstance;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _enabled = e?.enabled ?? true;

    if (e != null) {
      _serviceType = ServiceType.values.byName(e.serviceType);
      final uri = Uri.tryParse(e.baseUrl);
      _protocol = uri?.scheme ?? 'http';
      _hostCtrl = TextEditingController(text: uri?.host ?? '');
      _portCtrl = TextEditingController(
        text: uri?.hasPort == true ? uri!.port.toString() : '',
      );
      // rTorrent stores credentials as "username:password" in apiKey column
      final storedKey = e.apiKey;
      if (_useUserPass) {
        final colonIdx = storedKey.indexOf(':');
        if (colonIdx >= 0) {
          _usernameCtrl =
              TextEditingController(text: storedKey.substring(0, colonIdx));
          _passwordCtrl =
              TextEditingController(text: storedKey.substring(colonIdx + 1));
        } else {
          _usernameCtrl = TextEditingController();
          _passwordCtrl = TextEditingController(text: storedKey);
        }
        _apiKeyCtrl = TextEditingController();
      } else {
        _apiKeyCtrl = TextEditingController(text: storedKey);
        _usernameCtrl = TextEditingController();
        _passwordCtrl = TextEditingController();
      }
    } else {
      _hostCtrl = TextEditingController();
      _portCtrl = TextEditingController();
      _apiKeyCtrl = TextEditingController();
      _usernameCtrl = TextEditingController();
      _passwordCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _apiKeyCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get _baseUrl {
    final hostRaw = _hostCtrl.text.trim();
    final port = _portCtrl.text.trim();

    // If there's a path in the host field, split it to insert the port
    String host = hostRaw;
    String path = '';
    if (hostRaw.contains('/')) {
      final index = hostRaw.indexOf('/');
      host = hostRaw.substring(0, index);
      path = hostRaw.substring(index);
    }

    final portSuffix = port.isNotEmpty ? ':$port' : '';
    String result = '$_protocol://$host$portSuffix$path';
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  Future<void> _testConnection() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _testStatus = _TestStatus.testing;
      _testMessage = null;
    });

    try {
      if (_serviceType == ServiceType.rtorrent) {
        // rTorrent: XML-RPC POST with Basic Auth
        final username = _usernameCtrl.text.trim();
        final password = _passwordCtrl.text;
        final credential = '$username:$password';
        final encoded = base64.encode(utf8.encode(credential));
        final dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'text/xml',
              if (credential != ':') 'Authorization': 'Basic $encoded',
            },
            responseType: ResponseType.plain,
          ),
        );
        const body =
            '<?xml version="1.0"?><methodCall><methodName>system.listMethods</methodName></methodCall>';
        await dio.post('$_baseUrl/RPC2', data: body);
      } else if (_serviceType == ServiceType.nzbget) {
        // NZBGet: JSON-RPC POST with optional Basic Auth in URL or headers
        // LunaSea uses user:pass in URL, but we can use headers for cleaner approach
        // if user/pass are provided.
        final username = _usernameCtrl.text.trim();
        final password = _passwordCtrl.text;
        final credential = '$username:$password';
        final encoded = base64.encode(utf8.encode(credential));
        final dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              if (credential != ':') 'Authorization': 'Basic $encoded',
            },
          ),
        );
        final body = {
          "jsonrpc": "2.0",
          "method": "version",
          "params": [],
          "id": 1,
        };
        await dio.post('/jsonrpc', data: body);
      } else {
        final dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
        if (_serviceType.usesSabnzbdAuth) {
          await dio.get(
            _serviceType.healthPath,
            queryParameters: {
              'mode': 'version',
              'output': 'json',
              'apikey': _apiKeyCtrl.text.trim(),
            },
          );
        } else if (_serviceType == ServiceType.tautulli) {
          final res = await dio.get(
            _serviceType.healthPath,
            queryParameters: {
              'apikey': _apiKeyCtrl.text.trim(),
              'cmd': 'status',
            },
          );
          final data = res.data as Map<String, dynamic>;
          if (data['response']?['result'] != 'success') {
            throw Exception(
                data['response']?['message'] ?? 'Connection test failed');
          }
        } else {
          await dio.get(
            _serviceType.healthPath,
            options: Options(headers: {'X-Api-Key': _apiKeyCtrl.text.trim()}),
          );
        }
      }

      if (mounted) {
        setState(() {
          _testStatus = _TestStatus.success;
          _testMessage = 'Connected successfully';
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _testStatus = _TestStatus.failure;
          _testMessage = e.response != null
              ? 'HTTP ${e.response!.statusCode}: ${e.response!.statusMessage}'
              : e.message ?? 'Connection failed';
        });
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final repo = ref.read(instanceRepositoryProvider);
    final storedApiKey = _useUserPass
        ? '${_usernameCtrl.text.trim()}:${_passwordCtrl.text}'
        : _apiKeyCtrl.text.trim();

    final companion = InstancesCompanion(
      id: _isEdit ? Value(widget.existingInstance!.id) : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      serviceType: Value(_serviceType.name),
      baseUrl: Value(_baseUrl),
      apiKey: Value(storedApiKey),
      enabled: Value(_enabled),
    );

    if (_isEdit) {
      await repo.update(companion);
    } else {
      await repo.insert(companion);
    }

    if (mounted) context.pop();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text(
          'managarr',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              _isEdit ? 'Save' : 'Add Instance',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.pageHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Spacing.s8),
                _ServiceTypePicker(
                  selected: _serviceType,
                  onChanged: (t) => setState(() {
                    _serviceType = t;
                    _testStatus = _TestStatus.idle;
                    _testMessage = null;
                    // Clear credential fields when switching type
                    _apiKeyCtrl.clear();
                    _usernameCtrl.clear();
                    _passwordCtrl.clear();
                  }),
                ),
                const SizedBox(height: Spacing.s24),
                _FormField(
                  controller: _nameCtrl,
                  label: 'Instance Name',
                  hint: 'My Radarr',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: Spacing.s16),
                if (_useUserPass) ...[
                  _FormField(
                    controller: _usernameCtrl,
                    label: 'Username',
                    hint: 'admin',
                    mono: true,
                  ),
                  const SizedBox(height: Spacing.s16),
                  _FormField(
                    controller: _passwordCtrl,
                    label: 'Password',
                    hint: '••••••••',
                    mono: true,
                    obscureText: true,
                  ),
                ] else
                  _FormField(
                    controller: _apiKeyCtrl,
                    label: 'API Key',
                    hint: 'Paste your API key',
                    mono: true,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                const SizedBox(height: Spacing.s16),
                _ProtocolSelector(
                  value: _protocol,
                  onChanged: (p) => setState(() => _protocol = p),
                ),
                const SizedBox(height: Spacing.s16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _FormField(
                        controller: _hostCtrl,
                        label: 'Server Address',
                        hint: '192.168.1.100',
                        mono: true,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: Spacing.s12),
                    Expanded(
                      flex: 1,
                      child: _FormField(
                        controller: _portCtrl,
                        label: 'Port',
                        hint: '7878',
                        mono: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final n = int.tryParse(v);
                          if (n == null || n < 1 || n > 65535) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.s16),
                SwitchListTile(
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                  title: const Text('Enabled'),
                  subtitle: const Text('Include in dashboard and sync'),
                  activeThumbColor: AppColors.tealPrimary,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: Spacing.s8),
                if (_testMessage != null)
                  _TestResultBanner(
                    success: _testStatus == _TestStatus.success,
                    message: _testMessage!,
                  ),
                const SizedBox(height: Spacing.s16),
                _TestConnectionButton(
                  status: _testStatus,
                  onPressed: _testConnection,
                ),
                const SizedBox(height: Spacing.s24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _ServiceTypePicker extends StatelessWidget {
  const _ServiceTypePicker({
    required this.selected,
    required this.onChanged,
  });

  final ServiceType selected;
  final ValueChanged<ServiceType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service', style: theme.textTheme.titleMedium),
        const SizedBox(height: Spacing.s8),
        DropdownButtonFormField<ServiceType>(
          initialValue: selected,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          items: ServiceType.values
              .map(
                (t) => DropdownMenuItem(
                  value: t,
                  child: Text(t.displayName),
                ),
              )
              .toList(),
          onChanged: (t) {
            if (t != null) onChanged(t);
          },
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.mono = false,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool mono;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      style: mono
          ? GoogleFonts.jetBrainsMono(fontSize: 14)
          : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.tealPrimary, width: 2),
        ),
      ),
    );
  }
}

class _ProtocolSelector extends StatelessWidget {
  const _ProtocolSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'http', label: Text('http')),
        ButtonSegment(value: 'https', label: Text('https')),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: AppColors.tealPrimary,
        selectedForegroundColor: AppColors.textOnPrimary,
      ),
    );
  }
}

class _TestConnectionButton extends StatelessWidget {
  const _TestConnectionButton({
    required this.status,
    required this.onPressed,
  });

  final _TestStatus status;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isTesting = status == _TestStatus.testing;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: isTesting ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orangeAccent,
          disabledBackgroundColor: AppColors.orangeAccent.withAlpha(120),
          foregroundColor: AppColors.textOnPrimary,
          shape: const StadiumBorder(),
        ),
        icon: isTesting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnPrimary,
                ),
              )
            : const Icon(Icons.wifi_outlined),
        label: Text(
          isTesting ? 'Testing…' : 'Test Connection',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _TestResultBanner extends StatelessWidget {
  const _TestResultBanner({required this.success, required this.message});

  final bool success;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.validationOk : AppColors.validationError;
    final icon = success ? Icons.check_circle_outline : Icons.error_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(80)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
