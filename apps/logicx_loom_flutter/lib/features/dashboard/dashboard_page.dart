import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api/logicx_loom_api.dart';
import 'loom_data_page.dart';
import 'messages_sample_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    required this.api,
    required this.session,
    required this.onSignOut,
    super.key,
  });

  final LogicXLoomApi api;
  final UserSession session;
  final VoidCallback onSignOut;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) => Theme(
    data: _dashboardTheme,
    child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/logo.svg',
              height: 28,
              width: 34,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 9),
            const Text('LogicX Loom'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Account',
            icon: CircleAvatar(
              child: Text(
                widget.session.profile.name.characters.first.toUpperCase(),
              ),
            ),
            onSelected: (value) {
              if (value == 'sign-out') widget.onSignOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.session.profile.name),
                    Text(
                      widget.session.profile.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'sign-out', child: Text('Sign out')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          LoomDataPageView(api: widget.api, session: widget.session),
          MessagesSamplePage(
            api: widget.api,
            session: widget.session,
            embedded: true,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Messenger',
          ),
        ],
      ),
    ),
  );

  ThemeData get _dashboardTheme => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      brightness: Brightness.light,
      seedColor: const Color(0xFF305DDD),
      primary: const Color(0xFF305DDD),
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardTheme: const CardThemeData(color: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF305DDD),
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Color(0xFFE8EEFF),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD7DEEA)),
      ),
    ),
    useMaterial3: true,
  );
}
