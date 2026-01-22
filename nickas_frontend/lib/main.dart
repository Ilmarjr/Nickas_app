import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/shopping_list_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';

void main() {
  if (Platform.isWindows || Platform.isLinux) {
    // Initialize FFI
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
        ChangeNotifierProxyProvider<AuthProvider, ShoppingListProvider>(
          create: (_) => ShoppingListProvider(),
          update: (_, auth, shoppingListProvider) =>
              shoppingListProvider!..update(auth.userId, auth.token),
        ),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return MaterialApp(
            title: 'Nickas App',
            debugShowCheckedModeBanner: false,
            // ... Theme configurations ...
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue, // More sky-like base
                secondary: Colors.amber, // Complementary for actions
                background: Colors.grey.shade50,
                surface: Colors.white,
              ),
              appBarTheme: AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor:
                    Colors.blue.shade50, // Subtle sky blue for all AppBars
                surfaceTintColor: Colors.transparent, // Avoid M3 mixing color
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              fontFamily: 'Roboto',
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
                secondary: Colors.amber,
                surface: const Color(
                  0xFF1E1E2C,
                ), // Darker blue-ish grey surface
                background: const Color(0xFF121212),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Color(0xFF2E3B55), // Dark Blue Grey
                surfaceTintColor: Colors.transparent,
              ),
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
            supportedLocales: [
              const Locale('en'), // English
              const Locale('pt'), // Portuguese
            ],

            home: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return auth.isAuthenticated
                    ? const HomeScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
