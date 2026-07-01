import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const AssetTrackProApp());
}

class AssetTrackProApp extends StatelessWidget {
  const AssetTrackProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssetTrack Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D6EFD),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<Widget> _startScreenFuture;

  @override
  void initState() {
    super.initState();
    _startScreenFuture = _getStartScreen();
  }

  Future<Widget> _getStartScreen() async {
    final token = await ApiService.getToken();
    final userName = await ApiService.getUserName();
    final userEmail = await ApiService.getUserEmail();

    if (token != null && token.isNotEmpty) {
      return HomeScreen(
        userName: userName ?? '',
        userEmail: userEmail ?? '',
      );
    }

    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return snapshot.data ?? const LoginScreen();
        }

        return const Scaffold(
          backgroundColor: Color(0xFFF5F7FB),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}