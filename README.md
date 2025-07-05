[![pub package](https://img.shields.io/pub/v/varint.dart.svg)](https://pub.dartlang.org/packages/varint.dart)
[![GitHub stars](https://img.shields.io/github/stars/fingerart/varint.dart)](https://github.com/fingerart/varint.dart/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/fingerart/varint.dart)](https://github.com/fingerart/varint.dart/network)
[![GitHub license](https://img.shields.io/github/license/fingerart/varint.dart)](https://github.com/fingerart/varint.dart/blob/main/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/fingerart/varint.dart)](https://github.com/fingerart/varint.dart/issues)

<br/>

A Dart library for encoding and decoding [variable-length quantity](https://en.wikipedia.org/wiki/Variable-length_quantity) (VLQ).


> [!TIP]
> If this package is useful to you, please remember to give it a star✨ ([Pub](https://pub.dev/packages/varint) | [GitHub](https://github.com/fingerart/varint.dart)).

## Usage

If you need signed integer support, please use `varintSignedEncode`, `varintSignedDecode`, and `varintSigned`.

```dart
import 'package:varint/varint.dart';

var example = [10, 65535, 3277, 9999];
// Encode
var encoded = varintEncode(example);
// Decode
var decoded = varintDecode(encoded);
```

Handle as a stream:

```dart
// Encode
var encoded = await Stream.value(example).transform(varint.encoder).fold(
  <int>[],
  (dat, el) => dat..addAll(el),
);
// Decode
var decoded = await Stream.value(encoded).transform(varint.decoder).fold(
  <int>[],
  (dat, el) => dat..addAll(el),
);
```
