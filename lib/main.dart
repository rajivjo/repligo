import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');
  // Free Syncfusion Community License (revenue < $1M): register at
  // https://www.syncfusion.com/products/communitylicense — see README.md
  // "Syncfusion license" section. Note: registerLicense() is a deprecated
  // no-op in the pinned syncfusion_flutter_core version (license is no
  // longer enforced), kept here for forward/backward compatibility.
  // ignore: deprecated_member_use
  SyncfusionLicense.registerLicense('YOUR_LICENSE_KEY_HERE');
  runApp(
    const ProviderScope(
      child: RepliGoApp(),
    ),
  );
}
