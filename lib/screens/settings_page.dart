import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todocart/provider/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://github.com/reddevil212');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          //ACCOUNT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              "Account",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.person, color: colors.onSurfaceVariant),
            title: const Text("Profile"),
            subtitle: const Text("Edit your profile"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const SizedBox(height: 10),

          // APPEARANCE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              "Appearance",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),

          SwitchListTile(
            value: themeProvider.isDarkMode,
            onChanged: (val) {
              themeProvider.toggleTheme(val);
            },
            secondary: Icon(Icons.dark_mode, color: colors.onSurfaceVariant),
            title: const Text("Dark Mode"),
          ),

          const SizedBox(height: 10),

          // NOTIFICATIONS
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              "Notifications (Experimental)",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),

          SwitchListTile(
            value: false,
            onChanged: (val) {},
            secondary: Icon(
              Icons.notifications,
              color: colors.onSurfaceVariant,
            ),
            title: const Text("Push Notifications"),
          ),

          const SizedBox(height: 10),

          //ABOUT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Text(
              "About",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.primary,
              ),
            ),
          ),

          ListTile(
            leading: Icon(Icons.info, color: colors.onSurfaceVariant),
            title: const Text("About App"),
            subtitle: const Text("Version 1.0.0"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          ListTile(
            leading: Icon(Icons.description, color: colors.onSurfaceVariant),
            title: const Text("Terms & Conditions"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const SizedBox(height: 40),

          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  children: [
                    const TextSpan(text: "Made with ❤️ by "),
                    TextSpan(
                      text: 'reddevil212',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()..onTap = _launchURL,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
