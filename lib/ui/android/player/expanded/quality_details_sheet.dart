import 'package:looper_player/core/motion/looper_scroll_physics.dart';
import 'dart:async';
import 'package:looper_player/core/motion/pause_when_offscreen.dart';
import 'dart:io';
import 'dart:math' as math;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/core/theme/app_fonts.dart';
import 'package:looper_player/core/utils/l10n.dart';
import 'package:looper_player/features/library/domain/models/models.dart';
import 'package:looper_player/features/playback/data/audio_analyzer.dart';
import 'package:looper_player/features/playback/data/device_audio_info.dart';
import 'package:looper_player/features/playback/presentation/providers/equalizer/equalizer_notifier.dart';
import 'package:looper_player/features/settings/domain/quality_badge_style.dart';
import 'package:looper_player/features/settings/presentation/providers/settings_notifier.dart';
import 'package:looper_player/l10n/app_localizations.dart';
import 'package:looper_player/ui/widgets/common/player_scale.dart';
import 'package:looper_player/ui/widgets/player/quality_badge.dart';

part 'quality_details_widgets.dart';

/// Hero tag shared by the Now Playing quality badge and this dialog's card,
/// so the pill morphs into the dialog and back.
const String qualityBadgeHeroTag = 'quality_badge_hero';

/// Opened by tapping the Now Playing quality badge: the file, what the
/// engine decodes and outputs (live), the output device and the phone.
///
/// A see-through page route rather than a bottom sheet: Hero flights only
/// run between PageRoutes, and the badge's hero should grow into the card.
///
/// What the card shows is resolved before the push: data landing during
/// the flight changed the card's size under the hero, so it snapped to a
/// new size (and position) when the flight ended. Each wait is capped so
/// a slow channel or first-time analysis never holds the tap up long.
Future<void> showQualityDetailsSheet(BuildContext context, Song song) async {
  if (_opening) return;
  _opening = true;
  try {
    final String path = song.path;
    final (device, _, fileSize) = await (
      _capped(DeviceAudioInfo.fetch()),
      _capped(AudioAnalyzer.analyze(path)),
      path.startsWith('content://')
          ? Future<int?>.value()
          : _capped(File(path).length()),
    ).wait;
    if (!context.mounted) return;
    await pushQualityHeroDialog(
      context,
      (_) => _QualityDetailsSheet(
        song: song,
        device: device ?? DeviceAudioInfo.cached,
        deviceFresh: device != null,
        fileSize: fileSize,
      ),
    );
  } finally {
    _opening = false;
  }
}

/// Guards against a double tap pushing two dialogs while the data loads.
bool _opening = false;

const Duration _prefetchCap = Duration(milliseconds: 250);

// Re-typed to Future<T?> first: timing out a non-nullable future (like
// File.length()'s Future<int>) with a null result throws a TypeError.
Future<T?> _capped<T>(Future<T> future) => future
    .then<T?>((value) => value, onError: (Object _) => null)
    .timeout(_prefetchCap, onTimeout: () => null);

/// Pushes [builder]'s page (a [QualityDialogFrame]) over a dimmed barrier.
Future<void> pushQualityHeroDialog(
  BuildContext context,
  WidgetBuilder builder,
) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 480),
      reverseTransitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      // The card itself arrives by its hero flight; nothing else to animate.
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          child,
    ),
  );
}

/// Same surface rules as [AppBottomSheetContainer]: frosted blur when
/// "Always blur sheets" (or Dynamic Theming's blur) is on, otherwise the
/// solid sheet color.
({bool blur, Color color}) _surface(AppSettings s) {
  final bool blur =
      s.alwaysBlurSheets || (!s.disableBlur && s.enableDynamicTheming);
  return (
    blur: blur,
    color: blur
        ? Color.alphaBlend(
            const Color.fromARGB(50, 0, 0, 0),
            Colors.white.withValues(alpha: 0.05),
          )
        : s.darkTheme
        ? Colors.black
        : const Color(0xFF1E1E1E),
  );
}

const double _cardRadius = 28;

