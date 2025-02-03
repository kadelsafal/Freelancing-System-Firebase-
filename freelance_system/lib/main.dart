import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freelance_system/firebase_options.dart';
import 'package:freelance_system/providers/userProvider.dart';
import 'package:freelance_system/screens/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(ChangeNotifierProvider(
      create: (context) {
        return Userprovider();
      },
      child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            textTheme: GoogleFonts.poppinsTextTheme()),
        home: SplashScreen());
  }
}
