import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/modules/dynamic_layout/config/app_config.dart';
import 'package:fstore/services/home_config_validation.dart';
import 'package:fstore/services/remote_home_config.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _PendingClient extends http.BaseClient {
  int closes = 0;
  final pending = Completer<http.StreamedResponse>();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      pending.future;
  @override
  void close() => closes++;
}

void main() {
  final valid = {
    'Setting': {'MainColor': '#B18729'},
    'TabBar': [
      {'layout': 'home', 'icon': 'home'}
    ],
    'HorizonLayout': [
      {'layout': 'bannerImage'}
    ],
  };
  for (final path in [
    'lib/config/config_ar.json',
    'lib/config/config_en.json',
    'lib/config/vi_store/config_ar.json',
    'lib/config/vi_store/config_en.json',
    'lib/config/us_store/config_en.json',
    'lib/config/us_store/config_vi.json',
  ]) {
    test('bundled home configuration satisfies contract: $path', () {
      final json = jsonDecode(File(path).readAsStringSync());
      validateHomeConfig(json);
      final config = AppConfig.fromJson(json);
      expect(config.tabBar, isNotEmpty);
      expect(config.settings.productListLayout, isNotEmpty);
    });
  }
  final invalid = [
    null,
    [],
    {},
    {
      'Setting': [],
      'TabBar': [
        {'layout': 'home'}
      ]
    },
    {...valid, 'TabBar': []},
    {
      ...valid,
      'TabBar': [
        {'layout': null}
      ]
    },
    {
      ...valid,
      'HorizonLayout': ['bad']
    },
    {...valid, 'HorizonLayout': null},
    {
      ...valid,
      'HorizonLayout': [{}]
    },
    {...valid, 'Drawer': 'bad'},
  ];
  for (var i = 0; i < invalid.length; i++) {
    test('invalid contract $i fails before late settings can be accessed', () {
      expect(() => AppConfig.fromJson(invalid[i]),
          throwsA(isA<FormatException>()));
    });
  }
  test('remote 200 valid configuration is decoded and parsed', () async {
    expect(AppConfig.fromJson(valid).settings.mainColor, '#B18729');
    final config =
        await loadRemoteHomeConfig('https://store.example/config.json',
            transport: MockClient((request) async {
      expect(request.headers['accept'], 'application/json');
      return http.Response(jsonEncode(valid), 200);
    }));
    expect(config.settings.mainColor, '#B18729');
  });
  for (final response in [
    http.Response(jsonEncode(valid), 403),
    http.Response('{"message":"PRIVATE_SERVER_DATA"}', 200),
    http.Response('PRIVATE_SERVER_DATA', 200),
    http.Response('PRIVATE_SERVER_DATA', 500),
  ]) {
    test(
        'remote rejection is generic: ${response.statusCode}/${response.body.length}',
        () async {
      try {
        await loadRemoteHomeConfig(
            'https://store.example/config?token=PRIVATE_TOKEN',
            transport: MockClient((_) async => response));
        fail('Expected rejection');
      } catch (error) {
        expect(error, isA<FormatException>());
        expect(error.toString(), isNot(contains('PRIVATE')));
        expect(error.toString(), isNot(contains('store.example')));
      }
    });
  }
  test('remote HTTP cannot reach transport', () async {
    var calls = 0;
    await expectLater(
        loadRemoteHomeConfig('http://store.example/config',
            transport: MockClient((_) async {
          calls++;
          return http.Response(jsonEncode(valid), 200);
        })),
        throwsA(isA<FormatException>()));
    expect(calls, 0);
  });
  test(
      'configuration timeout releases owned client without waiting for response',
      () async {
    final client = _PendingClient();
    await expectLater(
        loadRemoteHomeConfig('https://store.example/config',
            transport: client, timeout: const Duration(milliseconds: 1)),
        throwsA(isA<FormatException>()));
    expect(client.closes, 1);
    client.pending.complete(http.StreamedResponse(const Stream.empty(), 200));
  });
}
