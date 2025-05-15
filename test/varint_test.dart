import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:varint/src/varint_codec.dart';
import 'package:varint/varint.dart';

void main() {
  final random = Random();
  final example = List.generate(10000, (index) => random.nextInt(5000));

  test('test varint codec', () {
    _testVarint(0, [0]);
    _testVarint(1, [1]);
    _testVarint(127, [127]);
    _testVarint(128, [0x80, 0x01]);
    _testVarint(300, [0xac, 0x02]);
    _testVarint(16383, [0xff, 0x7f]);
    _testVarint(16384, [0x80, 0x80, 0x01]);
    _testVarint(730081594, [0xBA, 0xD2, 0x90, 0xDC, 0x02]);
  });

  test('test varint codec random', () async {
    var encoded = varintEncode(example);
    var decoded = varintDecode(encoded);
    expect(example, decoded);
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
}

void _testVarint(int i, List<int> bytes) {
  var input = [i];
  var encoded = varintEncode(input);
  expect(encoded, bytes);

  var decoded = varintDecode(encoded);
  expect(decoded, input);
}
