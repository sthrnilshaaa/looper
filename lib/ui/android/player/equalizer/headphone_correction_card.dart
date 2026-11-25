part of 'android_equalizer_screen.dart';

class _HeadphoneCorrectionCard extends ConsumerStatefulWidget {
  final EqualizerState eqState;
  final Equalizer eqNotifier;
  final Color accentColor;

  const _HeadphoneCorrectionCard({
    required this.eqState,
    required this.eqNotifier,
    required this.accentColor,
  });

  @override
  ConsumerState<_HeadphoneCorrectionCard> createState() =>
      _HeadphoneCorrectionCardState();
}

class _HeadphoneCorrectionCardState
    extends ConsumerState<_HeadphoneCorrectionCard> {
  DeviceAudioInfo? _audioInfo;
  double _dragBass = 0.0;
  double _dragTilt = 0.0;
  bool _isDraggingBass = false;
  bool _isDraggingTilt = false;

  @override
  void initState() {
    super.initState();
    _audioInfo = DeviceAudioInfo.cached;
    _refreshDeviceInfo();
  }

  Future<void> _refreshDeviceInfo() async {
    final info = await DeviceAudioInfo.fetch();
    if (mounted && info != null) setState(() => _audioInfo = info);
  }

  String _deviceDisplayLabel(OutputDeviceInfo? d, AppLocalizations l10n) {
    if (d == null) return 'Audio Output';
    if (d.kind == OutputDeviceKind.speaker) return 'Phone speaker';
    if (d.kind == OutputDeviceKind.bluetooth) {
      return 'Bluetooth · ${d.name ?? 'Headphones'}';
    }
    if (d.kind == OutputDeviceKind.usb) return 'USB · ${d.name ?? 'DAC'}';
    if (d.kind == OutputDeviceKind.wired) return 'Wired headphones';
    return d.name ?? d.kind.name;
  }

  IconData _deviceIcon(OutputDeviceInfo? d) {
    if (d == null) return LucideIcons.headphones;
    if (d.kind == OutputDeviceKind.speaker) return LucideIcons.volume2;
    if (d.kind == OutputDeviceKind.bluetooth) return LucideIcons.bluetooth;
    if (d.kind == OutputDeviceKind.usb) return LucideIcons.cable;
    return LucideIcons.headphones;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final device = _audioInfo?.device;
    final isSpeaker = device?.kind == OutputDeviceKind.speaker;
    final activeBass = _isDraggingBass ? _dragBass : widget.eqState.autoEqBass;
    final activeTilt = _isDraggingTilt ? _dragTilt : widget.eqState.autoEqTilt;

    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kEqCard,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Device icon + label, profile name or 'None', switch
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _deviceIcon(device),
                  color: widget.accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deviceDisplayLabel(device, l10n),
                      style: AppFonts.jostStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.eqState.autoEqSelectedProfile ??
                          l10n.autoEqNoProfile,
                      style: AppFonts.jostStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.56),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Semantics(
                label:
                    '${l10n.headphoneCorrection}, ${widget.eqState.autoEqEnabled ? "on" : "off"}',
                child: Switch(
                  value: widget.eqState.autoEqEnabled && !isSpeaker,
                  onChanged: isSpeaker
                      ? null
                      : (val) {
                          AppHaptics.medium();
                          widget.eqNotifier.setAutoEqEnabled(val);
                        },
                ),
              ),
            ],
          ),

          if (isSpeaker) ...[
            const SizedBox(height: 8),
            Text(
              l10n.autoEqSpeakerDisabled,
              style: AppFonts.jostStyle(
                fontSize: 11,
                color: Colors.white38,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          if (widget.eqState.autoEqEnabled && !isSpeaker) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 14),

            // Bass Slider (-12 .. +12 dB)
            Row(
              children: [
                Text(
                  l10n.autoEqBass,
                  style: AppFonts.jostStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${activeBass > 0 ? "+" : ""}${activeBass.toStringAsFixed(1)} dB',
                  style: AppFonts.jostStyle(
                    fontSize: 12,
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: widget.accentColor,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                thumbColor: Colors.white,
                trackHeight: 3.0,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: activeBass.clamp(-12.0, 12.0),
                min: -12.0,
                max: 12.0,
                divisions: 48,
                onChanged: (val) {
                  setState(() {
                    _isDraggingBass = true;
                    _dragBass = val;
                  });
                },
                onChangeEnd: (val) {
                  setState(() {
                    _isDraggingBass = false;
                  });
                  widget.eqNotifier.setAutoEqBass(val);
                },
              ),
            ),

            // Tilt Slider (-1.5 .. +1.5 dB/oct)
            Row(
              children: [
                Text(
                  l10n.autoEqTilt,
                  style: AppFonts.jostStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${activeTilt > 0 ? "+" : ""}${activeTilt.toStringAsFixed(2)} dB/oct',
                  style: AppFonts.jostStyle(
                    fontSize: 12,
                    color: widget.accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: widget.accentColor,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                thumbColor: Colors.white,
                trackHeight: 3.0,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: activeTilt.clamp(-1.5, 1.5),
                min: -1.5,
                max: 1.5,
                divisions: 30,
                onChanged: (val) {
                  setState(() {
                    _isDraggingTilt = true;
                    _dragTilt = val;
                  });
                },
                onChangeEnd: (val) {
                  setState(() {
                    _isDraggingTilt = false;
                  });
                  widget.eqNotifier.setAutoEqTilt(val);
                },
              ),
            ),

            // Mode scope indicator chip
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.eqState.currentSongHasCustom
                        ? l10n.eqSongSpecific
                        : l10n.eqGlobalDefault,
                    style: AppFonts.jostStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Actions row: "Choose headphones…", "Use for this device", "Saved devices"
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openHeadphonePicker(context, l10n),
                  icon: Icon(
                    LucideIcons.search,
                    size: 14,
                    color: widget.accentColor,
                  ),
                  label: Text(
                    l10n.autoEqChooseHeadphones,
                    style: AppFonts.jostStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: widget.accentColor.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                if (widget.eqState.autoEqSelectedProfile != null)
                  TextButton.icon(
                    onPressed: () async {
                      final key = AutoEqService.deviceKey(device);
                      await AutoEqService.instance.saveDeviceProfile(
                        key,
                        widget.eqState.autoEqSelectedProfile!,
                      );
                      AppHaptics.medium();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${widget.eqState.autoEqSelectedProfile} saved for ${_deviceDisplayLabel(device, l10n)}',
                              style: AppFonts.jostStyle(color: Colors.white),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      LucideIcons.hardDrive,
                      size: 14,
                      color: widget.accentColor,
                    ),
                    label: Text(
                      l10n.autoEqUseForDevice,
                      style: AppFonts.jostStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _showSavedDevicesDialog(context, l10n),
                  icon: const Icon(
                    LucideIcons.list,
                    size: 14,
                    color: Colors.white54,
                  ),
                  label: Text(
                    l10n.autoEqSavedDevices,
                    style: AppFonts.jostStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Credit footer
            Text(
              l10n.autoEqCredit,
              style: AppFonts.jostStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openHeadphonePicker(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AppBottomSheetContainer(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: _AutoEqSearchSheetContent(
          accentColor: widget.accentColor,
          onProfileSelected: (profile) {
            widget.eqNotifier.setAutoEqProfile(profile);
            widget.eqNotifier.setAutoEqEnabled(true);
            AppHaptics.medium();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'AutoEQ: ${profile.name}',
                    style: AppFonts.jostStyle(color: Colors.white),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _showSavedDevicesDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final devices = await AutoEqService.instance.getSavedDevices();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              l10n.autoEqSavedDevices,
              style: AppFonts.jostStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: devices.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        l10n.autoEqNoSavedDevices,
                        style: AppFonts.jostStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: devices.entries.map((entry) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry.key,
                            style: AppFonts.jostStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            entry.value,
                            style: AppFonts.jostStyle(
                              color: widget.accentColor,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              LucideIcons.trash2,
                              size: 16,
                              color: Colors.redAccent,
                            ),
                            tooltip: l10n.autoEqForget,
                            onPressed: () async {
                              await AutoEqService.instance.forgetDeviceProfile(
                                entry.key,
                              );
                              setDialogState(() {
                                devices.remove(entry.key);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  l10n.cancel,
                  style: AppFonts.jostStyle(color: widget.accentColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AutoEqSearchSheetContent extends StatefulWidget {
  final Color accentColor;
  final ValueChanged<AutoEqProfile> onProfileSelected;

  const _AutoEqSearchSheetContent({
    required this.accentColor,
    required this.onProfileSelected,
  });

  @override
  State<_AutoEqSearchSheetContent> createState() =>
      _AutoEqSearchSheetContentState();
}

class _AutoEqSearchSheetContentState extends State<_AutoEqSearchSheetContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<AutoEqIndexEntry> _allEntries = const [];
  List<AutoEqIndexEntry> _filtered = const [];
  bool _isLoading = true;
  String? _loadingEntryPath;

  @override
  void initState() {
    super.initState();
    _loadIndex();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIndex() async {
    setState(() => _isLoading = true);
    final entries = await AutoEqService.instance.loadIndex();
    if (mounted) {
      setState(() {
        _allEntries = entries;
        _isLoading = false;
        _filtered = _searchCtrl.text.trim().isEmpty
            ? entries.take(50).toList()
            : AutoEqService.searchIndex(entries, _searchCtrl.text.trim());
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_allEntries.isEmpty) return;
    setState(() {
      _filtered = query.trim().isEmpty
          ? _allEntries.take(50).toList()
          : AutoEqService.searchIndex(_allEntries, query.trim());
    });
  }

  Future<void> _selectEntry(AutoEqIndexEntry entry) async {
    setState(() => _loadingEntryPath = entry.path);
    final profile = await AutoEqService.instance.fetchProfile(entry);
    if (mounted) {
      setState(() => _loadingEntryPath = null);
      if (profile != null) {
        Navigator.of(context).pop();
        widget.onProfileSelected(profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            style: AppFonts.jostStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: l10n.autoEqSearchHeadphones,
              hintStyle: AppFonts.jostStyle(color: Colors.white38),
              prefixIcon: const Icon(
                LucideIcons.search,
                color: Colors.white54,
                size: 18,
              ),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        color: Colors.white54,
                        size: 16,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: widget.accentColor,
                          strokeWidth: 2.5,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.autoEqIndexDownloading,
                          style: AppFonts.jostStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Text(
                      _allEntries.isEmpty
                          ? l10n.autoEqDownloadIndex
                          : 'No headphones found',
                      style: AppFonts.jostStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, index) {
                      final entry = _filtered[index];
                      final isFetching = _loadingEntryPath == entry.path;

                      return ListTile(
                        title: Text(
                          entry.name,
                          style: AppFonts.jostStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          entry.source,
                          style: AppFonts.jostStyle(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                        trailing: isFetching
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: widget.accentColor,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                LucideIcons.chevronRight,
                                color: Colors.white24,
                                size: 16,
                              ),
                        onTap: isFetching ? null : () => _selectEntry(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
