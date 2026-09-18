import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/services/secure_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('credentials introduced by a redirect cannot leak on the next hop',
      () async {
    var calls = 0;
    final client = SecureHttpClient(MockClient((_) async {
      calls++;
      return http.Response('', 302, headers: {
        'location': calls == 1
            ? 'https://cdn.example/image?token=private'
            : 'https://external.example'
      });
    }));
    await expectLater(client.get(Uri.parse('https://store.example/image')),
        throwsA(isA<http.ClientException>()));
    expect(calls, 2);
    client.close();
  });
  test('stream errors do not expose upstream secrets', () async {
    final client = SecureHttpClient(_FailingResponseClient());
    try {
      await client.get(Uri.parse('https://store.example?token=private'));
      fail('Expected stream error');
    } catch (error) {
      expect(error.toString(), isNot(contains('UPSTREAM_PRIVATE_BODY')));
    }
    client.close();
  });
  test('non-HTTPS endpoints never reach the network', () async {
    var calls = 0;
    final client = SecureHttpClient(MockClient((_) async {
      calls++;
      return http.Response('ok', 200);
    }));
    for (final value in [
      'http://store.example',
      'file:///secret',
      'https://user@store.example'
    ]) {
      await expectLater(
          client.get(Uri.parse(value)), throwsA(isA<http.ClientException>()));
    }
    expect(calls, 0);
    client.close();
  });
  test('HTTPS redirect to HTTP is blocked before a second request', () async {
    var calls = 0;
    final client = SecureHttpClient(MockClient((request) async {
      calls++;
      expect(request.followRedirects, false);
      return http.Response('', 302,
          headers: {'location': 'http://store.example/next'});
    }));
    await expectLater(client.get(Uri.parse('https://store.example')),
        throwsA(isA<http.ClientException>()));
    expect(calls, 1);
    client.close();
  });
  test('same-origin HTTPS redirect keeps authenticated headers', () async {
    var calls = 0;
    final client = SecureHttpClient(MockClient((request) async {
      calls++;
      expect(request.headers['Authorization'], 'Bearer private');
      return calls == 1
          ? http.Response('', 302, headers: {'location': '/next'})
          : http.Response('ok', 200);
    }));
    final response = await client.get(Uri.parse('https://store.example'),
        headers: {'Authorization': 'Bearer private'});
    expect(response.body, 'ok');
    expect(calls, 2);
    client.close();
  });
  test('credentialed cross-origin redirects never forward credentials',
      () async {
    var calls = 0;
    final client = SecureHttpClient(MockClient((_) async {
      calls++;
      return http.Response('', 302,
          headers: {'location': 'https://external.example'});
    }));
    await expectLater(
        client.get(Uri.parse('https://store.example?consumer_secret=private')),
        throwsA(isA<http.ClientException>()));
    expect(calls, 1);
    client.close();
  });
  test('public HTTPS CDN redirect drops original custom headers', () async {
    var calls = 0;
    final client = SecureHttpClient(MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response('', 302,
            headers: {'location': 'https://cdn.example/image'});
      }
      expect(request.headers['Accept-Language'], null);
      return http.Response('ok', 200);
    }));
    expect(
        (await client.get(Uri.parse('https://store.example/image'),
                headers: {'Accept-Language': 'ar'}))
            .body,
        'ok');
    client.close();
  });
  test('write redirects are not automatically replayed', () async {
    var calls = 0;
    final client = SecureHttpClient(MockClient((_) async {
      calls++;
      return http.Response('', 307, headers: {'location': '/next'});
    }));
    await expectLater(
        client.post(Uri.parse('https://store.example/order'), body: 'payload'),
        throwsA(isA<http.ClientException>()));
    expect(calls, 1);
    client.close();
  });
  test('connection errors do not expose URI secrets', () async {
    final client = SecureHttpClient(MockClient((request) async {
      throw http.ClientException('sensitive upstream body', request.url);
    }));
    try {
      await client
          .get(Uri.parse('https://store.example?consumer_secret=private'));
      fail('Expected failure');
    } catch (error) {
      expect(error.toString(), isNot(contains('private')));
      expect(error.toString(), isNot(contains('sensitive upstream')));
    }
    client.close();
  });
  test('redirect loops stop at the configured limit', () async {
    var calls = 0;
    final client = SecureHttpClient(MockClient((_) async {
      calls++;
      return http.Response('', 302, headers: {'location': '/next'});
    }));
    final request = http.Request('GET', Uri.parse('https://store.example'))
      ..maxRedirects = 1;
    await expectLater(
        client.send(request), throwsA(isA<http.ClientException>()));
    expect(calls, 2);
    client.close();
  });
}

class _FailingResponseClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
          Stream<List<int>>.error(
              http.ClientException('UPSTREAM_PRIVATE_BODY', request.url)),
          200);
}
