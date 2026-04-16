import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'l10n/app_localizations.dart';
import 'presentation/providers/shopping_list_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/finance_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_container_screen.dart';

Future<void> main() async {
  // Load .env file
  await dotenv.load(fileName: ".env");

  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, FinanceProvider>(
          create: (_) => FinanceProvider(),
          update: (_, auth, financeProvider) =>
              financeProvider!..updateContext(auth.userId),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, FinanceProvider,
            ShoppingListProvider>(
          create: (_) => ShoppingListProvider(),
          update: (_, auth, finance, shoppingListProvider) =>
              shoppingListProvider!
                ..setFinanceProvider(finance)
                ..update(auth.userId, auth.token),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return MaterialApp(
            title: 'Nickas App',
            debugShowCheckedModeBanner: false,

            // Theme Section
            // Theme Section
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                primary: const Color(0xFF6200EE),
                secondary: const Color(0xFF03DAC6),
                background: const Color(0xFFF5F5F7), // Light Grayish
                surface: Colors.white,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.transparent, // Modern Look
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                iconTheme: IconThemeData(color: Colors.black87),
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                surfaceTintColor: Colors.white,
              ),
              scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.deepPurple,
                brightness: Brightness.dark,
                primary: const Color(0xFFBB86FC),
                secondary: const Color(0xFF03DAC6),
                surface: const Color(0xFF1E1E2C),
                background: const Color(0xFF121212),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
              ),
              cardTheme: CardThemeData(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFF2C2C3E), // Dark Card
                surfaceTintColor: const Color(0xFF2C2C3E),
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
            ),
            themeMode: themeProvider.themeMode,

            // Localization
            locale: languageProvider.locale,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [const Locale('en'), const Locale('pt')],

            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return auth.isAuthenticated
                    ? const MainContainerScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
