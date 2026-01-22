import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader(context, l10n.theme),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.themeSystem),
                    value: ThemeMode.system,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setThemeMode(value!),
                    secondary: const Icon(Icons.brightness_auto),
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.themeLight),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setThemeMode(value!),
                    secondary: const Icon(Icons.brightness_5),
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text(l10n.themeDark),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setThemeMode(value!),
                    secondary: const Icon(Icons.brightness_2),
                  ),
                ],
              );
            },
          ),
          
          const Divider(),
          _buildSectionHeader(context, l10n.language), // "Idioma" vs "Language"
          Consumer<LanguageProvider>(
            builder: (context, langProvider, child) {
              return Column(
                children: [
                   RadioListTile<Locale>(
                    title: const Text('Português (BR)'),
                    value: const Locale('pt'),
                    groupValue: langProvider.locale,
                    onChanged: (value) => langProvider.setLocale(value!),
                    secondary: const Text('🇧🇷', style: TextStyle(fontSize: 24)),
                  ),
                  RadioListTile<Locale>(
                    title: const Text('English (US)'),
                    value: const Locale('en'),
                    groupValue: langProvider.locale,
                    onChanged: (value) => langProvider.setLocale(value!),
                    secondary: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                  ),
                ],
              );
            },
          ),
           
          const Divider(),
          _buildSectionHeader(context, 'Conta'), // TODO: add to arb
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logout, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.logoutConfirmTitle),
                  content: Text(l10n.logoutConfirmMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pop(context); // Close settings
              }
            },
          ),
          
           const Divider(),
           Center(
             child: Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text(
                 'Nickas App v1.0.0',
                 style: TextStyle(color: Colors.grey[500], fontSize: 12),
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
