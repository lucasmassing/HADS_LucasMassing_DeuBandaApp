import 'package:deubanda_app/viewmodels/notificacao_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/login_page.dart';
import 'viewmodels/profile_viewmodel.dart';
import 'viewmodels/projeto_viewmodel.dart';
import 'viewmodels/matching_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    // Injeta o ViewModel na raiz do App
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => ProjetoViewModel()),
        ChangeNotifierProvider(create: (_) => MatchingViewModel()),
        ChangeNotifierProvider(create: (_) => NotificacaoViewModel()),
      ],
      child: const DeuBandaApp(),
    ),
  );
}

class DeuBandaApp extends StatelessWidget {
  const DeuBandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeuBanda App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}