/// Container transform: the pill's rounded box grows into the card. The
/// badge text fades out early and the card's real content fades in over
/// the second half, laid out at the card's final size and revealed by the
/// growing clip, so the card is never seen empty.
///
/// At both ends it draws exactly what's under it (the badge as it sits in
/// the top bar, the card as it sits in the dialog), so neither take-off nor
/// landing jumps.
Widget _morphShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final bool push = direction == HeroFlightDirection.push;
  final BuildContext pillContext = push ? fromHeroContext : toHeroContext;
  final BuildContext cardContext = push ? toHeroContext : fromHeroContext;
  final Widget pill = (pillContext.widget as Hero).child;
  final Size? pillSize = _sizeOf(pillContext);
  // The top bar is drawn enlarged at a low display density (PlayerScaled);
  // pillSize is its layout size, so the pill is drawn at that scale too.
  final double pillScale = PlayerScale.of(pillContext);
  final surface = _surface(
    ProviderScope.containerOf(flightContext).read(settingsProvider),
  );

  // The shuttle's own box starts invisible with the badge's corners (the
  // badge still draws its own fill and border, fading out on top) and
  // ends as the card's surface.
  // Clamped to half the pill's height: that's how the badge's 100 radius
  // actually draws, and lerping from 100 would balloon the growing box.
  final double badgeRadius = pill is QualityBadge
      ? (QualityBadge.decorationFor(pill.style, null).borderRadius
                as BorderRadius)
            .topLeft
            .x
      : 20;
  final BorderRadius pillRadius = BorderRadius.circular(
    math.min(badgeRadius, (pillSize?.height ?? 40) / 2) * pillScale,
  );
  const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(_cardRadius),
  );

  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      // The route animation: 0 = closed pill, 1 = open card, both ways.
      final double open = Curves.easeInOutCubic.transform(animation.value);
      final double pillFade = (1 - open / 0.3).clamp(0.0, 1.0);
      final double contentFade = ((open - 0.3) / 0.5).clamp(0.0, 1.0);
      final BorderRadius radius = BorderRadius.lerp(
        pillRadius,
        cardRadius,
        open,
      )!;
      // Read every frame, not once at take-off: the card's live content
      // (the sheet may rebuild during the flight) at its current size.
      final Widget? cardChild = cardContext.mounted
          ? (cardContext.widget as Hero).child
          : null;
      final Widget? content = cardChild is _DialogCard
          ? cardChild.content
          : null;
      final Size? cardSize = cardContext.mounted ? _sizeOf(cardContext) : null;

      Widget body = ColoredBox(
        color: surface.color.withValues(alpha: surface.color.a * open),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (contentFade > 0 && content != null && cardSize != null)
              Opacity(
                opacity: contentFade,
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minWidth: cardSize.width,
                  maxWidth: cardSize.width,
                  minHeight: cardSize.height,
                  maxHeight: cardSize.height,
                  child: content,
                ),
              ),
            // Laid out at the badge's own size: unbounded, its Flexible
            // text is a layout error (a red frame in debug builds) and in
            // release loses its ellipsis.
            if (pillFade > 0 && pillSize != null)
              Center(
                child: Opacity(
                  opacity: pillFade,
                  child: Transform.scale(
                    scale: pillScale,
                    child: OverflowBox(
                      minWidth: pillSize.width,
                      maxWidth: pillSize.width,
                      minHeight: pillSize.height,
                      maxHeight: pillSize.height,
                      child: pill,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
      if (surface.blur) {
        body = BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10 * open, sigmaY: 10 * open),
          child: body,
        );
      }
      return Material(
        type: MaterialType.transparency,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: Colors.white10.withValues(alpha: Colors.white10.a * open),
              width: 0.6,
            ),
          ),
          child: ClipRRect(borderRadius: radius, child: body),
        ),
      );
    },
  );
}

Size? _sizeOf(BuildContext context) {
  final RenderObject? box = context.findRenderObject();
  return box is RenderBox && box.hasSize ? box.size : null;
}

String _khz(int hz) => '${(hz / 1000).toStringAsFixed(1)} kHz';

String? _formatLabel(Format? f) => switch (f) {
  null || Format.auto => null,
  Format.u8 || Format.u8Planar => '8-bit int',
  Format.s16 || Format.s16Planar => '16-bit int',
  Format.s32 || Format.s32Planar => '32-bit int',
  Format.s64 || Format.s64Planar => '64-bit int',
  Format.float32 || Format.float32Planar => '32-bit float',
  Format.float64 || Format.float64Planar => '64-bit float',
};

class _QualityDetailsSheet extends ConsumerStatefulWidget {
  final Song song;

  /// Resolved before the push (see [showQualityDetailsSheet]); when
  /// [deviceFresh] is false it's the last cached value, refreshed here.
  final DeviceAudioInfo? device;
  final bool deviceFresh;
  final int? fileSize;

  const _QualityDetailsSheet({
    required this.song,
    this.device,
    this.deviceFresh = false,
    this.fileSize,
  });

