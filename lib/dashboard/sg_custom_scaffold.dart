import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:smart_grow_code/auth/app_user.dart';
import 'package:smart_grow_code/auth/auth_service.dart';
import 'package:smart_grow_code/dashboard/other_features_barrel.dart';
import 'package:smart_grow_code/iot_screens/sensor_test_screen.dart';

class SgCustomScaffold extends StatefulWidget {
  final String title;
  final Widget bodyContent;

  const SgCustomScaffold({
    super.key,
    required this.title,
    required this.bodyContent,
  });

  @override
  State<SgCustomScaffold> createState() => _SgCustomScaffoldState();
}

class _SgCustomScaffoldState extends State<SgCustomScaffold> {
  bool isDrawerOpen = false;

  void toggleDrawer() {
    setState(() {
      isDrawerOpen = !isDrawerOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          ///  MAIN CONTENT (SWITCHES TO DASHBOARD WHEN OPEN)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: isDrawerOpen ? width * 0.35 : 0,
            top: isDrawerOpen ? 40 : 0,
            bottom: isDrawerOpen ? 40 : 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isDrawerOpen ? width * 0.65 : width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: isDrawerOpen
                    ? BorderRadius.circular(25)
                    : BorderRadius.circular(0),
                boxShadow: isDrawerOpen
                    ? [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ]
                    : [],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: toggleDrawer,
                        ),
                        Text(
                          widget.title,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),

                    Expanded(
                      child: isDrawerOpen
                          ? const SmartGrowDashboard()
                          : widget.bodyContent,
                    ),
                  ],
                ),
              ),
            ),
          ),

          ///  BLUR BACKGROUND (OPTIONAL)
          if (isDrawerOpen)
            GestureDetector(
              onTap: toggleDrawer,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),

          /// DRAWER (MENU)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: isDrawerOpen ? 0 : -width * 0.65,
            top: 0,
            bottom: 0,
            child: Material(
              elevation: 20,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
              child: Container(
                width: width * 0.65,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: AppDrawer(onClose: toggleDrawer),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///  DRAWER CONTENT
class AppDrawer extends StatelessWidget {
  final VoidCallback onClose;

  const AppDrawer({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const DrawerHeader(
          decoration: BoxDecoration(color: Color(0xFFB88A5A)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/adhika_logo.jpg'),
              ),
              SizedBox(height: 7),
              Text(
                'Smart Grow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        /// HOME (just close drawer, already dashboard in background)
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('Home'),
          onTap: () {
            onClose();
          },
        ),

        ListTile(
          leading: const Icon(Icons.sensors),
          title: const Text('Sensor Data Test'),
          onTap: () {
            onClose();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SensorTestScreen()),
            );
          },
        ),

        FutureBuilder<AppUser>(
          future: AuthService.currentAppUser(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            if (user == null || !user.isAdmin) {
              return const SizedBox.shrink();
            }

            return ListTile(
              leading: const Icon(Icons.manage_accounts),
              title: const Text('User Management'),
              onTap: () {
                onClose();
                Navigator.pushNamed(context, '/admin/users');
              },
            );
          },
        ),

        /// LOGS
        ListTile(
          leading: const Icon(Icons.library_books_rounded),
          title: const Text('Logs'),
          onTap: () {
            onClose();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogBookScreen()),
            );
          },
        ),

        /// GUIDES
        ListTile(
          leading: const Icon(Icons.list_alt_rounded),
          title: const Text('Guides'),
          onTap: () {
            onClose();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuidesScreen()),
            );
          },
        ),

        /// SETTINGS
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            onClose();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),

        /// CONTACT
        ListTile(
          leading: const Icon(Icons.phone),
          title: const Text('Contact Us'),
          onTap: () {
            onClose();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactUsScreen()),
            );
          },
        ),

        /// LOGOUT
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () async {
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Confirm Logout"),
                content: const Text("Are you sure you want to log out?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );

            if (shouldLogout == true) {
              await AuthService.signOut();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            }
          },
        ),
      ],
    );
  }
}
