import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../style/style.dart'; // your styles like head1Text, colors, etc.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Profile data, initially null except email fetched from FirebaseAuth
  String? profilePicUrl;
  String? name;
  String? mobile;
  String? address;
  late String email;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    email = user?.email ?? 'No Email';
    // name, mobile, address, profilePicUrl remain null initially
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
      successToast('Logged out successfully!');
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // Logout tapped
      _logout();
    } else {
      setState(() {
        _selectedIndex = index >= 1 ? index - 1 : index;
      });
    }
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: profilePicUrl != null
                ? NetworkImage(profilePicUrl!)
                : const AssetImage('assets/images/default_avatar.png')
            as ImageProvider,
          ),
          const SizedBox(height: 20),
          _buildProfileRow('Name', name),
          _buildProfileRow('Email', email),
          _buildProfileRow('Mobile', mobile),
          _buildProfileRow('Address', address),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: head6Text(colorGreen),
          ),
          Expanded(
            child: Text(
              value ?? 'Not set',
              style: head6Text(colorDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateProfileTab() {
    return Center(child: Text('Update Profile Screen', style: head1Text(colorGreen)));
  }

  Widget _buildFreeProductsTab() {
    return Center(child: Text('Free Products Screen', style: head1Text(colorBlue)));
  }

  Widget _buildExchangeProductsTab() {
    return Center(child: Text('Exchange Products Screen', style: head1Text(colorOrange)));
  }

  @override
  Widget build(BuildContext context) {
    // Tabs except Logout (Logout handled via nav bar tap)
    final tabs = [
      _buildProfileTab(),
      _buildUpdateProfileTab(),
      _buildFreeProductsTab(),
      _buildExchangeProductsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Reuse Hub', style: head6Text(colorWhite)),
        backgroundColor: colorGreen,
        centerTitle: true,
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex < 1 ? _selectedIndex : _selectedIndex + 1,
        selectedItemColor: colorGreen,
        unselectedItemColor: colorLightGray,
        onTap: (index) {
          if (index == 1) {
            // Logout
            _logout();
          } else if (index > 1) {
            _onItemTapped(index - 1);
          } else {
            _onItemTapped(index);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Update Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Free Products'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Exchange Products'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud_upload), label: 'Upload Product'),
        ],
      ),
    );
  }
}
