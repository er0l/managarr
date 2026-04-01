import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:xml/xml.dart';

import '../../../core/database/app_database.dart';
import 'models/torrent.dart';

class RTorrentApi {
  RTorrentApi._(this._dio, this._endpoint);

  final Dio _dio;
  final String _endpoint;

  factory RTorrentApi.fromInstance(Instance instance) {
    String host = instance.baseUrl
        .replaceAll(RegExp(r'[\u0000-\u001f\x7f-\x9f]'), '')
        .trim();

    String? basicAuth;
    if (host.contains('@')) {
      try {
        final uri = Uri.parse(host);
        if (uri.userInfo.isNotEmpty) {
          basicAuth = 'Basic ${base64.encode(utf8.encode(uri.userInfo))}';
          host = uri.replace(userInfo: '').toString();
        }
      } catch (_) {}
    }

    while (host.endsWith('/')) {
      host = host.substring(0, host.length - 1);
    }
    final endpoint = '$host/RPC2';

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x86) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Content-Type': 'text/xml',
          'Authorization': basicAuth ??
              (instance.apiKey.isNotEmpty
                  ? 'Basic ${base64.encode(utf8.encode(instance.apiKey))}'
                  : null),
        },
        responseType: ResponseType.plain,
      ),
    );

    return RTorrentApi._(dio, endpoint);
  }

  // ── XML-RPC helpers ──────────────────────────────────────────────────────

  Future<String> _call(String method, [List<dynamic> params = const []]) async {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0"');
    builder.element('methodCall', nest: () {
      builder.element('methodName', nest: method);
      if (params.isNotEmpty) {
        builder.element('params', nest: () {
          for (final p in params) {
            builder.element('param', nest: () {
              builder.element('value', nest: () => _writeValue(builder, p));
            });
          }
        });
      }
    });

    final xml = builder.buildDocument().toXmlString();
    final res = await _dio.post(_endpoint, data: xml);

    final doc = XmlDocument.parse(res.data as String);
    final fault = doc.findAllElements('fault').firstOrNull;
    if (fault != null) {
      final members = fault.findAllElements('member').toList();
      String msg = 'rTorrent fault';
      for (final m in members) {
        if (m.getElement('name')?.innerText == 'faultString') {
          msg = m.getElement('value')?.innerText ?? msg;
          break;
        }
      }
      throw Exception(msg);
    }
    return res.data as String;
  }

  void _writeValue(XmlBuilder b, dynamic v) {
    if (v is String) {
      b.element('string', nest: v);
    } else if (v is int) {
      b.element('i4', nest: v.toString());
    } else if (v is bool) {
      b.element('boolean', nest: v ? '1' : '0');
    } else if (v is Uint8List) {
      b.element('base64', nest: base64.encode(v));
    } else if (v is List) {
      b.element('array', nest: () {
        b.element('data', nest: () {
          for (final item in v) {
            b.element('value', nest: () => _writeValue(b, item));
          }
        });
      });
    } else if (v is Map<String, dynamic>) {
      b.element('struct', nest: () {
        v.forEach((key, val) {
          b.element('member', nest: () {
            b.element('name', nest: key);
            b.element('value', nest: () => _writeValue(b, val));
          });
        });
      });
    }
  }

  String _parseValue(XmlElement el) {
    for (final t in ['string', 'i4', 'int', 'boolean', 'double']) {
      final node = el.getElement(t);
      if (node != null) return node.innerText;
    }
    return el.innerText;
  }

  // ── Public API ───────────────────────────────────────────────────────────

  Future<void> testConnection() => _call('system.listMethods');

  Future<List<RTorrentTorrent>> getTorrents() async {
    final data = await _call('d.multicall2', [
      '',
      'main',
      'd.hash=',
      'd.name=',
      'd.size_bytes=',
      'd.completed_bytes=',
      'd.down.rate=',
      'd.up.rate=',
      'd.is_active=',
      'd.state=',
      'd.message=',
      'd.creation_date=',
      'd.timestamp.finished=',
      'd.ratio=',
      'd.custom1=',
    ]);

    final doc = XmlDocument.parse(data);
    final rows = doc
        .findAllElements('value')
        .where((e) => e.parentElement?.name.local == 'data');

    final torrents = <RTorrentTorrent>[];
    for (final row in rows) {
      final vals = row.findAllElements('value').toList();
      if (vals.length >= 13) {
        torrents.add(RTorrentTorrent(
          hash: _parseValue(vals[0]),
          name: _parseValue(vals[1]),
          size: int.tryParse(_parseValue(vals[2])) ?? 0,
          completed: int.tryParse(_parseValue(vals[3])) ?? 0,
          downRate: int.tryParse(_parseValue(vals[4])) ?? 0,
          upRate: int.tryParse(_parseValue(vals[5])) ?? 0,
          isActive: _parseValue(vals[6]) == '1',
          state: int.tryParse(_parseValue(vals[7])) ?? 0,
          message: _parseValue(vals[8]),
          dateAdded: int.tryParse(_parseValue(vals[9])) ?? 0,
          dateDone: int.tryParse(_parseValue(vals[10])) ?? 0,
          ratio: (int.tryParse(_parseValue(vals[11])) ?? 0) / 1000.0,
          label: _parseValue(vals[12]),
        ));
      }
    }
    return torrents;
  }

  Future<List<RTorrentTracker>> getTrackers(String hash) async {
    final data = await _call('t.multicall', [hash, '', 't.url=', 't.type=']);
    final doc = XmlDocument.parse(data);
    final rows = doc
        .findAllElements('value')
        .where((e) => e.parentElement?.name.local == 'data');

    final trackers = <RTorrentTracker>[];
    for (final row in rows) {
      final vals = row.findAllElements('value').toList();
      if (vals.length >= 2) {
        trackers.add(RTorrentTracker(
          url: _parseValue(vals[0]),
          type: int.tryParse(_parseValue(vals[1])) ?? 0,
        ));
      }
    }
    return trackers;
  }

  Future<List<RTorrentFile>> getFiles(String hash) async {
    final data = await _call('f.multicall', [
      hash,
      '',
      'f.path=',
      'f.size_bytes=',
      'f.completed_chunks=',
      'f.size_chunks=',
    ]);
    final doc = XmlDocument.parse(data);
    final rows = doc
        .findAllElements('value')
        .where((e) => e.parentElement?.name.local == 'data');

    final files = <RTorrentFile>[];
    for (final row in rows) {
      final vals = row.findAllElements('value').toList();
      if (vals.length >= 4) {
        files.add(RTorrentFile(
          path: _parseValue(vals[0]),
          size: int.tryParse(_parseValue(vals[1])) ?? 0,
          completedChunks: int.tryParse(_parseValue(vals[2])) ?? 0,
          sizeChunks: int.tryParse(_parseValue(vals[3])) ?? 0,
        ));
      }
    }
    return files;
  }

  Future<bool> stop(String hash) async {
    await _call('d.stop', [hash]);
    await _call('d.close', [hash]);
    return true;
  }

  Future<bool> pause(String hash) async {
    await _call('d.stop', [hash]);
    return true;
  }

  Future<bool> resume(String hash) async {
    await _call('d.start', [hash]);
    return true;
  }

  Future<bool> remove(String hash, {bool deleteData = false}) async {
    final h = hash.trim().toUpperCase();
    try {
      await _call('d.stop', [h]);
      await _call('d.close', [h]);
    } catch (_) {}

    if (deleteData) {
      try {
        String? path;
        try {
          final res = await _call('d.base_path', [h]);
          path = _parseValue(XmlDocument.parse(res).rootElement).trim();
        } catch (_) {}

        if (path == null || path.isEmpty) {
          try {
            final res = await _call('d.directory', [h]);
            path = _parseValue(XmlDocument.parse(res).rootElement).trim();
          } catch (_) {}
        }

        if (path != null && path.isNotEmpty && path != '/') {
          // Attempt physical deletion via execute2
          for (final method in ['execute2', 'execute', 'execute.throw.bg']) {
            try {
              await _call(method, ['', 'rm', '-rf', path]);
              break;
            } catch (_) {}
          }
        }
      } catch (_) {}

      try {
        await _call('d.delete_tied', [h]);
      } catch (_) {}
      try {
        await _call('d.custom.set', [h, 'custom5', '1']);
        await _call('d.custom.set', [h, 'delete_data', '1']);
      } catch (_) {}
    }

    await _call('d.erase', [h]);
    return true;
  }

  Future<bool> addByUrl(String url) async {
    await _call('load.start', ['', url]);
    return true;
  }

  Future<bool> addByFile(Uint8List bytes) async {
    await _call('load.raw_start', ['', bytes]);
    return true;
  }

  Future<bool> setLabel(String hash, String label) async {
    await _call('d.custom1.set', [hash, label]);
    return true;
  }

  Future<bool> checkHash(String hash) async {
    await _call('d.check_hash', [hash]);
    return true;
  }
}
