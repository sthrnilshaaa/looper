import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../../features/library/domain/models/models.dart';
export '../../../features/library/domain/models/models.dart';
import '../../utils/logger_helper.dart';

class DbService {
  static late Isar isar;

  static Future<void> init() async {
    if (Isar.getInstance() != null) {
      isar = Isar.getInstance()!;
      LoggerHelper.write(
        'DbService: Isar database already open, reusing active instance.',
      );
      return;
    }
    try {
      LoggerHelper.write('DbService: Getting application support directory...');
      final dir = await getApplicationSupportDirectory();
      LoggerHelper.write('DbService: Directory path: ${dir.path}');

      LoggerHelper.write('DbService: Opening Isar database schemas...');
      isar = await Isar.open([
        SongSchema,
        AlbumSchema,
        ArtistSchema,
        PlaylistSchema,
        AppSettingsSchema,
        PlayEventSchema,
      ], directory: dir.path);
      LoggerHelper.write('DbService: Isar opened successfully.');
    } catch (e, stack) {
      LoggerHelper.write('DbService: Opening Isar failed!', e, stack);
      rethrow;
    }
  }
}
