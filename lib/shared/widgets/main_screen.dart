import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class MainScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _isBottomBarVisible = true;
  // Define your icons
  final iconList = <IconData>[
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.payment,
    Icons.person_rounded,
  ];

  void _onTap(int index) {
    if (index != 0) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        context.push('/login');
        return;
      }
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            if (notification.scrollDelta! > 0 && _isBottomBarVisible) {
              setState(() => _isBottomBarVisible = false);
            } else if (notification.scrollDelta! < 0 && !_isBottomBarVisible) {
              setState(() => _isBottomBarVisible = true);
            }
          }
          return false;
        },
        child: widget.navigationShell,
      ),
      floatingActionButton: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: _isBottomBarVisible ? 1.0 : 0.0,
        child: FloatingActionButton(
          heroTag: 'main_nav_fab',
          onPressed: () {
            final user = Supabase.instance.client.auth.currentUser;
            if (user == null) {
              context.push('/login');
              return;
            }
            context.push('/housemate-post');
          },
          backgroundColor: context.appColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isBottomBarVisible ? Offset.zero : const Offset(0, 1),
        child: AnimatedBottomNavigationBar(
          icons: iconList,
          activeIndex: widget.navigationShell.currentIndex,
          gapLocation: GapLocation.center,
          notchSmoothness: NotchSmoothness.softEdge,
          leftCornerRadius: 32,
          rightCornerRadius: 32,
          onTap: _onTap,
          activeColor: context.appColors.primary,
          inactiveColor: context.appColors.outlineVariant,
          backgroundColor: context.appColors.surfaceContainerLowest,
          elevation: 0,
          iconSize: 28,
          height: 70,
        ),
      ),
    );
  }
}
