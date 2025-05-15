import 'dart:convert';
import 'dart:typed_data';

/// 一个[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)的编码器和
/// 解码器
const varint = VarintCodec();

/// 一个支持有符号[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)
/// 的编码器和解码器
const varintSigned = VarintCodec.signed();

/// 使用无符号[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)编码[bytes]
List<int> varintEncode(List<int> bytes) => varint.encode(bytes);

/// 使用支持有符号[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)编码[bytes]
List<int> varintSignedEncode(List<int> bytes) => varintSigned.encode(bytes);

/// 使用无符号[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)解码[bytes]
List<int> varintDecode(List<int> bytes) => varint.decode(bytes);

/// 使用支持有符号[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)解码[bytes]
List<int> varintSignedDecode(List<int> bytes) => varintSigned.decode(bytes);

/// [varint](https://en.wikipedia.org/wiki/Variable-length_quantity)编解码器
class VarintCodec extends Codec<List<int>, List<int>> {
  const VarintCodec() : _signed = false;

  const VarintCodec.signed() : _signed = true;

  /// 是否支持有符号
  final bool _signed;

  @override
  Converter<List<int>, List<int>> get encoder {
    return _signed ? const VarintEncoder(signed: true) : const VarintEncoder();
  }

  @override
  Converter<List<int>, List<int>> get decoder {
    return _signed ? const VarintDecoder(signed: true) : const VarintDecoder();
  }
}

/// [varint](https://en.wikipedia.org/wiki/Variable-length_quantity)编码器
class VarintEncoder extends Converter<List<int>, List<int>> {
  const VarintEncoder({this.signed = false});

  /// 是否支持有符号
  final bool signed;

  @override
  List<int> convert(List<int> input) {
    final buffer = BytesBuilder(copy: false);
    for (var val in input) {
      _varintEncodeOne(val, buffer, signed: signed);
    }
    return buffer.takeBytes();
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<List<int>> sink) {
    return _VarintEncodeSink(sink, signed);
  }
}

/// [varint](https://en.wikipedia.org/wiki/Variable-length_quantity)解码器
class VarintDecoder extends Converter<List<int>, List<int>> {
  const VarintDecoder({this.signed = false});

  /// 是否支持有符号
  final bool signed;

  @override
  List<int> convert(List<int> bytes) {
    return _varintDecode(bytes, signed: signed);
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<List<int>> sink) {
    return _VarintDecodeSink(sink, signed);
  }
}

class _VarintEncodeSink extends ByteConversionSinkBase {
  _VarintEncodeSink(this._sink, this.signed);

  final Sink<List<int>> _sink;

  final bool signed;

  final _buf = BytesBuilder(copy: false);

  @override
  void add(List<int> chunk) {
    for (var val in chunk) {
      _varintEncodeOne(val, _buf, signed: signed);
    }
    _sink.add(_buf.takeBytes());
  }

  @override
  void close() {
    _sink.close();
  }
}

class _VarintDecodeSink extends ByteConversionSink {
  const _VarintDecodeSink(this._sink, this.signed);

  final Sink<List<int>> _sink;

  final bool signed;

  @override
  void add(List<int> bytes) {
    _sink.add(_varintDecode(bytes, signed: signed));
  }

  @override
  void close() {
    _sink.close();
  }
}

/// 对[value]编码为[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)
/// 并将结果添加到[buffer]
@pragma('vm:prefer-inline')
void _varintEncodeOne(int value, BytesBuilder buffer, {bool signed = false}) {
  assert(value >= 0 || signed, 'Negative numbers do not support variable int.');

  if (signed) value = zigZagEncode(value);

  while (value >= 0x80) {
    buffer.addByte(0x80 | (value & 0x7F));
    value >>= 7;
  }
  buffer.addByte(value);
}

/// 对[Uint8List]解码到[List<int>]
@pragma('vm:prefer-inline')
List<int> _varintDecode(List<int> bytes, {bool signed = false}) {
  final result = <int>[];
  int value = 0;
  int shift = 0;

  for (int i = 0; i < bytes.length; i++) {
    final byte = bytes[i];
    value |= (byte & 0x7F) << shift;

    if ((byte & 0x80) == 0) {
      if (signed) value = zigZagDecode(value);
      result.add(value);
      value = 0;
      shift = 0;
    } else {
      shift += 7;
    }
  }

  return result;
}

/// 编码[val]为[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)所
/// 需的大小（Byte）
@pragma('vm:prefer-inline')
int _encodeVarintSize(int val) {
  int s = 1;
  while (val >= 0x80) {
    ++s;
    val >>= 7;
  }
  return s;
}

/// ZigZag encoding that maps signed integers with a small absolute value
/// to unsigned integers with a small (positive) values. Without this,
/// encoding negative values using Varint would use up 9 or 10 bytes.
///
/// if x >= 0, encodeZigZag(x) == 2*x
/// if x <  0, encodeZigZag(x) == -2*x - 1
@pragma('vm:prefer-inline')
int zigZagEncode(int n) {
  return (n << 1) ^ (n >> 63);
}

@pragma('vm:prefer-inline')
int zigZagDecode(int n) {
  return (n >> 1) ^ -(n & 1);
}
