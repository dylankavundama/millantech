import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:stocktrue/HomeScreenBar.dart';
import 'package:stocktrue/Smartphone/homeSmart.dart';

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
    _initHive();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    _usersBox = await Hive.openBox('users');
    _techniciansBox = await Hive.openBox('technicians');

    // Initialisation avec des données de test uniquement en développement
    await _initializeTestData();
  }

  Future<void> _initializeTestData() async {
    if (_techniciansBox.isEmpty) {
      await _techniciansBox.putAll({
        'tech@example.com': {
          'email': 'tech@example.com',
          'name': 'Technicien Test',
          'isTechnician': true,
        },
        'admin@example.com': {
          'email': 'admin@example.com',
          'name': 'Admin Technicien',
          'isTechnician': true,
        },
        'mac@gmail.com': {
          'email': 'mac@gmail.com',
          'name': 'Admin Technicien',
          'isTechnician': true,
        }
      });
    }

    if (_usersBox.isEmpty) {
      // Ajout d'un utilisateur test avec mot de passe hashé
      await _usersBox.put('admin@gmail.com', {
        'email': 'admin@gmail.com',
        'name': 'Admin',
        'password': _hashPassword('1234'),
        'isTechnician': false,
      });
    }
  }

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
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
        await _handleTechnicianLogin(email);
      } else {
        await _handleUserLogin(email);
      }
    } catch (e) {
      _handleLoginError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleTechnicianLogin(String email) async {
    if (!_techniciansBox.containsKey(email)) {
      throw Exception('Email technicien non reconnu');
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
      MaterialPageRoute(builder: (context) => ShopSelectionPage()),
    );
  }

  Future<void> _handleUserLogin(String email) async {
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
      MaterialPageRoute(builder: (context) => const adminPage()),
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
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                  ],
                  const SizedBox(height: 24),
                  _buildLoginButton(),
                  if (!_isTechnicianLogin) ...[
                    const SizedBox(height: 16),
                    // _buildRegisterButton(),
                  ],
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
              value: _isTechnicianLogin,
              onChanged: (value) {
                setState(() {
                  _isTechnicianLogin = value;
                  _message = '';
                  if (value) {
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

class ShopSelectionPage extends StatelessWidget {
  const ShopSelectionPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélection de boutique'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Choisissez votre boutique',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeMillan(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              ),
              child: const Text('Millan Tech'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeSmart(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
              ),
              child: const Text('Smart Phone'),
            ),
          ],
        ),
      ),
    );
  }
}

class adminPage extends StatefulWidget {
  const adminPage({super.key});

  @override
  State<adminPage> createState() => _adminPageState();
}

class _adminPageState extends State<adminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text("admin")),
    );
  }
}
