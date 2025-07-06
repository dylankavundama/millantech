import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:stocktrue/Smartphone/homeSmart.dart'; // This might still be needed if HomeBarAdmin has a path to it, but not directly from AuthPage anymore.
import 'package:stocktrue/agent/homeBarAgent.dart';

import '../HomeScreenBar.dart'; // Ensure HomeBarAdmin is defined here

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  // This _isTechnicianLogin corresponds to the "Agent" role in your UI switch.
  // When true, the user is attempting to log in as an Agent.
  bool _isTechnicianLogin = false;
  String _message = '';

  late Box _usersBox;
  late Box _techniciansBox;

  @override
  void initState() {
    super.initState();
    _initHiveAndCheckLogin(); // Call a new method to handle both Hive init and login check
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initHiveAndCheckLogin() async {
    await Hive.initFlutter();
    _usersBox = await Hive.openBox('users');
    _techniciansBox = await Hive.openBox('technicians');

    // Initialisation avec des données de test uniquement en développement
    await _initializeTestData();

    // After Hive is initialized and test data is set, check login status
    _checkLoginStatus();
  }

  Future<void> _initializeTestData() async {
    // Only add test data if the boxes are empty
    // Technicians (Agents) - these directly map to the 'Agent' role.
    if (_techniciansBox.isEmpty) {
      await _techniciansBox.putAll({
        'agent@example.com': {
          // Renamed for clarity: agent instead of tech
          'email': 'agent@example.com',
          'name': 'Agent Test',
          'isTechnician': true, // Indicates Agent role
        },
        'mac@gmail.com': {
          // This user is also treated as an Agent for navigation
          'email': 'mac@gmail.com',
          'name': 'Agent Macmillan',
          'isTechnician': true,
        }
      });
    }

    // Users (Admins) - these directly map to the 'Admin' role.
    if (_usersBox.isEmpty) {
      await _usersBox.put('admin@gmail.com', {
        'email': 'admin@gmail.com',
        'name': 'Admin User',
        'password': _hashPassword('1234'),
        'isTechnician': false, // Indicates Admin role
      });
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // New method to check login status on app restart
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final isTechnician = prefs.getBool('isTechnician') ?? false;

    if (isLoggedIn) {
      // Use addPostFrameCallback to ensure navigation happens after the build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Check if the widget is still mounted before navigating
          if (isTechnician) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeBarAgent()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeBarAdmin()),
            );
          }
        }
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final email = _emailController.text.trim().toLowerCase();

      if (_isTechnicianLogin) {
        // If the switch is on 'Agent' (_isTechnicianLogin is true), handle Agent login
        await _handleAgentLogin(email);
      } else {
        // If the switch is on 'Admin' (_isTechnicianLogin is false), handle Admin login
        await _handleAdminLogin(email);
      }
    } catch (e) {
      _handleLoginError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Handles login for 'Admin' role
  Future<void> _handleAdminLogin(String email) async {
    final password = _passwordController.text.trim();

    if (!_usersBox.containsKey(email)) {
      throw Exception('Email non reconnu');
    }

    final user = _usersBox.get(email);
    final hashedPassword = _hashPassword(password);

    if (user['password'] != hashedPassword) {
      throw Exception('Mot de passe incorrect');
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('email', email);
    await prefs.setString('userName', user['name']);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool(
        'isTechnician', false); // Storing role as non-technician (admin)

    if (!mounted) return;
    // Direct navigation to HomeBarAdmin for Admin users
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeBarAdmin()),
    );
  }

  // Handles login for 'Agent' role
  Future<void> _handleAgentLogin(String email) async {
    if (!_techniciansBox.containsKey(email)) {
      throw Exception('Email agent non reconnu');
    }

    final technician = _techniciansBox.get(email);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('email', email);
    await prefs.setString('userName', technician['name']);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool(
        'isTechnician', true); // Storing role as technician (agent)

    if (!mounted) return;
    // Direct navigation to HomeBarAgent for Agent users
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeBarAgent()),
    );
  }

  void _handleLoginError(dynamic error) {
    final errorMessage = error is Exception
        ? error.toString().replaceAll('Exception: ', '')
        : 'Une erreur inattendue est survenue';

    if (mounted) {
      setState(() {
        _message = 'Erreur de connexion: $errorMessage';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 111),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 24,
                  ),
                  Image.asset(height: 111, 'assets/logo.png'),
                  const SizedBox(height: 24),
                  _buildEmailField(),
                  if (!_isTechnicianLogin) ...[
                    // Password field only for Admin (non-technician) login
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                  ],
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                  const SizedBox(height: 16), // Spacing before the switch
                  _buildRoleSwitch(),
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                  const Center(
                      child: Text(
                    "Copyright©Macmillan 2025",
                    style: TextStyle(),
                    textAlign: TextAlign.center,
                  ))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSwitch() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Admin',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Switch(
              // _isTechnicianLogin being true means 'Agent' is selected
              // _isTechnicianLogin being false means 'Admin' is selected
              value: _isTechnicianLogin,
              onChanged: (value) {
                setState(() {
                  _isTechnicianLogin = value;
                  _message = ''; // Clear message on role switch
                  if (value) {
                    // If switching to Agent, clear password as it's not needed
                    _passwordController.clear();
                  }
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const Text(
              'Agent',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer un email';
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Email invalide';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: Icon(Icons.lock),
        border: OutlineInputBorder(),
      ),
      obscureText: true,
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer un mot de passe';
        }
        if (value.length < 4) {
          return '4 caractères minimum';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'SE CONNECTER',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildErrorMessage() {
    if (_message.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Text(
        _message,
        style: TextStyle(
          color: Colors.red[700],
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
