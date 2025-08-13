import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app/app.dart';

Future<void> main() async {
  // Load the .env file
  await dotenv.load(fileName: ".env");
  // Ensure that widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
