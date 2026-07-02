import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({super.key, required this.asset});

  final Map<String, dynamic> asset;

  String _value(String key) {
    final value = asset[key];

    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
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

  Future<void> _returnAsset(BuildContext context) async {
    final rawId = asset['id'];

    if (rawId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asset ID is missing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final int assetId = int.parse(rawId.toString());
    String remarksInput = '';

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Return Asset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Are you sure you want to return this asset?'),
                const SizedBox(height: 14),
                TextField(
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  onChanged: (value) {
                    remarksInput = value;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Remarks',
                    hintText: 'Optional remarks',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(dialogContext).unfocus();
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                FocusScope.of(dialogContext).unfocus();
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Return'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final remarks = remarksInput.trim().isEmpty
        ? 'Asset returned using mobile scanner.'
        : remarksInput.trim();

    if (!context.mounted) return;

    FocusManager.instance.primaryFocus?.unfocus();

    await Future.delayed(const Duration(milliseconds: 250));

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Expanded(child: Text('Returning asset...')),
            ],
          ),
        );
      },
    );

    try {
      await ApiService.returnAsset(assetId: assetId, remarks: remarks);

      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D6EFD);

    final String assetName = _value('asset_name');
    final String assetNo = _value('asset_no');
    final String status = _value('current_status');

    final List<dynamic> movements = asset['movements'] is List
        ? asset['movements'] as List<dynamic>
        : [];

    final bool canReturn = status.toLowerCase() == 'assigned';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asset Details'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canReturn)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _returnAsset(context),
                    icon: const Icon(Icons.assignment_return_outlined),
                    label: const Text('Return Asset'),
                  ),
                ),

              if (canReturn) const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scan Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Back to Home'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assetName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(assetNo, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          _section(
            title: 'Asset Information',
            children: [
              _row('Asset No', _value('asset_no')),
              _row('Property No', _value('property_no')),
              _row('QR Code', _value('qr_code')),
              _row('Category', _value('category')),
              _row('Brand', _value('brand')),
              _row('Model', _value('model')),
              _row('Serial No', _value('serial_no')),
              _row('Description', _value('description')),
            ],
          ),

          _section(
            title: 'Status and Cost',
            children: [
              _row('Current Status', _value('current_status')),
              _row('Condition', _value('condition_status')),
              _row('Acquisition Date', _value('acquisition_date')),
              _row('Acquisition Cost', _value('acquisition_cost')),
            ],
          ),

          _section(
            title: 'Current Assignment',
            children: [
              _row('Office', _value('current_office')),
              _row('Department', _value('current_department')),
              _row('Employee', _value('assigned_employee')),
            ],
          ),

          _section(
            title: 'Owning / Return Office',
            children: [
              _row('Owning Office', _value('owning_office')),
              _row('Owning Department', _value('owning_department')),
              _row('Return Office', _value('return_office')),
              _row('Return Department', _value('return_department')),
            ],
          ),

          _section(title: 'Remarks', children: [Text(_value('remarks'))]),
          if (movements.isNotEmpty)
            _section(
              title: 'Movement History',
              children: movements.map((movement) {
                final item = movement as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE1E5EA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item['movement_type'] ?? '-').toString().toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['movement_date']?.toString() ?? '-',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['remarks']?.toString().trim().isNotEmpty == true
                            ? item['remarks'].toString()
                            : 'No remarks.',
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 135,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
