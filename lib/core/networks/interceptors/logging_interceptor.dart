import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  static const _line = '════════════════════════════════════════════════════';

  // Print line-by-line so logcat never truncates a chunk.
  void _print(String msg) {
    for (final line in msg.split('\n')) {
      debugPrint(line);
    }
  }

  String _prettyBody(dynamic data) {
    if (data == null) return '(empty)';
    try {
      final encoded = const JsonEncoder.withIndent('  ').convert(data);
      return encoded;
    } catch (_) {
      return data.toString();
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final buf = StringBuffer();
    buf.writeln('╔$_line');
    buf.writeln('║ ➡  REQUEST');
    buf.writeln('║  Method  : ${options.method}');
    buf.writeln('║  URL     : ${options.uri}');
    if (options.queryParameters.isNotEmpty) {
      buf.writeln('║  Params  :');
      options.queryParameters.forEach(
        (k, v) => buf.writeln('║    $k: $v'),
      );
    }
    buf.writeln('║  Headers :');
    buf.writeln(
      options.headers.entries
          .map((e) => '║    ${e.key}: ${e.value}')
          .join('\n'),
    );
    buf.writeln('║  Body    :');
    if (options.data is FormData) {
      final fd = options.data as FormData;
      buf.writeln('║    [FormData]');
      for (final f in fd.fields) {
        buf.writeln('║    field  → ${f.key}: ${f.value}');
      }
      for (final f in fd.files) {
        buf.writeln('║    file   → ${f.key}: ${f.value.filename}');
      }
    } else {
      _prettyBody(options.data)
          .split('\n')
          .forEach((l) => buf.writeln('║    $l'));
    }
    buf.write('╚$_line');
    _print(buf.toString());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final buf = StringBuffer();
    buf.writeln('╔$_line');
    buf.writeln('║ ✅ RESPONSE');
    buf.writeln('║  Status  : ${response.statusCode} ${response.statusMessage}');
    buf.writeln('║  URL     : ${response.requestOptions.uri}');
    buf.writeln('║  Headers :');
    response.headers.map.forEach(
      (k, v) => buf.writeln('║    $k: ${v.join(', ')}'),
    );
    buf.writeln('║  Body    :');
    _prettyBody(response.data)
        .split('\n')
        .forEach((l) => buf.writeln('║    $l'));
    buf.write('╚$_line');
    _print(buf.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final buf = StringBuffer();
    buf.writeln('╔$_line');
    buf.writeln('║ ❌ ERROR');
    buf.writeln('║  Type    : ${err.type}');
    buf.writeln('║  Message : ${err.message}');
    buf.writeln('║  Method  : ${err.requestOptions.method}');
    buf.writeln('║  URL     : ${err.requestOptions.uri}');
    if (err.response != null) {
      buf.writeln('║  Status  : ${err.response!.statusCode} ${err.response!.statusMessage}');
      buf.writeln('║  Headers :');
      err.response!.headers.map.forEach(
        (k, v) => buf.writeln('║    $k: ${v.join(', ')}'),
      );
      buf.writeln('║  Body    :');
      _prettyBody(err.response!.data)
          .split('\n')
          .forEach((l) => buf.writeln('║    $l'));
    }
    buf.write('╚$_line');
    _print(buf.toString());
    handler.next(err);
  }
}
