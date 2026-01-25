import 'package:flutter/material.dart';
import 'booking_screen.dart';
import 'wallet_screen.dart';
import 'bookings_screen.dart';
import 'change_password_screen.dart';
import 'loginscreen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final int initialTab;
  
  const CustomerHomeScreen({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {

  late int _selectedIndex;
  final GlobalKey<BookingsScreenState> _bookingsKey = GlobalKey<BookingsScreenState>();

  late final List<Widget> _pages;

  final List<String> _pageTitles = const [
    'Booking',
    'Wallet',
    'Bookings',
  ];

  final GlobalKey<WalletScreenState> _walletKey = GlobalKey<WalletScreenState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _pages = [
      BookingScreen(),
      WalletScreen(key: _walletKey),
      BookingsScreen(key: _bookingsKey),
    ];
    if (widget.initialTab == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_bookingsKey.currentState != null) {
          _bookingsKey.currentState!.loadBookings();
        }
      });
    }
  }

  void refreshBookings() {
    if (_bookingsKey.currentState != null) {
      _bookingsKey.currentState!.loadBookings();
    }
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) {
      if (index == 1 && _walletKey.currentState != null) {
        _walletKey.currentState!.refreshWallet();
      }
      if (index == 2) {
        refreshBookings();
      }
      return;
    }
    setState(() => _selectedIndex = index);
    if (index == 1 && _walletKey.currentState != null) {
      _walletKey.currentState!.refreshWallet();
    }
    if (index == 2) {
      refreshBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xff0095FF),
              unselectedItemColor: Colors.grey[500],
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_car_wash),
                  label: 'Booking',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet),
                  label: 'Wallet',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Bookings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 6,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
      automaticallyImplyLeading: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _pageTitles[_selectedIndex],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'change_password') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              );
            } else if (value == 'logout') {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
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
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
            ),
          ),
          ],
        ),
      ],
    );
  }
}
