import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'asset_detail_screen.dart';

class AssetsByStatusScreen extends StatefulWidget {
  const AssetsByStatusScreen({
    super.key,
    required this.title,
    required this.status,
  });

  final String title;
  final String status;

  @override
  State<AssetsByStatusScreen> createState() => _AssetsByStatusScreenState();
}

class _AssetsByStatusScreenState extends State<AssetsByStatusScreen> {
  bool _isLoading = true;
  List<dynamic> _assets = [];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final assets = await ApiService.getAssetsByStatus(widget.status);

      if (!mounted) return;

      setState(() {
        _assets = assets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.friendlyError(e)),
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

        await _loadAssets();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.friendlyError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _text(dynamic value) {
    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String _value(dynamic item, String key) {
    final value = item[key];

    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  String _employeeDisplay(dynamic item) {
    final employee = _value(item, 'assigned_employee');
    final status = _value(item, 'current_status').toLowerCase();

    if (employee != '-') {
      return employee;
    }

    if (status == 'assigned') {
      return 'No employee assigned';
    }

    return '-';
  }

  String _displayStatus(dynamic item) {
    final status = _value(item, 'current_status').toLowerCase();
    final employee = _value(item, 'assigned_employee');

    if (status == 'assigned' && employee == '-') {
      return 'Assigned to Office';
    }

    if (status == 'assigned' && employee != '-') {
      return 'Assigned to Employee';
    }

    switch (status) {
      case 'available':
        return 'Available';
      case 'maintenance':
        return 'Maintenance';
      case 'disposed':
        return 'Disposed';
      case 'lost':
        return 'Lost';
      default:
        return _value(item, 'current_status');
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'assigned':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'disposed':
        return Colors.grey;
      case 'lost':
        return Colors.red;
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D6EFD);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAssets,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssets,
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : _assets.isEmpty
            ? ListView(
          padding: EdgeInsets.all(24),
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('No assets found.'),
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _assets.length,
          itemBuilder: (context, index) {
            final item = _assets[index];
            final rawStatus = _text(item['current_status']);
            final displayStatus = _displayStatus(item);

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                title: Text(
                  _text(item['asset_name']),
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
                      Text(
                        'Property No: ${_text(item['property_no'])}',
                      ),
                      Text(
                        'Employee: ${_employeeDisplay(item)}',
                      ),
                      Text(
                        'Office: ${_text(item['current_office'])}',
                      ),
                      Text(
                        'Department: ${_text(item['current_department'])}',
                      ),
                    ],
                  ),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(rawStatus).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayStatus.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(rawStatus),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                onTap: () => _openAsset(item),
              ),
            );
          },
        ),
      ),
    );
  }
}