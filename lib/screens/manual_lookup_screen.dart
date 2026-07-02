import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'asset_detail_screen.dart';

class ManualLookupScreen extends StatefulWidget {
  const ManualLookupScreen({super.key});

  @override
  State<ManualLookupScreen> createState() => _ManualLookupScreenState();
}

class _ManualLookupScreenState extends State<ManualLookupScreen> {
  final TextEditingController _keywordController = TextEditingController();

  bool _isLoadingOptions = true;
  bool _isSearching = false;

  String _searchType = 'asset';
  String _selectedStatus = '';

  List<dynamic> _offices = [];
  List<dynamic> _departments = [];
  List<dynamic> _employees = [];
  List<dynamic> _results = [];

  Map<String, dynamic>? _selectedOffice;
  Map<String, dynamic>? _selectedDepartment;
  Map<String, dynamic>? _selectedEmployee;

  final Map<String, String> _searchTypes = {
    'asset': 'Asset Code / Name',
    'employee': 'Employee',
    'department': 'Department',
  };

  final Map<String, String> _statusOptions = {
    '': 'All Status',
    'available': 'Available',
    'assigned': 'Assigned',
    'maintenance': 'Maintenance',
    'disposed': 'Disposed',
    'lost': 'Lost',
  };

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final data = await ApiService.getAssetSearchOptions();

      if (!mounted) return;

      setState(() {
        _offices = data['offices'] ?? [];
        _departments = data['departments'] ?? [];
        _employees = data['employees'] ?? [];
        _isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingOptions = false;
      });

      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  List<dynamic> get _filteredDepartments {
    if (_selectedOffice == null) {
      return [];
    }

    final officeId = _selectedOffice!['id'].toString();

    return _departments.where((department) {
      return department['office_id']?.toString() == officeId;
    }).toList();
  }

  List<dynamic> get _filteredEmployees {
    if (_selectedOffice == null) {
      return [];
    }

    final officeId = _selectedOffice!['id'].toString();
    final departmentId = _selectedDepartment?['id']?.toString();

    return _employees.where((employee) {
      final officeMatches = employee['office_id']?.toString() == officeId;

      if (departmentId == null) {
        return officeMatches;
      }

      final departmentMatches =
          employee['department_id']?.toString() == departmentId;

      return officeMatches && departmentMatches;
    }).toList();
  }

  void _resetSelections() {
    _keywordController.clear();
    _selectedOffice = null;
    _selectedDepartment = null;
    _selectedEmployee = null;
    _selectedStatus = '';
    _results = [];
  }

  Future<void> _pickOffice() async {
    final selected = await _showSearchablePicker(
      title: 'Select Office',
      items: _offices,
      labelBuilder: (item) => item['office_name']?.toString() ?? '-',
    );

    if (selected == null) return;

    setState(() {
      _selectedOffice = Map<String, dynamic>.from(selected);
      _selectedDepartment = null;
      _selectedEmployee = null;
      _results = [];
    });
  }

  Future<void> _pickDepartment() async {
    if (_selectedOffice == null) {
      _showError('Please select office first.');
      return;
    }

    final selected = await _showSearchablePicker(
      title: 'Select Department',
      items: _filteredDepartments,
      labelBuilder: (item) => item['department_name']?.toString() ?? '-',
    );

    if (selected == null) return;

    setState(() {
      _selectedDepartment = Map<String, dynamic>.from(selected);
      _selectedEmployee = null;
      _results = [];
    });
  }

  Future<void> _pickEmployee() async {
    if (_selectedOffice == null) {
      _showError('Please select office first.');
      return;
    }

    final selected = await _showSearchablePicker(
      title: 'Select Employee',
      items: _filteredEmployees,
      labelBuilder: (item) => item['name']?.toString() ?? '-',
    );

    if (selected == null) return;

    setState(() {
      _selectedEmployee = Map<String, dynamic>.from(selected);
      _results = [];
    });
  }

