import 'package:flutter/material.dart';
import 'booking_screen.dart';
import 'wallet_screen.dart';
import 'history_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    BookingScreen(),
    WalletScreen(),
    HistoryScreen(),
  ];

  final List<String> _pageTitles = const [
    'Booking',
    'Wallet',
    'History',
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      /// ---- APP BAR ----
      appBar: _buildAppBar(),

      /// ---- BODY ----
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      /// ---- FLOATING BOTTOM NAV ----
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
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ---- APP BAR ----
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 6,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.08),
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
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xff0095FF),
            child: IconButton(
              icon: const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                // TODO: Navigate to profile
              },
            ),
          ),
        ),
      ],
    );
  }
}
