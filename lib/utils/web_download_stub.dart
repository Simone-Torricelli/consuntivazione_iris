bool downloadTextFile({
  required String fileName,
  required String content,
  String mimeType = 'text/plain;charset=utf-8',
}) {
  return false;
}

bool downloadBinaryFile({
  required String fileName,
  required List<int> bytes,
  String mimeType =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
}) {
  return false;
}
