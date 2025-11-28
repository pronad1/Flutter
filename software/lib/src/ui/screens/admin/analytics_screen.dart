// lib/src/ui/screens/admin/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/chatbot/chatbot_wrapper.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatbotWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics Dashboard'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
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
              int donors = 0;
              int seekers = 0;
              int approvedUsers = 0;
              int pendingUsers = 0;

              for (var user in users) {
                final data = user.data() as Map<String, dynamic>;
                final role = (data['role'] ?? '').toString().toLowerCase();
                final approved = data['approved'] as bool? ?? false;

                if (role == 'donor') donors++;
                if (role == 'seeker') seekers++;
                if (approved) {
                  approvedUsers++;
                } else {
                  pendingUsers++;
                }
              }

              int totalItems = items.length;
              int availableItems = 0;
              int requestedItems = 0;

              for (var item in items) {
                final data = item.data() as Map<String, dynamic>;
                final status = (data['status'] ?? 'available').toString().toLowerCase();
                if (status == 'available') availableItems++;
                if (status == 'requested') requestedItems++;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Cards
                    const Text(
                      'Overview',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildOverviewGrid(
                      totalUsers,
                      totalItems,
                      approvedUsers,
                      pendingUsers,
                    ),
                    const SizedBox(height: 32),

                    // User Distribution
                    const Text(
                      'User Distribution',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 200,
                              child: _buildPieChart(donors, seekers),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem(Colors.green, 'Donors', donors),
                                const SizedBox(width: 24),
                                _buildLegendItem(Colors.orange, 'Seekers', seekers),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Item Status
                    const Text(
                      'Item Status',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          height: 250,
                          child: _buildBarChart(availableItems, requestedItems),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // User Approval Status
                    const Text(
                      'User Approval Status',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Approved',
                            approvedUsers,
                            Colors.green,
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Pending',
                            pendingUsers,
                            Colors.orange,
                            Icons.pending,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        ),
        ),
      ),
    );
  }

  Widget _buildOverviewGrid(int users, int items, int approved, int pending) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4, // Adjusted from 1.5 to prevent overflow
      children: [
        _buildStatCard('Total Users', users, Colors.blue, Icons.people),
        _buildStatCard('Total Items', items, Colors.purple, Icons.inventory),
        _buildStatCard('Approved', approved, Colors.green, Icons.check_circle),
        _buildStatCard('Pending', pending, Colors.orange, Icons.hourglass_bottom),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12), // Reduced from 16
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
          mainAxisSize: MainAxisSize.min, // Added to prevent overflow
          children: [
            Icon(icon, color: color, size: 36), // Reduced from 40
            const SizedBox(height: 6), // Reduced from 8
            Flexible( // Wrapped in Flexible
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 28, // Reduced from 32
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2), // Reduced from 4
            Flexible( // Wrapped in Flexible
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, // Reduced from 14
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(int donors, int seekers) {
    // Prevent division by zero
    if (donors == 0 && seekers == 0) {
      return const Center(
        child: Text('No user data available', style: TextStyle(color: Colors.grey)),
      );
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(
            value: donors.toDouble(),
            title: donors.toString(),
            color: Colors.green,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: seekers.toDouble(),
            title: seekers.toString(),
            color: Colors.orange,
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(int available, int requested) {
    final maxValue = (available > requested ? available : requested).toDouble();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue + (maxValue * 0.2), // Add 20% padding
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toInt().toString(),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Available', style: TextStyle(fontSize: 12)),
                    );
                  case 1:
                    return const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Requested', style: TextStyle(fontSize: 12)),
                    );
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue > 0 ? maxValue / 5 : 1,
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: available.toDouble(),
                color: Colors.green,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: requested.toDouble(),
                color: Colors.orange,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, int value) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
