import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.title});

  final String? title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _auth = Get.find<AuthController>();

  final TextEditingController _emailController =
      TextEditingController(text: 'user');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(text: '1234');

  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _auth.authError.value = '';
      if (_isRegisterMode && _emailController.text == 'user') {
        _emailController.clear();
        _passwordController.clear();
      } else if (!_isRegisterMode && _emailController.text.isEmpty) {
        _emailController.text = 'user';
        _passwordController.text = '1234';
      }
    });
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _auth.authError.value = 'fill_required_fields'.tr;
      return;
    }
    if (_isRegisterMode && username.length < 2) {
      _auth.authError.value = 'username_too_short'.tr;
      return;
    }

    if (_isRegisterMode) {
      await _auth.register(
        email: email,
        username: username,
        password: password,
      );
    } else {
      await _auth.login(email: email, password: password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerTitle = _isRegisterMode ? 'register'.tr : 'login'.tr;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      (constraints.maxHeight - 24.0).clamp(0, double.infinity),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 135,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20.0),
                                  child: Image.asset(
                                    'assets/images/login_background.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16.0),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    headerTitle,
                                    style: const TextStyle(
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3.0,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isRegisterMode) ...[
                          TextField(
                            controller: _usernameController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'username'.tr,
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'email_or_login'.tr,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'password'.tr,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                        ),
                        Obx(() {
                          final err = _auth.authError.value;
                          if (err.isEmpty) return const SizedBox(height: 16);
                          return Padding(
                            padding: const EdgeInsets.only(top: 10, bottom: 6),
                            child: Text(
                              err,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        Obx(
                          () => FilledButton(
                            onPressed: _auth.isLoading.value ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                            child: _auth.isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    headerTitle,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(
                            _isRegisterMode
                                ? 'have_account_login'.tr
                                : 'no_account_register'.tr,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}