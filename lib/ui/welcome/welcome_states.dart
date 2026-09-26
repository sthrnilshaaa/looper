part of 'welcome_screen.dart';

extension _WelcomeStates on _WelcomeScreenState {
  Widget _buildStateContent(ColorScheme colorScheme, AppLocalizations l10n) {
    switch (_currentState) {
      case WelcomeState.scanning:
        return _buildScanningState(colorScheme, l10n);
      case WelcomeState.indexing:
        return _buildIndexingState(colorScheme, l10n);
      case WelcomeState.noSongs:
        return _buildNoSongsState(colorScheme, l10n);
      case WelcomeState.initial:
      default:
        return _buildInitialState(colorScheme, l10n);
    }
  }

  // State 1: Initial Premium Welcome State
  Widget _buildInitialState(ColorScheme colorScheme, AppLocalizations l10n) {
    final librarySongs = ref.watch(libraryProvider).songs;
    final settings = ref.watch(settingsProvider);

    return Column(
      key: const ValueKey('initial_state'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Brand logo container with glowing borders
        Container(
          padding: const EdgeInsets.all(28.0),
          child: SizedBox(
            height: 100.s,
            width: 200.s,
            child: SvgPicture.asset(
              'assets/main_logo_transparent.svg',
              fit: BoxFit.contain,
              placeholderBuilder: (context) => Icon(
                LucideIcons.music,
                size: 50.s,
                color: colorScheme.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Clean & Modern Title Typography
        Text(
          l10n.appTitle.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28.ts,
            fontWeight: FontWeight.w200,
            letterSpacing: 10,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "LOOPER PLAYER",
          style: TextStyle(
            fontSize: 11.ts,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary.withValues(alpha: 0.6),
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 32),

        // Premium About Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 16.s,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.aboutLooperPlayer.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.ts,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.welcomeAboutDesc,
                style: TextStyle(
                  fontSize: 13.ts,
                  height: 1.6,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Interactive Permission Checklist (Sequential Setup)
        if (Platform.isAndroid) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      size: 16.s,
                      color: Color(settings.accentColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.systemPermissionChecklist.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.ts,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. Notification Permission Row
                _buildPermissionRow(
                  title: l10n.notificationAccess.toUpperCase(),
                  description: l10n.welcomeNotificationDesc,
                  isGranted: _notificationGranted,
                  onGrant: _requestNotificationPermission,
                  colorScheme: colorScheme,
                  accentColor: Color(settings.accentColor),
                  l10n: l10n,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(height: 1, color: Colors.white10),
                ),

                // 2. Music & Audio Permission Row
                _buildPermissionRow(
                  title: l10n.musicAudioAccess.toUpperCase(),
                  description: l10n.welcomeMusicAudioDesc,
                  isGranted: _audioGranted,
                  onGrant: _requestAudioPermission,
                  colorScheme: colorScheme,
                  accentColor: Color(settings.accentColor),
                  l10n: l10n,
                ),

                // 3. All Files Access Row (github flavor, optional)
                // Its availability is only known after an async native
                // check, so grow it in rather than letting the card jump.
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: _canOfferAllFiles
                      ? Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1, color: Colors.white10),
                            ),
                            _buildPermissionRow(
                              title: l10n.allFilesAccess.toUpperCase(),
                              description: l10n.welcomeAllFilesDesc,
                              isGranted: _allFilesGranted,
                              onGrant: _requestAllFilesPermission,
                              colorScheme: colorScheme,
                              accentColor: Color(settings.accentColor),
                              l10n: l10n,
                            ),
                          ],
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Modern Action Button area
        Column(
          children: [
            // GO START Button (Colored when standard permission is granted, otherwise greyed)
            _PremiumButton(
              onPressed: _permissionGranted
                  ? () async {
                      await _startStorageScanFlow();
                    }
                  : null,
              label: l10n.goStart,
              icon: LucideIcons.playCircle,
              gradientColors: _permissionGranted
                  ? [
                      Color(settings.accentColor),
                      Color(settings.accentColor).withValues(alpha: 0.75),
                    ]
                  : [
                      Colors.grey.withValues(alpha: 0.3),
                      Colors.grey.withValues(alpha: 0.2),
                    ],
            ),
            const SizedBox(height: 24),

            // Scan Completion Status feedback
            if (_permissionGranted && librarySongs.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Color(settings.accentColor).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Color(settings.accentColor).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      color: Color(settings.accentColor),
                      size: 18.s,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.scanCompleteSongsDetected(librarySongs.length),
                      style: TextStyle(
                        fontSize: 12.ts,
                        fontWeight: FontWeight.bold,
                        color: Color(settings.accentColor),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionRow({
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onGrant,
    required ColorScheme colorScheme,
    required Color accentColor,
    required AppLocalizations l10n,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2.0),
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: isGranted
                ? accentColor.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isGranted ? LucideIcons.check : LucideIcons.shieldAlert,
            size: 16.s,
            color: isGranted ? accentColor : Colors.white60,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11.ts,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (!isGranted)
          SizedBox(
            height: 30.s,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: accentColor.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14.0,
                  vertical: 0.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: onGrant,
              child: Text(
                l10n.grant,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.ts,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l10n.granted,
              style: TextStyle(
                color: accentColor,
                fontSize: 11.ts,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // State 2: Deep Scanning State
  Widget _buildScanningState(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('scanning_state'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _ScanningLottieAnimation(),
        const SizedBox(height: 24),
        Text(
          l10n.deepStorageScanProgress,
          style: TextStyle(
            fontSize: 16.ts,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            l10n.welcomeScanningFoldersDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.ts,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // State 2b: Brief final "Indexing..." beat shown after the scan itself
  // finds songs but before handing off to Home - covers the moment Pass 2
  // enrichment (tags/art/lyrics) is just getting started in the background,
  // so the app doesn't cut straight from "scanning" to a Home screen full
  // of half-populated song rows.
  Widget _buildIndexingState(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      key: const ValueKey('indexing_state'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _ScanningLottieAnimation(),
        const SizedBox(height: 24),
        Text(
          context.l10n.indexingYourLibrary,
          style: TextStyle(
            fontSize: 16.ts,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            context.l10n.indexingYourLibraryDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.ts,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36.s,
            width: 36.s,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 16.s, color: colorScheme.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.welcomeStep(stepNumber, title),
                  style: TextStyle(
                    fontSize: 11.ts,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.ts,
                    color: Colors.white.withValues(alpha: 0.45),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
