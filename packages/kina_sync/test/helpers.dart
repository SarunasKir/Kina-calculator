import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:kina_data/kina_data.dart';

/// A fresh in-memory database.
KinaDatabase openTestDatabase() {
  // Sync tests deliberately open two databases, like a PC and a phone.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return KinaDatabase(NativeDatabase.memory());
}

/// A journal entry for tests.
JournalEntry entry(String id, String item, {DateTime? date}) => JournalEntry(
  id: id,
  date: date ?? DateTime.utc(2026, 10, 20),
  item: item,
  kina: Decimal.parse('25000000'),
  qunaEquivalent: Decimal.parse('7500'),
  officialEur: Decimal.parse('95.63'),
  rmtEur: Decimal.parse('33.05'),
  currency: 'EUR',
  fxRatePerEur: Decimal.parse('1'),
);
