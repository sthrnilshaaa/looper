import 'package:flutter/widgets.dart';
import 'package:looper_player/core/providers/providers.dart';
import 'package:looper_player/l10n/app_localizations.dart';

extension L10nContext on BuildContext {
  /// Shorthand for `AppLocalizations.of(context)!`.
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Localized strings for code that has no [BuildContext] (services,
/// notifiers). Resolves through the app's scaffold messenger, so it follows
/// the language the app is currently showing; before the app has mounted it
/// falls back to English.
AppLocalizations currentL10n() {
  final context = scaffoldMessengerKey.currentContext;
  final l10n = context == null ? null : AppLocalizations.of(context);
  return l10n ?? lookupAppLocalizations(const Locale('en'));
}