  @override
  ConsumerState<_QualityDetailsSheet> createState() =>
      _QualityDetailsSheetState();
}

class _QualityDetailsSheetState extends ConsumerState<_QualityDetailsSheet>
    with TickerProviderStateMixin {
  /// Staggered entrance of the sections. Starts with the push, so the
  /// rows are already cascading in as the morph (which draws this same
  /// content) opens up.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..forward();

  late final Player _player = ref.read(audioServiceProvider).player;
  final List<StreamSubscription<Object?>> _subs = [];
  late DeviceAudioInfo? _device = widget.device;
  late bool _deviceLoaded = widget.deviceFresh || !Platform.isAndroid;
  late int? _fileSize = widget.fileSize;

  @override
  void initState() {
    super.initState();
    // The engine values change as mpv (re)configures the output; rebuild
    // from player.state whenever one of them moves.
    void refresh(Object? _) {
      if (mounted) setState(() {});
    }

    _subs
      ..add(_player.stream.audioParams.listen(refresh))
      ..add(_player.stream.audioOutParams.listen(refresh))
      ..add(_player.stream.audioBitrate.listen(refresh))
      ..add(_player.stream.audioDevice.listen(refresh));

    // Only when the pre-push fetches ran out of time.
    if (!_deviceLoaded) {
      DeviceAudioInfo.fetch().then((info) {
        if (mounted) {
          setState(() {
            _device = info ?? _device;
            _deviceLoaded = true;
          });
        }
      });
    }
    final path = widget.song.path;
    if (AudioAnalyzer.getCachedAnalysis(path) == null) {
      AudioAnalyzer.analyze(path).then((_) {
        if (mounted) setState(() {});
      }, onError: (_) {});
    }
    if (_fileSize == null && !path.startsWith('content://')) {
      File(path).length().then((size) {
        if (mounted) setState(() => _fileSize = size);
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _intro.dispose();
    super.dispose();
  }

  /// Fade + rise for the [index]th block, spaced ~40ms apart.
  Widget _stagger(int index, Widget child) {
    final double start = math.min(index * 0.06, 0.4);
    final animation = CurvedAnimation(
      parent: _intro,
      curve: Interval(start, start + 0.5, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final song = widget.song;
    final AudioAnalysis? analysis = AudioAnalyzer.getCachedAnalysis(song.path);
    final QualityInfo info = analysis != null
        ? QualityInfo.fromAnalysis(analysis)
        : QualityInfo.fromPath(song.path);
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color tint =
        QualityBadge.tierColor(info.tier, primary) ?? Colors.white;
    final badgeIcon = ref.watch(
      settingsProvider.select((s) => QualityBadgeStyle.fromSettings(s).icon),
    );
    final bool eqOn = ref.watch(equalizerProvider.select((s) => s.enabled));

    final PlayerState ps = _player.state;
    final AudioParams dec = ps.audioParams;
    final AudioParams out = ps.audioOutParams;
    final DeviceAudioInfo? device = _device;

    // Where the rate changes on the way out: mpv's output, then Android's
    // mixer (skipped in bit-perfect mode, which we can't confirm is active).
    final int? sourceRate = info.sampleRate > 0
        ? info.sampleRate
        : dec.sampleRate;
    final int? outRate = out.sampleRate;
    final int? finalRate = device?.nativeSampleRate ?? outRate;
    final bool resampled =
        sourceRate != null &&
        finalRate != null &&
        info.tier != QualityTier.dsd &&
        sourceRate != finalRate;

    final details = <String>[
      info.codec ?? l10n.qualityAudio,
      if (info.bitsPerSample > 1) '${info.bitsPerSample}-bit',
      if (info.sampleRate > 0) _khz(info.sampleRate),
    ].join(' · ');

    int block = 0;
    return QualityDialogFrame(
      child: SingleChildScrollView(
        physics: const LooperScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _stagger(
              block++,
              _Header(
                intro: _intro,
                tint: tint,
                icon: QualityBadge.iconWidget(
                  badgeIcon == QualityBadgeIcon.none
                      ? QualityBadgeIcon.ribbon
                      : badgeIcon,
                  22,
                  tint,
                )!,
                title: QualityBadge.tierLabel(context, info.tier),
                subtitle: details,
                song: song.title,
              ),
            ),
            const SizedBox(height: 16),
            _stagger(block++, _SectionTitle(l10n.qualitySignalPath)),
            _stagger(
              block++,
              PauseWhenOffscreen(
                child: _PulseHost(
                  builder: (pulse) => _SignalPath(
                    pulse: pulse,
                    tint: tint,
                    stages: [
                      _Stage(
                        LucideIcons.fileAudio,
                        l10n.qualityStageSource,
                        info.codec ?? l10n.qualityAudio,
                        sourceRate != null ? _khz(sourceRate) : null,
                      ),
                      _Stage(
                        LucideIcons.cpu,
                        l10n.qualityStageDecoder,
                        (dec.codec ?? dec.codecName ?? '—').toUpperCase(),
                        _formatLabel(dec.format),
                      ),
                      _Stage(
                        LucideIcons.audioLines,
                        l10n.qualityStageOutput,
                        outRate != null ? _khz(outRate) : '—',
                        _formatLabel(out.format),
                      ),
                      _Stage(
                        _deviceIcon(device?.device?.kind),
                        l10n.qualityStageDevice,
                        device?.device != null
                            ? _deviceKindLabel(l10n, device!.device!.kind)
                            : '—',
                        device?.nativeSampleRate != null
                            ? _khz(device!.nativeSampleRate!)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _stagger(
              block++,
              _Verdict(
                ok: !resampled,
                text: resampled
                    ? l10n.qualityResampledBy(_khz(sourceRate), _khz(finalRate))
                    : l10n.qualityNativeEndToEnd,
              ),
            ),
            _stagger(
              block++,
              _Section(
                icon: LucideIcons.fileAudio,
                title: l10n.qualitySectionSource,
                rows: [
                  (l10n.codec, info.codec ?? l10n.qualityAudio),
                  if (analysis != null)
                    (l10n.container, analysis.container.toUpperCase()),
                  if (info.bitsPerSample > 0)
                    (l10n.bitDepth, '${info.bitsPerSample}-bit'),
                  if (info.sampleRate > 0)
                    (l10n.sampleRate, _khz(info.sampleRate)),
                  if (info.bitrate > 0)
                    (l10n.bitrate, '${(info.bitrate / 1000).round()} kbps'),
                  if (info.channels > 0)
                    (l10n.channels, _channelLabel(l10n, info.channels)),
                  if ((song.duration ?? 0) > 0)
                    (l10n.duration, _duration(song.duration!)),
                  if (_fileSize != null) (l10n.fileSize, _bytes(_fileSize!)),
                ],
              ),
            ),
            _stagger(
              block++,
              _Section(
                icon: LucideIcons.cpu,
                title: l10n.qualitySectionEngine,
                rows: [
                  if (dec.codecName != null || dec.codec != null)
                    (l10n.qualityStageDecoder, dec.codecName ?? dec.codec!),
                  if (_formatLabel(dec.format) != null)
                    (l10n.decodedFormat, _formatLabel(dec.format)!),
                  if (_formatLabel(out.format) != null)
                    (l10n.qualityOutputFormat, _formatLabel(out.format)!),
                  if (outRate != null) (l10n.qualityOutputRate, _khz(outRate)),
                  if (out.hrChannels != null || out.channelCount != null)
                    (
                      l10n.qualityOutputChannels,
                      out.hrChannels ??
                          _channelLabel(l10n, out.channelCount ?? 0),
                    ),
                  if (ps.audioBitrate != null)
                    (
                      l10n.qualityLiveBitrate,
                      '${(ps.audioBitrate! / 1000).round()} kbps',
                    ),
                  (
                    l10n.qualityGapless,
                    ps.gapless == Gapless.no ? l10n.off : l10n.on,
                  ),
                  (
                    l10n.qualityReplayGain,
                    switch (ps.replayGain.mode) {
                      ReplayGain.no => l10n.off,
                      ReplayGain.track => l10n.qualityReplayGainTrack,
                      ReplayGain.album => l10n.qualityReplayGainAlbum,
                    },
                  ),
                  (l10n.equalizer, eqOn ? l10n.on : l10n.off),
                  if (ps.rate != 1.0)
                    (l10n.qualitySpeed, '${ps.rate.toStringAsFixed(2)}×'),
                ],
              ),
            ),
            if (device?.device != null)
              _stagger(
                block++,
                _Section(
                  icon: _deviceIcon(device!.device!.kind),
                  title: l10n.qualitySectionDevice,
                  note: l10n.qualityDeviceNote,
                  rows: _deviceRows(l10n, device.device!, device),
                ),
              ),
            if (device != null)
              _stagger(
                block++,
                _Section(
                  icon: LucideIcons.smartphone,
                  title: l10n.qualitySectionPhone,
                  rows: [
                    (
                      l10n.qualityPhoneModel,
                      '${_capitalize(device.manufacturer)} ${device.model}'
                          .trim(),
                    ),
                    (
                      l10n.qualityAndroidVersion,
                      '${device.androidVersion} (API ${device.sdkInt})',
                    ),
                    if (device.nativeSampleRate != null)
                      (l10n.qualityMixerRate, _khz(device.nativeSampleRate!)),
                    if (device.framesPerBuffer != null)
                      (
                        l10n.qualityMixerBuffer,
                        device.bufferMs != null
                            ? '${device.framesPerBuffer} · '
                                  '${device.bufferMs!.toStringAsFixed(1)} ms'
                            : '${device.framesPerBuffer}',
                      ),
                    (
                      l10n.qualityLowLatency,
                      device.lowLatency
                          ? l10n.qualitySupported
                          : l10n.qualityNotSupported,
                    ),
                    (
                      l10n.qualityProAudio,
                      device.proAudio
                          ? l10n.qualitySupported
                          : l10n.qualityNotSupported,
                    ),
                  ],
                ),
              )
            else if (_deviceLoaded && !Platform.isAndroid)
              _stagger(
                block++,
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    l10n.qualityDeviceUnavailable,
                    textAlign: TextAlign.center,
                    style: AppFonts.jostStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _deviceRows(
    AppLocalizations l10n,
    OutputDeviceInfo d,
    DeviceAudioInfo phone,
  ) {
    final rates = d.sampleRates;
    return [
      if (d.name != null && d.name!.isNotEmpty)
        (l10n.qualityDeviceName, d.name!),
      (l10n.qualityDeviceType, _deviceKindLabel(l10n, d.kind)),
      (
        l10n.qualitySupportedRates,
        rates.isEmpty
            ? l10n.qualityAnyRate
            : rates.length == 1
            ? _khz(rates.first)
            : '${_khz(rates.first)} – ${_khz(rates.last)}',
      ),
      if (d.maxBits > 0)
        (
          l10n.qualityMaxBitDepth,
          d.supportsFloat ? '${d.maxBits}-bit (float)' : '${d.maxBits}-bit',
        ),
      if (d.maxChannels > 0)
        (l10n.qualityMaxChannels, _channelLabel(l10n, d.maxChannels)),
      (
        l10n.qualityBitPerfect,
        d.bitPerfect ? l10n.qualitySupported : l10n.qualityNotSupported,
      ),
      if (phone.spatialAvailable != null)
        (
          l10n.qualitySpatialAudio,
          phone.spatialAvailable != true
              ? l10n.notAvailable
              : (phone.spatialEnabled == true ? l10n.on : l10n.off),
        ),
    ];
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _duration(int ms) {
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String _bytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}

String _channelLabel(AppLocalizations l10n, int channels) => switch (channels) {
  1 => l10n.qualityMono,
  2 => l10n.qualityStereo,
  6 => '5.1',
  8 => '7.1',
  final n => '$n ch',
};

IconData _deviceIcon(OutputDeviceKind? kind) => switch (kind) {
  null || OutputDeviceKind.speaker => LucideIcons.speaker,
  OutputDeviceKind.wired => LucideIcons.headphones,
  OutputDeviceKind.bluetooth => LucideIcons.bluetooth,
  OutputDeviceKind.usb => LucideIcons.usb,
  OutputDeviceKind.hdmi => LucideIcons.tv,
  OutputDeviceKind.hearingAid => LucideIcons.ear,
  OutputDeviceKind.dock => LucideIcons.monitorSpeaker,
};

String _deviceKindLabel(AppLocalizations l10n, OutputDeviceKind kind) =>
    switch (kind) {
      OutputDeviceKind.speaker => l10n.qualityDeviceSpeaker,
      OutputDeviceKind.wired => l10n.qualityDeviceWired,
      OutputDeviceKind.bluetooth => l10n.qualityDeviceBluetooth,
      OutputDeviceKind.usb => l10n.qualityDeviceUsb,
      OutputDeviceKind.hdmi => l10n.qualityDeviceHdmi,
      OutputDeviceKind.hearingAid => l10n.qualityDeviceHearingAid,
      OutputDeviceKind.dock => l10n.qualityDeviceDock,
    };

/// Owns the endless pulse of the signal-path arrows, below the
/// [PauseWhenOffscreen] around it, so the loop stops while it is scrolled
/// out of the sheet.
class _PulseHost extends StatefulWidget {
  const _PulseHost({required this.builder});

  final Widget Function(Animation<double> pulse) builder;

  @override
  State<_PulseHost> createState() => _PulseHostState();
}

class _PulseHostState extends State<_PulseHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_pulse);
}
