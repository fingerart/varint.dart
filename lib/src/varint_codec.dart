import 'dart:convert';
import 'dart:typed_data';

/// 一个[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)的编码器和
/// 解码器
const varint = VarintCodec();

/// 使用[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)编码[bytes]
List<int> varintEncode(List<int> bytes) => varint.encode(bytes);

/// 使用[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)解码[bytes]
List<int> varintDecode(List<int> bytes) => varint.decode(bytes);

/// 计算单个[val]编码为[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)
/// 所需的字节数量
int varintEncodeSize(int val) => _encodeVarintSize(val);

class VarintCodec extends Codec<List<int>, List<int>> {
  const VarintCodec();

  @override
  Converter<List<int>, List<int>> get encoder => const VarintEncoder();

  @override
  Converter<List<int>, List<int>> get decoder => const VarintDecoder();
}

class VarintEncoder extends Converter<List<int>, List<int>> {
  const VarintEncoder();

  @override
  List<int> convert(List<int> input) {
    final buffer = BytesBuilder(copy: false);
    for (var val in input) {
      _varintEncodeOne(val, buffer);
    }
    return buffer.takeBytes();
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<List<int>> sink) {
    return _VarintEncodeSink(sink);
  }
}

class VarintDecoder extends Converter<List<int>, List<int>> {
  const VarintDecoder();

  @override
  List<int> convert(List<int> bytes) {
    return _varintDecode(bytes);
  }

  @override
  Sink<List<int>> startChunkedConversion(Sink<List<int>> sink) {
    return _VarintDecodeSink(sink);
  }
}

class _VarintEncodeSink extends ByteConversionSinkBase {
  _VarintEncodeSink(this._sink);

  final Sink<List<int>> _sink;

  final _buf = BytesBuilder(copy: false);

  @override
  void add(List<int> chunk) {
    for (var val in chunk) {
      _varintEncodeOne(val, _buf);
    }
    _sink.add(_buf.takeBytes());
  }

  @override
  void close() {
    _sink.close();
  }
}

class _VarintDecodeSink extends ByteConversionSink {
  const _VarintDecodeSink(this._sink);

  final Sink<List<int>> _sink;

  @override
  void add(List<int> bytes) {
    _sink.add(_varintDecode(bytes));
  }

  @override
  void close() {
    _sink.close();
  }
}

/// 对[val]编码为[varint](https://en.wikipedia.org/wiki/Variable-length_quantity)
/// 并将结果添加到[buffer]
@pragma('vm:prefer-inline')
void _varintEncodeOne(int val, BytesBuilder buffer) {
  assert(val >= 0, 'Negative numbers do not support variable int.');
  while (val >= 0x80) {
    buffer.addByte(0x80 | val & 0x7F);
    val >>= 7;
  }
  buffer.addByte(val);
}

/// 对[Uint8List]解码到[List<int>]
@pragma('vm:prefer-inline')
List<int> _varintDecode(List<int> bytes) {
  if (bytes.isEmpty) return const [];

  final decoded = <int>[];
  for (int b = 0, i = 0, val = 0; i < bytes.length;) {
    do {
      b = bytes[i++];
      val = (b & 0x7F);
      if (b < 0x80) {
        break;
      }
      b = bytes[i++];
      val |= (b & 0x7F) << 7;
      if (b < 0x80) {
        break;
      }
      b = bytes[i++];
      val |= (b & 0x7F) << 14;
      if (b < 0x80) {
        break;
      }
      b = bytes[i++];
      val |= (b & 0x7F) << 21;
      if (b < 0x80) {
        break;
      }
      b = bytes[i++];
      val |= (b & 0x7F) << 28;
      if (b < 0x80) {
        break;
      }
      b = bytes[i++];
      val |= (b & 0x7F) << 35;
      if (b < 0x80) {
        break;
      }
      b = bytes[i++];
      val |= (b & 0x7F) << 42;
      if (b < 0x80) {
        break;
      }
      b = bytes[i++];
      val |= (b & 0x7F) << 49;
      if (b < 0x80) {
        break;
      }
      b = bytes[i++];
      val |= (b & 0x7F) << 56;
      if (b < 0x80) {
        break;
      }
      b = bytes[i++];
      val |= (b & 0x01) << 63;
      if (b < 0x80) {
        break;
      }
    } while (false);
    decoded.add(val);
  }
  return decoded;
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
