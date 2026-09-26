part of 'scanner.dart';

/// True if [filePath] falls inside one of [excludedFolders] - the user's
/// per-folder scan exclusions (e.g. a voice-memos subfolder living inside an
/// otherwise-wanted Music folder), which is a separate, finer-grained knob
/// than the blanket "include system & messaging audio" setting.
bool isUnderExcludedFolder(String filePath, List<String> excludedFolders) {
  for (final folder in excludedFolders) {
    if (folder.isEmpty) continue;
    final normalized = folder.endsWith('/') ? folder : '$folder/';
    if (filePath == folder || filePath.startsWith(normalized)) return true;
  }
  return false;
}

@visibleForTesting
bool isIgnoredScanPath(
  String targetPath, {
  bool includeSystemAndMessagingAudio = false,
}) {
  final lower = targetPath.toLowerCase();
  final baseName = p.basename(lower);
  final segments = p
      .split(lower)
      .where((segment) => segment.isNotEmpty && segment != p.separator)
      .toList();

  if (baseName.startsWith('.') && baseName != '.') return true;
  if (lower.contains('/android/data/') ||
      lower.endsWith('/android/data') ||
      lower.contains('/android/obb/') ||
      lower.endsWith('/android/obb') ||
      segments.contains('.cache') ||
      baseName == '.nomedia') {
    return true;
  }

  if (includeSystemAndMessagingAudio) return false;

  // Ringtones, Notifications, Alarms
  if (segments.any(
        const {
          'ringtones',
          'ringtone',
          'notifications',
          'notification',
          'alarms',
          'alarm',
        }.contains,
      ) ||
      lower.contains('/system/media/audio')) {
    return true;
  }

  // WhatsApp & Messaging Voice Notes / Audio
  if (segments.any(
    (segment) =>
        segment == 'whatsapp' ||
        segment == 'whatsapp business' ||
        segment == 'whatsapp voice notes' ||
        segment == 'whatsapp audio' ||
        segment == 'telegram audio' ||
        segment == 'telegram voice',
  )) {
    return true;
  }

  // Common voice note filename prefixes (PTT, AUD)
  if (baseName.startsWith('ptt-') || baseName.startsWith('aud-')) {
    return true;
  }

  return false;
}

Future<List<String>> _isolatedDirectoryTraversal(
  Map<String, dynamic> params,
) async {
  final String rootPath = params['rootPath'] as String;
  final List<String> extensions = List<String>.from(
    params['extensions'] as List,
  );
  final int minSizeBytes = params['minSizeBytes'] as int;
  final bool includeSystemAndMessagingAudio =
      params['includeSystemAndMessagingAudio'] as bool? ?? false;

  final dir = Directory(rootPath);
  if (!dir.existsSync()) return [];

  final List<String> validFiles = [];

  void walk(Directory currentDir) {
    if (isIgnoredScanPath(
      currentDir.path,
      includeSystemAndMessagingAudio: includeSystemAndMessagingAudio,
    )) {
      return;
    }

    List<FileSystemEntity> entities = [];
    try {
      entities = currentDir.listSync(recursive: false, followLinks: false);
    } catch (_) {
      return;
    }

    for (final entity in entities) {
      if (isIgnoredScanPath(
        entity.path,
        includeSystemAndMessagingAudio: includeSystemAndMessagingAudio,
      )) {
        continue;
      }

      if (entity is File) {
        final ext = p.extension(entity.path).toLowerCase();
        if (extensions.contains(ext)) {
          try {
            if (entity.lengthSync() >= minSizeBytes) {
              validFiles.add(entity.path);
            }
          } catch (_) {}
        }
      } else if (entity is Directory) {
        walk(entity);
      }
    }
  }

  walk(dir);
  return validFiles;
}