  Future<dynamic> _showSearchablePicker({
    required String title,
    required List<dynamic> items,
    required String Function(dynamic item) labelBuilder,
  }) async {
    if (items.isEmpty) {
      _showError('No records available.');
      return null;
    }

    return showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _SearchablePickerSheet(
          title: title,
          items: items,
          labelBuilder: labelBuilder,
        );
      },
    );
  }

  Future<void> _search() async {
    FocusManager.instance.primaryFocus?.unfocus();

    String keyword = '';
    int? officeId;
    int? departmentId;
    int? employeeId;

    if (_searchType == 'asset') {
      keyword = _keywordController.text.trim();

      if (keyword.isEmpty) {
        _showError('Please enter asset code or asset name.');
        return;
      }
    }

    if (_searchType == 'employee') {
      if (_selectedOffice == null) {
        _showError('Please select office.');
        return;
      }

      if (_selectedEmployee == null) {
        _showError('Please select employee.');
        return;
      }

      officeId = int.parse(_selectedOffice!['id'].toString());

      if (_selectedDepartment != null) {
        departmentId = int.parse(_selectedDepartment!['id'].toString());
      }

      employeeId = int.parse(_selectedEmployee!['id'].toString());
    }

    if (_searchType == 'department') {
      if (_selectedOffice == null) {
        _showError('Please select office.');
        return;
      }

      officeId = int.parse(_selectedOffice!['id'].toString());

      if (_selectedDepartment != null) {
        departmentId = int.parse(_selectedDepartment!['id'].toString());
      }
    }

    setState(() {
      _isSearching = true;
      _results = [];
    });

    try {
      final results = await ApiService.searchAssets(
        type: _searchType,
        keyword: keyword,
        officeId: officeId,
        departmentId: departmentId,
        employeeId: employeeId,
        status: _selectedStatus,
      );

      if (!mounted) return;

      setState(() {
        _results = results;
      });

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No assets found.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _openAsset(dynamic item) async {
    final code = item['qr_code']?.toString().trim().isNotEmpty == true
        ? item['qr_code'].toString()
        : item['asset_no'].toString();

    setState(() {
      _isSearching = true;
    });

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

        await _search();
      }
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _value(dynamic item, String key) {
    final value = item[key];

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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D6EFD);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Assets'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingOptions
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          DropdownButtonFormField<String>(
            value: _searchType,
            decoration: InputDecoration(
              labelText: 'Search By',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _searchTypes.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: _isSearching
                ? null
                : (value) {
              setState(() {
                _searchType = value ?? 'asset';
                _resetSelections();
              });
            },
          ),

          const SizedBox(height: 14),

          if (_searchType == 'asset')
            TextField(
              controller: _keywordController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Asset Code / Name',
                hintText: 'Example: AST-20260624100653-1990',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          if (_searchType == 'employee' || _searchType == 'department')
            _pickerField(
              label: 'Office',
              value: _selectedOffice?['office_name']?.toString(),
              icon: Icons.apartment,
              onTap: _isSearching ? null : _pickOffice,
            ),

          if (_searchType == 'employee' || _searchType == 'department')
            const SizedBox(height: 14),

          if (_searchType == 'employee' || _searchType == 'department')
            _pickerField(
              label: 'Department (Optional)',
              value: _selectedDepartment?['department_name']?.toString(),
              icon: Icons.account_tree_outlined,
              onTap: _isSearching ? null : _pickDepartment,
              onClear: _isSearching
                  ? null
                  : () {
                setState(() {
                  _selectedDepartment = null;
                  _selectedEmployee = null;
                  _results = [];
                });
              },
            ),

          if (_searchType == 'employee') const SizedBox(height: 14),

          if (_searchType == 'employee')
            _pickerField(
              label: 'Employee',
              value: _selectedEmployee?['name']?.toString(),
              icon: Icons.person_outline,
              onTap: _isSearching ? null : _pickEmployee,
            ),

          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _statusOptions.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: _isSearching
                ? null
                : (value) {
              setState(() {
                _selectedStatus = value ?? '';
                _results = [];
              });
            },
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSearching ? null : _search,
              icon: _isSearching
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.search),
              label: Text(
                _isSearching ? 'Searching...' : 'Search',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          if (_results.isNotEmpty)
            Text(
              '${_results.length} asset(s) found',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),

          const SizedBox(height: 10),

          ..._results.map((item) {
            final status = _value(item, 'current_status');

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                onTap: _isSearching ? null : () => _openAsset(item),
                title: Text(
                  _value(item, 'asset_name'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asset No: ${_value(item, 'asset_no')}'),
                      Text('Property No: ${_value(item, 'property_no')}'),
                      Text(
                        'Employee: ${_value(item, 'assigned_employee')}',
                      ),
                      Text('Office: ${_value(item, 'current_office')}'),
                      Text(
                        'Department: ${_value(item, 'current_department')}',
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
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required String? value,
    required IconData icon,
    required VoidCallback? onTap,
    VoidCallback? onClear,
  }) {
    final bool hasValue = value != null && value.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: hasValue && onClear != null
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: onClear,
          )
              : const Icon(Icons.arrow_drop_down),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabled: onTap != null,
        ),
        child: Text(
          hasValue ? value : 'Select $label',
          style: TextStyle(
            color: hasValue ? Colors.black87 : Colors.black45,
          ),
        ),
      ),
    );
  }
}

class _SearchablePickerSheet extends StatefulWidget {
  const _SearchablePickerSheet({
    required this.title,
    required this.items,
    required this.labelBuilder,
  });

  final String title;
  final List<dynamic> items;
  final String Function(dynamic item) labelBuilder;

  @override
  State<_SearchablePickerSheet> createState() => _SearchablePickerSheetState();
}

class _SearchablePickerSheetState extends State<_SearchablePickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String keyword) {
    final search = keyword.trim().toLowerCase();

    setState(() {
      if (search.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget.labelBuilder(item).toLowerCase().contains(search);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _filter,
                decoration: InputDecoration(
                  labelText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Expanded(
                child: _filteredItems.isEmpty
                    ? const Center(
                  child: Text('No results found.'),
                )
                    : ListView.separated(
                  itemCount: _filteredItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];

                    return ListTile(
                      title: Text(widget.labelBuilder(item)),
                      onTap: () {
                        Navigator.of(context).pop(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}