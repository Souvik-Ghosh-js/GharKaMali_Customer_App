import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  bool _newUser = false;
  final _nameCtrl = TextEditingController();

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.length != 10) {
      _snack('Enter a valid 10-digit phone number'); return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().sendOtp(_phoneCtrl.text);
      setState(() => _otpSent = true);
      _snack('OTP sent! Use 123456 for testing.');
    } catch (e) {
      _snack(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.length != 6) { _snack('Enter 6-digit OTP'); return; }
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().verifyOtp(
        _phoneCtrl.text, _otpCtrl.text,
        name: _newUser && _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      _snack(e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(22)),
                  child: const Center(child: Text('🌿', style: TextStyle(fontSize: 40))),
                ),
                const SizedBox(height: 16),
                const Text('Ghar Ka Mali', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                const Text('Login to manage your garden', style: TextStyle(color: AppTheme.textSecondary)),
              ]),
            ),
            const SizedBox(height: 48),
            if (!_otpSent) ...[
              const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '9876543210',
                  prefixText: '+91 ',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Send OTP'),
              ),
            ] else ...[
              if (_newUser) ...[
                const Text('Your Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(hintText: 'Enter your name')),
                const SizedBox(height: 16),
              ],
              Row(children: [
                const Text('OTP sent to ', style: TextStyle(color: AppTheme.textSecondary)),
                Text('+91 ${_phoneCtrl.text}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton(onPressed: () => setState(() => _otpSent = false), child: const Text('Change')),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 12),
                decoration: const InputDecoration(hintText: '000000', counterText: ''),
              ),
              const SizedBox(height: 8),
              const Text('💡 Use OTP: 123456 for testing', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Verify & Login'),
              ),
              const SizedBox(height: 12),
              Center(child: TextButton(
                onPressed: () { setState(() => _newUser = !_newUser); },
                child: Text(_newUser ? 'Already have account? Login' : 'New user? Register'),
              )),
            ],
            const SizedBox(height: 32),
            const Center(child: Text('By continuing you agree to our\nTerms of Service & Privacy Policy',
              textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          ],
        ),
      ),
    ),
  );
}
