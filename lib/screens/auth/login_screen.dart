import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';
import 'otp_verification_screen.dart';

class CountryData {
  final String name;
  final String code;
  final String flag;

  const CountryData({
    required this.name,
    required this.code,
    required this.flag,
  });
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isPhoneLogin = true;
  bool _obscurePassword = true;
  bool _loading = false;

  static const List<CountryData> _countries = [
    CountryData(name: 'Pakistan', code: '+92', flag: '🇵🇰'),
    CountryData(name: 'India', code: '+91', flag: '🇮🇳'),
    CountryData(name: 'United States', code: '+1', flag: '🇺🇸'),
    CountryData(name: 'United Kingdom', code: '+44', flag: '🇬🇧'),
    CountryData(name: 'Saudi Arabia', code: '+966', flag: '🇸🇦'),
    CountryData(name: 'United Arab Emirates', code: '+971', flag: '🇦🇪'),
  ];

  late CountryData _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries[0]; // Default is Pakistan +92
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isPhoneLogin) {
      _submitPhone();
    } else {
      _submitEmail();
    }
  }

  void _submitPhone() {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OTPVerificationScreen(
            phoneNumber: '${_selectedCountry.code}${_phoneController.text}',
          ),
        ),
      );
    });
  }

  void _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AuthService.instance.readableError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPhoneInput() {
    return TextFormField(
      key: const ValueKey('phone_input'),
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'Enter mobile number',
        filled: true,
        fillColor: const Color(0xFFF6F6F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<CountryData>(
                  value: _selectedCountry,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                  onChanged: (CountryData? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCountry = newValue;
                      });
                    }
                  },
                  items: _countries.map<DropdownMenuItem<CountryData>>((CountryData country) {
                    return DropdownMenuItem<CountryData>(
                      value: country,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            country.flag,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            country.code,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      ),
      validator: (value) {
        if (!_isPhoneLogin) return null;
        if (value == null || value.trim().isEmpty) {
          return 'Enter mobile number';
        }
        if (value.trim().length < 7) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildEmailInput() {
    return Column(
      key: const ValueKey('email_input'),
      children: [
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Enter email address',
            filled: true,
            fillColor: const Color(0xFFF6F6F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
          ),
          validator: (value) {
            if (_isPhoneLogin) return null;
            if (value == null || value.trim().isEmpty) {
              return 'Enter email address';
            }
            if (!value.contains('@')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Enter password',
            filled: true,
            fillColor: const Color(0xFFF6F6F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.black54,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (_isPhoneLogin) return null;
            if (value == null || value.isEmpty) {
              return 'Enter password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Welcome back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please Login to your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: Image.asset(
                    'assets/images/login_illustration.png',
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Toggle Tab Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPhoneLogin = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isPhoneLogin ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'Phone Number',
                                style: TextStyle(
                                  color: _isPhoneLogin ? Colors.white : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPhoneLogin = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isPhoneLogin ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'Email Address',
                                style: TextStyle(
                                  color: !_isPhoneLogin ? Colors.white : Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Dynamic Input Panel with Micro-Animation
                AnimatedCrossFade(
                  firstChild: _buildPhoneInput(),
                  secondChild: _buildEmailInput(),
                  crossFadeState: _isPhoneLogin
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),
                const SizedBox(height: 32),
                
                // Log In Button
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                        children: [
                          TextSpan(text: "Don't have account? "),
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
