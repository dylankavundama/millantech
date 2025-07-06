import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:stocktrue/Smartphone/homeSmart.dart';
import 'package:stocktrue/agent/homeBarAgent.dart';
import '../HomeScreenBar.dart';

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
  bool _isTechnicianLogin = false;
  String _message = '';

  late Box _usersBox;
  late Box _techniciansBox;

  @override
  void initState() {
    super.initState();
    _initHiveAndCheckLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initHiveAndCheckLogin() async {
    try {
      await Hive.initFlutter();

      _usersBox = await Hive.isBoxOpen('users')
          ? Hive.box('users')
          : await Hive.openBox('users');
      _techniciansBox = await Hive.isBoxOpen('technicians')
          ? Hive.box('technicians')
          : await Hive.openBox('technicians');

      await _initializeTestData();
      _checkLoginStatus();
    } catch (e) {
      setState(() {
        _message = 'Erreur d\'initialisation locale : ${e.toString()}';
      });
    }
  }

  Future<void> _initializeTestData() async {
    // Nettoyer les anciennes données pour éviter les doublons ou clés en majuscules
    await _techniciansBox.clear();
    await _usersBox.clear();

    // Agents (Technicians) — emails stockés en minuscules
    await _techniciansBox.putAll({
      'macmillan@millantech.cd': {
        'email': 'macmillan@millantech.cd',
        'name': 'Agent Macmillan',
        'isTechnician': true,
      },
      'mac@gmail.com': {
        'email': 'mac@gmail.com',
        'name': 'Agent Mac',
        'isTechnician': true,
      },
      'eloge@millantech.cd': {
        'email': 'eloge@millantech.cd',
        'name': 'Agent Eloge',
        'isTechnician': true,
      },
      'guershom@millantech.cd': {
        'email': 'guershom@millantech.cd',
        'name': 'Agent Guershom',
        'isTechnician': true,
      }
    });

    // Admin (User) — email aussi en minuscule
    await _usersBox.put('ahadi@millantech.cd', {
      'email': 'ahadi@millantech.cd',
      'name': 'Admin User',
      'password': _hashPassword('Macmillan.1504'),
      'isTechnician': false,
    });

    // Debug : afficher les emails disponibles
    print("Technicians: ${_techniciansBox.keys}");
    print("Admins: ${_usersBox.keys}");
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final isTechnician = prefs.getBool('isTechnician') ?? false;

    if (isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  isTechnician ? const HomeBarAgent() : const HomeBarAdmin()),
        );
      });
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      final email = _emailController.text.trim().toLowerCase();

      if (_isTechnicianLogin) {
        await _handleAgentLogin(email);
      } else {
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
    await prefs.setBool('isTechnician', false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeBarAdmin()),
    );
  }

  Future<void> _handleAgentLogin(String email) async {
    if (!_techniciansBox.containsKey(email)) {
      throw Exception('Email agent non reconnu');
    }

    final technician = _techniciansBox.get(email);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('userName', technician['name']);
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('isTechnician', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeBarAgent()),
    );
  }

  void _handleLoginError(dynamic error) {
    final errorMessage = error is Exception
        ? error.toString().replaceFirst('Exception: ', '')
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
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Image.asset('assets/logo.png', height: 111),
                const SizedBox(height: 24),
                _buildEmailField(),
                if (!_isTechnicianLogin) ...[
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                ],
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 16),
                _buildRoleSwitch(),
                const SizedBox(height: 16),
                _buildErrorMessage(),
                const SizedBox(height: 20),
                // const Text(
                //   "Copyright©Macmillan 2025",
                //   textAlign: TextAlign.center,
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSwitch() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            Switch(
              value: _isTechnicianLogin,
              onChanged: (value) {
                setState(() {
                  _isTechnicianLogin = value;
                  _message = '';
                  if (value) _passwordController.clear();
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const Text('Agent', style: TextStyle(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 33,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'SE CONNECTER',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
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
