import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/app_feedback.dart';
import 'booking_screen.dart';
import 'bookings_screen.dart';
import 'change_password_screen.dart';
import 'loginscreen.dart';
import 'wallet_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final int initialTab;

  const CustomerHomeScreen({super.key, this.initialTab = 0});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  late int _selectedIndex;
  final GlobalKey<BookingsScreenState> _bookingsKey =
      GlobalKey<BookingsScreenState>();
  final GlobalKey<WalletScreenState> _walletKey =
      GlobalKey<WalletScreenState>();

  late final List<Widget> _pages;

  final List<String> _pageTitles = const ['Booking', 'Wallet', 'Bookings'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab.clamp(0, 2).toInt();
    _pages = [
      const BookingScreen(),
      WalletScreen(key: _walletKey),
      BookingsScreen(key: _bookingsKey),
    ];
    if (_selectedIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bookingsKey.currentState?.loadBookings();
      });
    }
  }

  void refreshBookings() {
    _bookingsKey.currentState?.loadBookings();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      if (index == 1) {
        _walletKey.currentState?.refreshWallet();
      }
      if (index == 2) {
        refreshBookings();
      }
      return;
    }
    setState(() => _selectedIndex = index);
    if (index == 1) {
      _walletKey.currentState?.refreshWallet();
    }
    if (index == 2) {
      refreshBookings();
    }
  }

  Future<void> _logout() async {
    final confirmed = await showAppConfirmationDialog(
      context,
      title: 'Log out',
      message: 'Are you sure you want to log out of this account?',
      confirmLabel: 'Log out',
      isDanger: true,
    );

    if (!confirmed || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_car_wash_outlined),
            selectedIcon: Icon(Icons.local_car_wash),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Dashboard', style: textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            _pageTitles[_selectedIndex],
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Account options',
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'change_password') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              );
            } else if (value == 'logout') {
              _logout();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'change_password',
              child: Row(
                children: [
                  Icon(Icons.lock_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Change Password'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: colorScheme.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
