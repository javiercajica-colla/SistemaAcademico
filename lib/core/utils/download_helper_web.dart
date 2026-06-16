import 'dart:html' as html;
import 'dart:typed_data';

void downloadBytes(List<int> bytes, String filename) {
  final blob = html.Blob([Uint8List.fromList(bytes)]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  (html.document.createElement('a') as html.AnchorElement)
    ..href = url
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}
