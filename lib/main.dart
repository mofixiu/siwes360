import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:siwes360/theme/app_theme.dart';
import 'package:siwes360/utils/request.dart';
import 'package:siwes360/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

  await Hive.initFlutter();
  await RequestService.initialize();

  runApp(const SiwesApp());
}

class SiwesApp extends StatelessWidget {
  const SiwesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIWES360',
      theme: buildAppTheme(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
