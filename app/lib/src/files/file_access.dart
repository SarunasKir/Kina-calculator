import 'dart:convert';

import 'package:file_picker/file_picker.dart';

/// A file the user picked, read as text.
typedef PickedFile = ({String name, String content});

/// Saving and opening files through the system dialogs. Tests swap in a fake.
abstract interface class FileAccess {
  /// Asks where to save [content] as [fileName]. Returns where it went, or
  /// null if the user cancelled.
  Future<String?> saveText(String fileName, String content);

  /// Lets the user pick JSON files and reads them. Returns an empty list if
  /// the user cancelled.
  Future<List<PickedFile>> pickJsonFiles();
}

/// [FileAccess] through the Windows and Android file dialogs.
// coverage:ignore-start
class PlatformFileAccess implements FileAccess {
  /// Creates the file access.
  const PlatformFileAccess();

  @override
  Future<String?> saveText(String fileName, String content) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: utf8.encode(content),
      mimeType: 'text/csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (uri == null) {
      return null;
    }
    return uri.scheme == 'file' ? uri.toFilePath() : fileName;
  }

  @override
  Future<List<PickedFile>> pickJsonFiles() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    return [
      for (final f in files)
        (name: f.name, content: await f.xFile.readAsString()),
    ];
  }
}

// coverage:ignore-end
