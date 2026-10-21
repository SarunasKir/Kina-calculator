import 'package:drift/native.dart';
import 'package:kina_data/kina_data.dart';

/// A fresh in-memory database for one test.
KinaDatabase openTestDatabase() => KinaDatabase(NativeDatabase.memory());
