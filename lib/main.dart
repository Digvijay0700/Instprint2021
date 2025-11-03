import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/register_page.dart';
import 'screens/file_upload_page.dart';
import 'screens/group_feature_page.dart';
import 'screens/track_orders_page.dart';

import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InstPrint App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.amber),

      // Start directly on login page
      home: const LoginPage(),

      routes: {
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/uploadFile': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
          final shopId = args['shopId'] ?? 'default_shop_id';
          return UploadFilePage(shopId: shopId);
        },
        '/groupFeature': (context) => const GroupFeaturePage(),
        '/orders': (context) => const TrackOrdersPage(),
      },
    );
  }
}
