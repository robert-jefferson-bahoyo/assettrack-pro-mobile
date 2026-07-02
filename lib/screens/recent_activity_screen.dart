import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'asset_detail_screen.dart';

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  bool _isLoading = true;
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await ApiService.getRecentActivity();

      if (!mounted) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openAsset(dynamic item) async {
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
        MaterialPageRoute(
          builder: (_) => AssetDetailScreen(asset: asset),
        ),
      );

      if (returned == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asset returned successfully.'),
          ),
        );

        await _loadActivity();
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

  String _text(dynamic value) {
    if (value == null) return '-';

    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String _movementText(dynamic value) {
    final text = _text(value);
    return text == '-' ? 'UPDATED' : text.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D6EFD);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Activity'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadActivity,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivity,
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _items.isEmpty
            ? ListView(
          padding: EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No recent activity.'),
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: const CircleAvatar(
                  child: Icon(Icons.history),
                ),
                title: Text(
                  '${_movementText(item['movement_type'])} - ${_text(item['asset_name'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asset No: ${_text(item['asset_no'])}'),
                      Text(_text(item['movement_date'])),
                      if (_text(item['remarks']) != '-')
                        Text('Remarks: ${_text(item['remarks'])}'),
                    ],
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openAsset(item),
              ),
            );
          },
        ),
      ),
    );
  }
}