import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/export/csv.dart';
import 'package:kina_app/src/providers.dart';

/// Asks where to save [csv] as a file named after [stem], and reports the
/// outcome in a snack bar.
Future<void> exportCsv(
  BuildContext context,
  WidgetRef ref, {
  required String stem,
  required String csv,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final where = await ref
        .read(fileAccessProvider)
        .saveText(csvFileName(stem, clock.now()), csv);
    if (where != null) {
      messenger.showSnackBar(SnackBar(content: Text('CSV saved: $where')));
    }
  } on Exception catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}
