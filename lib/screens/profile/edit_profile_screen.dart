import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../utils/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _name  = TextEditingController();
  final _email = TextEditingController();
  final _addr  = TextEditingController();
  final _city  = TextEditingController();
  final _state = TextEditingController();
  final _pin   = TextEditingController();
  File? _image;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user ?? {};
    _name.text  = u['name']    ?? '';
    _email.text = u['email']   ?? '';
    _addr.text  = u['address'] ?? '';
    _city.text  = u['city']    ?? '';
    _state.text = u['state']   ?? '';
    _pin.text   = u['pincode'] ?? '';
  }

  Future<void> _pickImage() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (p != null) setState(() => _image = File(p.path));
  }

  Future<void> _save() async {
    if (_name.text.isEmpty) { _snack('Name is required'); return; }
    setState(() => _saving = true);
    try {
      final api = context.read<ApiService>();
      if (_image != null) {
        await api.updateProfileWithImage({
          'name': _name.text, 'email': _email.text,
          'address': _addr.text, 'city': _city.text,
          'state': _state.text, 'pincode': _pin.text,
        }, _image!);
      } else {
        await api.updateProfile({
          'name': _name.text, 'email': _email.text,
          'address': _addr.text, 'city': _city.text,
          'state': _state.text, 'pincode': _pin.text,
        });
      }
      await context.read<AuthProvider>().refreshProfile();
      _snack('Profile updated!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) { _snack(e.toString()); }
    setState(() => _saving = false);
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(h: 18, w: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Avatar
          GestureDetector(
            onTap: _pickImage,
            child: Stack(children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? Text((user?['name'] ?? 'U')[0],
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 36))
                    : null,
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          const Text('Tap to change photo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 28),

          _Field(_name,  'Full Name',    Icons.person,         required: true),
          _Field(_email, 'Email',        Icons.email,          type: TextInputType.emailAddress),
          _Field(_addr,  'Address',      Icons.location_on,    maxLines: 2),
          _Field(_city,  'City',         Icons.location_city),
          _Field(_state, 'State',        Icons.map),
          _Field(_pin,   'Pincode',      Icons.pin,            type: TextInputType.number, maxLen: 6),

          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Changes'),
          ),
          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  final int maxLines, maxLen;
  final bool required;
  const _Field(this.ctrl, this.label, this.icon,
      {this.type = TextInputType.text, this.maxLines = 1, this.maxLen = 0, this.required = false});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      maxLength: maxLen > 0 ? maxLen : null,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        counterText: '',
      ),
    ),
  );
}
