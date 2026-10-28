import 'package:flutter/widgets.dart';

/// The words the package shows itself, in the app's language.
///
/// They follow `Localizations.localeOf(context)`, so an app that sets
/// `MaterialApp.locale` or `supportedLocales` gets them translated with no
/// delegate to add. A language missing here falls back to English; pass
/// your own text where a widget takes one, such as
/// `AdaptiveNavScaffold.moreLabel`.
abstract final class NavStrings {
  /// The label of the tab that lists the tabs a bar has no room for.
  static String more(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context);
    return _more[locale?.languageCode] ?? _more['en']!;
  }

  /// The languages [more] has a translation for.
  static Iterable<String> get languages => _more.keys;

  static const _more = {
    'ar': 'المزيد',
    'de': 'Mehr',
    'en': 'More',
    'es': 'Más',
    'fa': 'بیشتر',
    'fr': 'Plus',
    'he': 'עוד',
    'hi': 'अधिक',
    'id': 'Lainnya',
    'it': 'Altro',
    'ja': 'その他',
    'ko': '더보기',
    'nl': 'Meer',
    'pl': 'Więcej',
    'pt': 'Mais',
    'ru': 'Ещё',
    'th': 'เพิ่มเติม',
    'tr': 'Daha fazla',
    'uk': 'Більше',
    'vi': 'Thêm',
    'zh': '更多',
  };
}
