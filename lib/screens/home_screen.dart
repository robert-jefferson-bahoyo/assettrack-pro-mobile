import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';
import 'manual_lookup_screen.dart';
import 'qr_scanner_screen.dart';
import 'asset_detail_screen.dart';
import 'recent_activity_screen.dart';
import 'assets_by_status_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  final String userName;
  final String userEmail;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoadingSummary = true;
  Map<String, dynamic> _summary = {};
  List<dynamic> _recentMovements = [];

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoadingSummary = true;
    });

    try {
      final data = await ApiService.getDashboardSummary();

      if (!mounted) return;

      setState(() {
        _summary = data['summary'] ?? {};
        _recentMovements = data['recent_movements'] ?? [];
        _isLoadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingSummary = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _count(String key) {
    final value = _summary[key];

    if (value == null) {
      return '0';
    }

    return value.toString();
  }

  Future<void> _logout() async {
    await ApiService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openScanner() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const QrScannerScreen()));

    if (mounted) {
      _loadSummary();
    }
  }

  Future<void> _openSearch() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ManualLookupScreen()));

    if (mounted) {
      _loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D6EFD);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AssetTrack Pro'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadSummary,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text(
                      'Scan QR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: _openScanner,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text(
                      'Search',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: _openSearch,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFE7F1FF),
                      child: Icon(
                        Icons.person_outline,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName.isNotEmpty
                                ? widget.userName
                                : 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.userEmail,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoadingSummary)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: [
                  _summaryCard(
                    title: 'Total Assets',
                    count: _count('total_assets'),
                    icon: Icons.inventory_2_outlined,
                    status: 'all',
                  ),
                  _summaryCard(
                    title: 'Assigned',
                    count: _count('assigned'),
                    icon: Icons.person_outline,
                    status: 'assigned',
                  ),
                  _summaryCard(
                    title: 'Available',
                    count: _count('available'),
                    icon: Icons.check_circle_outline,
                    status: 'available',
                  ),
                  _summaryCard(
                    title: 'Maintenance',
                    count: _count('maintenance'),
                    icon: Icons.build_outlined,
                    status: 'maintenance',
                  ),
                  _summaryCard(
                    title: 'Disposed',
                    count: _count('disposed'),
                    icon: Icons.delete_outline,
                    status: 'disposed',
                  ),
                  _summaryCard(
                    title: 'Lost',
                    count: _count('lost'),
                    icon: Icons.warning_amber_outlined,
                    status: 'lost',
                  ),
                ],
              ),

            const SizedBox(height: 20),

            _recentActivitySection(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _openMovementAsset(dynamic item) async {
    final code = item['qr_code']?.toString().trim().isNotEmpty == true
        ? item['qr_code'].toString()
        : item['asset_no']?.toString() ?? '';

    if (code.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asset code is missing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final asset = await ApiService.scanAsset(code);

      if (!mounted) return;

      final returned = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => AssetDetailScreen(asset: asset)),
      );

      if (returned == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asset returned successfully.')),
        );
      }

      if (mounted) {
        _loadSummary();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _recentActivitySection() {
    if (_recentMovements.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'No recent activity.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Activity',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecentActivityScreen(),
                      ),
                    );

                    if (mounted) {
                      _loadSummary();
                    }
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(height: 22),

            ..._recentMovements.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _openMovementAsset(item),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          child: Icon(Icons.history, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_movementText(item['movement_type'])} - ${_text(item['asset_name'])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Asset No: ${_text(item['asset_no'])}',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _text(item['movement_date']),
                                style: const TextStyle(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black38),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _movementText(dynamic value) {
    final text = _text(value);

    if (text == '-') {
      return 'UPDATED';
    }

    return text.toUpperCase();
  }

  String _text(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  Widget _summaryCard({
    required String title,
    required String count,
    required IconData icon,
    required String status,
  }) {
    const Color primaryColor = Color(0xFF0D6EFD);

    return InkWell(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AssetsByStatusScreen(title: title, status: status),
          ),
        );

        if (mounted) {
          _loadSummary();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.10),
                child: Icon(icon, color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
