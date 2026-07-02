import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AssetDetailScreen extends StatelessWidget {
  const AssetDetailScreen({
    super.key,
    required this.asset,
  });

  final Map<String, dynamic> asset;

  String _value(String key) {
    final value = asset[key];

    if (value == null) {
      return '-';
    }

    final text = value.toString().trim();
    return text.isEmpty ? '-' : text;
  }

  bool _hasValue(String key) {
    return _value(key) != '-';
  }

  String _employeeDisplay() {
    final employee = _value('assigned_employee');
    final status = _value('current_status').toLowerCase();

    if (employee != '-') {
      return employee;
    }

    if (status == 'assigned') {
      return 'No employee assigned';
    }

    return '-';
  }

  String _displayStatus() {
    final status = _value('current_status').toLowerCase();
    final employee = _value('assigned_employee');

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
        return _value('current_status');
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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Icons.check_circle_outline;
      case 'assigned':
        return Icons.person_outline;
      case 'maintenance':
        return Icons.build_outlined;
      case 'disposed':
        return Icons.delete_outline;
      case 'lost':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
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
            ElevatedButton.icon(
              onPressed: () {
                FocusScope.of(dialogContext).unfocus();
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text('Return'),
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

    await Future.delayed(const Duration(milliseconds: 200));

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
              Expanded(
                child: Text('Returning asset...'),
              ),
            ],
          ),
        );
      },
    );

    try {
      await ApiService.returnAsset(
        assetId: assetId,
        remarks: remarks,
      );

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
    final String displayStatus = _displayStatus();
    final String condition = _value('condition_status');

    final List<dynamic> movements = asset['movements'] is List
        ? asset['movements'] as List<dynamic>
        : [];

    final bool canReturn = status.toLowerCase() == 'assigned';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Asset Details'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canReturn)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _returnAsset(context),
                    icon: const Icon(Icons.assignment_return_outlined),
                    label: const Text(
                      'Return Asset',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              if (canReturn) const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).popUntil(
                                (route) => route.isFirst,
                          );
                        },
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Home'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _headerCard(
            assetName: assetName,
            assetNo: assetNo,
            status: status,
            displayStatus: displayStatus,
            condition: condition,
          ),

          const SizedBox(height: 12),

          _quickInfoGrid(),

          const SizedBox(height: 12),

          _section(
            title: 'Asset Information',
            icon: Icons.inventory_2_outlined,
            children: [
              _row('Asset No', _value('asset_no')),
              _row('Property No', _value('property_no')),
              _row('QR Code', _value('qr_code')),
              _row('Category', _value('category')),
              _row('Brand', _value('brand')),
              _row('Model', _value('model')),
              _row('Serial No', _value('serial_no')),
              if (_hasValue('description'))
                _row('Description', _value('description')),
            ],
          ),

          _section(
            title: 'Status and Cost',
            icon: Icons.payments_outlined,
            children: [
              _row('Current Status', displayStatus),
              _row('Condition', _value('condition_status')),
              _row('Acquisition Date', _value('acquisition_date')),
              _row('Acquisition Cost', _value('acquisition_cost')),
            ],
          ),

          _section(
            title: 'Current Assignment',
            icon: Icons.assignment_ind_outlined,
            children: [
              _row('Office', _value('current_office')),
              _row('Department', _value('current_department')),
              _row('Employee', _employeeDisplay()),
            ],
          ),

          if (_hasValue('owning_office') ||
              _hasValue('owning_department') ||
              _hasValue('return_office') ||
              _hasValue('return_department'))
            _section(
              title: 'Owning / Return Office',
              icon: Icons.account_balance_outlined,
              children: [
                _row('Owning Office', _value('owning_office')),
                _row('Owning Department', _value('owning_department')),
                _row('Return Office', _value('return_office')),
                _row('Return Department', _value('return_department')),
              ],
            ),

          if (_hasValue('remarks'))
            _section(
              title: 'Remarks',
              icon: Icons.notes_outlined,
              children: [
                Text(
                  _value('remarks'),
                  style: const TextStyle(
                    height: 1.4,
                  ),
                ),
              ],
            ),

          _movementSection(movements),
        ],
      ),
    );
  }

  Widget _headerCard({
    required String assetName,
    required String assetNo,
    required String status,
    required String displayStatus,
    required String condition,
  }) {
    final statusColor = _statusColor(status);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: statusColor.withOpacity(0.12),
              child: Icon(
                _statusIcon(status),
                color: statusColor,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assetName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    assetNo,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(
                        text: displayStatus.toUpperCase(),
                        color: statusColor,
                      ),
                      if (condition != '-')
                        _chip(
                          text: condition.toUpperCase(),
                          color: Colors.black54,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickInfoGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: [
        _quickInfoCard(
          title: 'Employee',
          value: _employeeDisplay(),
          icon: Icons.person_outline,
        ),
        _quickInfoCard(
          title: 'Office',
          value: _value('current_office'),
          icon: Icons.apartment,
        ),
        _quickInfoCard(
          title: 'Department',
          value: _value('current_department'),
          icon: Icons.account_tree_outlined,
        ),
        _quickInfoCard(
          title: 'Category',
          value: _value('category'),
          icon: Icons.category_outlined,
        ),
      ],
    );
  }

  Widget _quickInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    const Color primaryColor = Color(0xFF0D6EFD);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor.withOpacity(0.10),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFF0D6EFD),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.only(bottom: 11),
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
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _movementSection(List<dynamic> movements) {
    if (movements.isEmpty) {
      return _section(
        title: 'Movement History',
        icon: Icons.history,
        children: const [
          Text(
            'No movement history.',
            style: TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      );
    }

    return _section(
      title: 'Movement History',
      icon: Icons.history,
      children: movements.map((movement) {
        final item = movement as Map<String, dynamic>;

        final movementType = (item['movement_type'] ?? '-')
            .toString()
            .trim()
            .toUpperCase();

        final movementDate = item['movement_date']?.toString() ?? '-';

        final remarks = item['remarks']?.toString().trim().isNotEmpty == true
            ? item['remarks'].toString()
            : 'No remarks.';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE1E5EA),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 18,
                child: Icon(
                  Icons.history,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movementType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      movementDate,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remarks,
                      style: const TextStyle(
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _chip({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}