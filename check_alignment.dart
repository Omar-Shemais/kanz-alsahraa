import 'dart:io';
import 'dart:typed_data';

void main() async {
  final apkPath = 'build/app/outputs/flutter-apk/app-release.apk';
  final file = File(apkPath);

  if (!await file.exists()) {
    print('Error: $apkPath not found.');
    return;
  }

  final bytes = await file.readAsBytes();
  final buffer = bytes.buffer.asUint8List();

  print('${"Data Offset".padRight(15)} ${"Path"}');
  print("-" * 60);

  // Simple ZIP parser to find local headers
  // Local header signature: 0x04034b50
  for (int i = 0; i < buffer.length - 30; i++) {
    if (buffer[i] == 0x50 && buffer[i+1] == 0x4b && buffer[i+2] == 0x03 && buffer[i+3] == 0x04) {
      final data = buffer.sublist(i + 26, i + 30);
      final nameLen = ByteData.sublistView(data, 0, 2).getUint16(0, Endian.little);
      final extraLen = ByteData.sublistView(data, 2, 4).getUint16(0, Endian.little);
      
      if (i + 30 + nameLen <= buffer.length) {
        final name = String.fromCharCodes(buffer.sublist(i + 30, i + 30 + nameLen));
        
        if (name.endsWith('.so')) {
          final dataOffset = i + 30 + nameLen + extraLen;
          final alignment = dataOffset % 16384;
          final status = alignment == 0 ? "✅ ALIGNED" : "❌ NOT ALIGNED";
          print('${dataOffset.toString().padRight(15)} $name (mod 16384 = $alignment) $status');
        }
      }
    }
  }
}
