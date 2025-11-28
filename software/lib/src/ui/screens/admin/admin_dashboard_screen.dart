// lib/src/ui/screens/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/chatbot/chatbot_wrapper.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatbotWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('items').snapshots(),
            builder: (context, itemSnapshot) {
              if (!itemSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = userSnapshot.data!.docs;
              final items = itemSnapshot.data!.docs;

              // Calculate statistics
              int totalUsers = users.length;
              int pendingUsers = 0;
              int totalItems = items.length;
              int availableItems = 0;

              for (var user in users) {
                final data = user.data() as Map<String, dynamic>;
                final approved = data['approved'] as bool? ?? false;
                if (!approved) pendingUsers++;
              }

              for (var item in items) {
                final data = item.data() as Map<String, dynamic>;
                final status = (data['status'] ?? 'available').toString().toLowerCase();
                if (status == 'available') availableItems++;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade900],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                                SizedBox(width: 12),
                                Text(
                                  'Admin Control Center',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage your donation system',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Stats
                    const Text(
                      'Quick Overview',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          'Total Users',
                          totalUsers.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Pending Approvals',
                          pendingUsers.toString(),
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Total Items',
                          totalItems.toString(),
                          Icons.inventory,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Available Items',
                          availableItems.toString(),
                          Icons.check_circle,
                          Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Admin Actions
                    const Text(
                      'System Controls',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      context,
                      'User Approvals',
                      'Review and approve pending users',
                      Icons.people_alt,
                      Colors.blue,
                      '/admin-approval',
                      badge: pendingUsers > 0 ? pendingUsers.toString() : null,
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      'Manage Users',
                      'View, edit, and manage all users',
                      Icons.manage_accounts,
                      Colors.orange,
                      '/manage-users',
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      'All Items',
                      'View and manage all donation items',
                      Icons.inventory_2,
                      Colors.green,
                      '/all-items',
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context,
                      'Analytics',
                      'View system statistics and reports',
                      Icons.analytics,
                      Colors.purple,
                      '/analytics',
                    ),
                  ],
                ),
              );
            },
          );
        },
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route, {
    String? badge,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(icon, color: color, size: 28)),
                    if (badge != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
