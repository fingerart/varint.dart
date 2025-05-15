import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:varint/src/varint_codec.dart';
import 'package:varint/varint.dart';

void main() {
  final random = Random();
  final example = List.generate(10000, (_) => random.nextInt(5000));
  final exampleSigned = List.generate(
    10000,
    (_) => random.nextInt(5000) * (random.nextBool() ? 1 : -1),
  );
  test('test varint codec', () {
    _testVarint(0, [0]);
    _testVarint(1, [1]);
    _testVarint(127, [127]);
    _testVarint(128, [0x80, 0x01]);
    _testVarint(300, [0xac, 0x02]);
    _testVarint(16383, [0xff, 0x7f]);
    _testVarint(16384, [0x80, 0x80, 0x01]);
  });

  test('test varint codec random', () async {
    var encoded = varintEncode(example);
    var decoded = varintDecode(encoded);
    expect(example, decoded);

    var encodedSigned = varintSignedEncode(exampleSigned);
    var decodedSigned = varintSignedDecode(encodedSigned);
    expect(exampleSigned, decodedSigned);
  });

  test('test varint codec random by stream', () async {
    var encoded = await Stream.value(example).transform(varint.encoder).fold(
      <int>[],
      (dat, el) => dat..addAll(el),
    );
    var decoded = await Stream.value(encoded).transform(varint.decoder).fold(
      <int>[],
      (dat, el) => dat..addAll(el),
    );
    expect(example, decoded);
  });

  test('test zigzag codec', () {
    expect(0, zigZagEncode(0));
    expect(1, zigZagEncode(-1));
    expect(2, zigZagEncode(1));
    expect(3, zigZagEncode(-2));
    expect(4, zigZagEncode(2));

    expect(0, zigZagDecode(0));
    expect(-1, zigZagDecode(1));
    expect(1, zigZagDecode(2));
    expect(-2, zigZagDecode(3));
    expect(2, zigZagDecode(4));
  });
}

void _testVarint(int i, List<int> bytes) {
  var vb = i < 0 ? varintSigned : varint;
  var input = [i];
  var encoded = vb.encode(input);
  expect(encoded, bytes);

  var decoded = vb.decode(encoded);
  expect(decoded, input);
}
