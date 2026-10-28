import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app.dart';
import 'data/plans/template_plan_builder.dart';

void main() {
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(AiSportApp(planBuilder: TemplatePlanBuilder()));
}

Stream<LicenseEntry> _fontLicenses() async* {
  for (final family in const ['Manrope', 'Unbounded']) {
    final text = await rootBundle.loadString('assets/fonts/OFL-$family.txt');
    yield LicenseEntryWithLineBreaks([family], text);
  }
}
