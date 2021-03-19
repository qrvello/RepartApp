import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseDatabase().setPersistenceEnabled(true);
  FirebaseDatabase().setPersistenceCacheSizeBytes(10000000);

  runApp(MyApp());
}
