import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fstore/services/wordpress/blognews_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _TrackedClient extends MockClient {
  _TrackedClient(super.handler);
  int closes = 0;
  @override
  void close() {
    closes++;
    super.close();
  }
}

class _StreamingClient extends http.BaseClient {
  final controller = StreamController<List<int>>();
  int closes = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    expect(request.url.path, '/wp-json/wp/v2/posts');
    return http.StreamedResponse(controller.stream, 200);
  }

  @override
  void close() => closes++;
}

void main() {
  test('GET uses requested endpoint and closes after UTF-8 decode', () async {
    final client = _TrackedClient((request) async {
      expect(request.url.path, '/wp-json/wp/v2/posts');
      expect(request.url.queryParameters['page'], '2');
      return http.Response.bytes(utf8.encode('[{"title":"ذهب"}]'), 200);
    });
    final api =
        BlogNewsApi('https://store.example/', createTransport: () => client);
    expect(await api.getAsync('posts?page=2'), [
      {'title': 'ذهب'}
    ]);
    expect(client.closes, 1);
  });

  test('HTTP never reaches transport and still closes', () async {
    var calls = 0;
    final client = _TrackedClient((_) async {
      calls++;
      return http.Response('[]', 200);
    });
    final api =
        BlogNewsApi('http://store.example', createTransport: () => client);
    await expectLater(
        api.getAsync('posts'), throwsA(isA<http.ClientException>()));
    expect(calls, 0);
    expect(client.closes, 1);
  });

  test('service rejection does not expose upstream body', () async {
    final client =
        _TrackedClient((_) async => http.Response('PRIVATE_BODY', 403));
    final api =
        BlogNewsApi('https://store.example', createTransport: () => client);
    try {
      await api.getAsync('posts');
      fail('Expected service rejection');
    } catch (error) {
      expect(error, isA<http.ClientException>());
      expect(error.toString(), isNot(contains('PRIVATE_BODY')));
    }
    expect(client.closes, 1);
  });

  test('POST preserves JSON and authentication without replay', () async {
    final client = _TrackedClient((request) async {
      expect(request.method, 'POST');
      expect(request.headers['authorization'], 'Bearer example');
      expect(jsonDecode(request.body), {'title': 'ذهب'});
      return http.Response('{"id":7}', 201);
    });
    final api =
        BlogNewsApi('https://store.example', createTransport: () => client);
    expect(await api.postAsync('posts', {'title': 'ذهب'}, token: 'example'),
        {'id': 7});
    expect(client.closes, 1);
  });

  test('PUT closes even when response JSON is malformed', () async {
    final client = _TrackedClient((request) async {
      expect(request.method, 'PUT');
      expect(jsonDecode(request.body), {'title': 'updated'});
      return http.Response('not json', 200);
    });
    final api =
        BlogNewsApi('https://store.example', createTransport: () => client);
    await expectLater(api.putAsync('posts/7', {'title': 'updated'}),
        throwsA(isA<FormatException>()));
    expect(client.closes, 1);
  });

  test('stream consumption releases client and uses endpoint', () async {
    final client = _TrackedClient((request) async {
      expect(request.url.path, '/wp-json/wp/v2/posts');
      return http.Response('[]', 200);
    });
    final api =
        BlogNewsApi('https://store.example', createTransport: () => client);
    final response = await api.getStream('posts');
    expect(client.closes, 0);
    expect(await response.stream.bytesToString(), '[]');
    expect(client.closes, 1);
  });

  test('stream cancellation releases client before upstream completion',
      () async {
    final client = _StreamingClient();
    final api =
        BlogNewsApi('https://store.example', createTransport: () => client);
    final response = await api.getStream('posts');
    final consume = response.stream.take(1).drain<void>();
    client.controller.add([1]);
    await consume;
    expect(client.closes, 1);
    await client.controller.close();
  });

  test('upload supplies multipart boundary and closes client', () async {
    final temp = await Directory.systemTemp.createTemp('kanz-blog-test-');
    try {
      final file = File('${temp.path}/image.bin');
      await file.writeAsBytes([1, 2, 3]);
      final client = _TrackedClient((request) async {
        expect(request.url.path, '/wp-json/wp/v2/media');
        expect(request.headers['content-type'],
            contains('multipart/form-data; boundary='));
        expect(request.headers['authorization'], 'Bearer example');
        expect(request.body, contains('filename="image.bin"'));
        return http.Response('{"id":9}', 201);
      });
      final api =
          BlogNewsApi('https://store.example', createTransport: () => client);
      expect(await api.uploadBlogImage(file, 'example'), {'id': 9});
      expect(client.closes, 1);
    } finally {
      await temp.delete(recursive: true);
    }
  });
}
