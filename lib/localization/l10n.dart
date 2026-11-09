import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  /// UI strings for the current locale (ARB). Recipe and ingredient
  /// names come from the catalog, not from here.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
