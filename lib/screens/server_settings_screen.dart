import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _serverUrlController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadServerUrl();
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadServerUrl() async {
    final currentUrl = await ApiService.getBaseUrl();

    if (!mounted) return;

    setState(() {
      _serverUrlController.text = currentUrl;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.saveBaseUrl(_serverUrlController.text);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Server URL saved.')));

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.friendlyError(e)),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _resetDefault() async {
    await ApiService.resetBaseUrl();

    if (!mounted) return;

    setState(() {
      _serverUrlController.text = ApiService.defaultBaseUrl;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server URL reset to default.')),
    );
  }

  String? _validateUrl(String? value) {
    final url = value?.trim() ?? '';

    if (url.isEmpty) {
      return 'Server URL is required.';
    }

    if (!ApiService.isValidBaseUrl(url)) {
      return 'Enter a valid URL ending with /api/mobile.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D6EFD);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Server Settings'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFE7F1FF),
                          child: Icon(Icons.dns_outlined, color: primaryColor),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'API Server URL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Use this only for development or admin setup.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _serverUrlController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    validator: _validateUrl,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://192.168.1.10:8000/api/mobile',
                      helperText: 'Must include /api/mobile',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onFieldSubmitted: (_) => _save(),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Server URL',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving ? null : _resetDefault,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Default'),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  color: const Color(0xFFFFF8E1),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Hidden access: tap the AssetTrack Pro logo/title 5 times on the login screen.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
