import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:looper_player/core/services/storage/local_json_store.dart';
import 'package:looper_player/features/playback/domain/crossmix_models.dart';

class CrossmixSettingsNotifier extends Notifier<CrossmixSettings> {
  static const _key = 'crossmix_settings_v1';

  /// Synchronous fallback for components without Ref.
  static CrossmixSettings current = const CrossmixSettings();

  @override
  CrossmixSettings build() {
    _load();
    return current;
  }

  Future<void> _load() async {
    final raw = await LocalJsonStore.read(_key);
    if (raw is Map) {
      state = current = CrossmixSettings.fromJson(
        Map<String, dynamic>.from(raw),
      );
    }
  }

  Future<void> update(
    CrossmixSettings Function(CrossmixSettings) transform,
  ) async {
    state = current = transform(state);
    await LocalJsonStore.write(_key, state.toJson());
  }

  Future<void> setCrossfadeEnabled(bool enabled) =>
      update((s) => s.copyWith(crossfadeEnabled: enabled));

  Future<void> setDurationSeconds(double seconds) =>
      update((s) => s.copyWith(durationSeconds: seconds));

  Future<void> setSmartTransitions(bool enabled) =>
      update((s) => s.copyWith(smartTransitions: enabled));

  Future<void> setBeatMixing(bool enabled) =>
      update((s) => s.copyWith(beatMixing: enabled));
}

final crossmixSettingsProvider =
    NotifierProvider<CrossmixSettingsNotifier, CrossmixSettings>(
      CrossmixSettingsNotifier.new,
    );
