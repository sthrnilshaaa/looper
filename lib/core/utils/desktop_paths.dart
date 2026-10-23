import 'dart:io';

import 'package:path/path.dart' as p;

/// The user's Music folder on Windows, from the process environment.
String windowsMusicFolder(Map<String, String> env) {
  final profile = env['USERPROFILE'];
  if (profile != null && profile.isNotEmpty) return '$profile\\Music';
  return '${env['HOMEDRIVE'] ?? 'C:'}${env['HOMEPATH'] ?? ''}\\Music';
}

/// The last part of [path] for display. Windows paths use `\` and drive
/// letters; everywhere else this keeps the original `split('/')` behaviour.
String displayFileName(String path, {bool? windows}) {
  if (!(windows ?? Platform.isWindows)) return path.split('/').last;
  final name = p.windows.basename(path);
  return name.isEmpty || name == p.windows.rootPrefix(path) ? path : name;
}

/// The user's Music folder on Linux or Windows. On Linux this asks
/// `xdg-user-dir`, so a renamed or translated folder is still found.
Future<String> desktopMusicFolder() async {
  if (Platform.isWindows) return windowsMusicFolder(Platform.environment);
  var path = '${Platform.environment['HOME']}/Music';
  try {
    final result = await Process.run('xdg-user-dir', ['MUSIC']);
    final out = result.stdout.toString().trim();
    if (result.exitCode == 0 && out.isNotEmpty) path = out;
  } catch (_) {}
  return path;
}
