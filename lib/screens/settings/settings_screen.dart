import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/app_theme.dart';
import '../auth/login_screen.dart';
import '../../services/google_auth_service.dart';
import 'tradebook_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // User info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Text(
                      (authProvider.userName ?? 'U')
                        .substring(0, 1)
                        .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment:
                      CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.userName ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        authProvider.userEmail ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Appearance section
          Text(
            'APPEARANCE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: Text(
                themeProvider.isDarkMode
                  ? 'Dark theme enabled'
                  : 'Light theme enabled',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              secondary: Icon(
                themeProvider.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
                color: AppTheme.primaryBlue,
              ),
              value: themeProvider.isDarkMode,
              onChanged: (_) =>
                themeProvider.toggleTheme(),
              activeColor: AppTheme.primaryBlue,
            ),
          ),

        const SizedBox(height: 24),

          // Tradebook section
          Text(
            'ACTIVITY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.receipt_long_outlined,
                color: AppTheme.primaryBlue,
              ),
              title: const Text('Tradebook'),
              subtitle: const Text(
                'Buy and sell history'),
              trailing: const Icon(
                Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                    const TradebookScreen()),
              ),
            ),
          ),


          const SizedBox(height: 24),

          // About section
          Text(
            'ABOUT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('App Version'),
                  trailing: Text(
                    '1.0.0',
                    style: TextStyle(
                      color: Colors.grey[600]),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.school_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Project'),
                  trailing: Text(
                    'MCA Final Year',
                    style: TextStyle(
                      color: Colors.grey[600]),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryBlue,
                  ),
                  title: const Text('Developer'),
                  trailing: Text(
                    'Santhosh',
                    style: TextStyle(
                      color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout button
          ElevatedButton.icon(
            onPressed: () async {
            await GoogleAuthService.signOut();
            await context
              .read<AuthProvider>()
              .logout();
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => LoginScreen()),
              (route) => false,
            );
          },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}