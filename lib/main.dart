import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:launch_at_startup/launch_at_startup.dart";
import "package:package_info_plus/package_info_plus.dart";

import "app/app.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    packageName: "com.qbitsinc.printer_manager",
  );
  try {
  await launchAtStartup.enable();

  } catch (e) {
    print(e);
  }
  // Load the .env file
  await dotenv.load(fileName: ".env");
  // Ensure that widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
