import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class PlantScreen extends StatefulWidget {
  const PlantScreen({super.key});
  @override
  State<PlantScreen> createState() => _PlantScreenState();
}

class _PlantScreenState extends State<PlantScreen> {
  File? _image;
  Map? _result;
  bool _identifying = false;
  List _history = [];
  bool _loadingHistory = true;

  @override
  void initState() { super.initState(); _loadHistory(); }

  Future<void> _loadHistory() async {
    try {
      final res = await context.read<ApiService>().getPlantHistory();
      setState(() => _history = res['data'] ?? []);
    } catch (_) {}
    setState(() => _loadingHistory = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 1024);
    if (picked == null) return;
    setState(() { _image = File(picked.path); _result = null; });
    _identify();
  }

  Future<void> _identify() async {
    if (_image == null) return;
    setState(() => _identifying = true);
    try {
      final res = await context.read<ApiService>().identifyPlant(_image!);
      setState(() => _result = res['data']);
      _loadHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
    setState(() => _identifying = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Plantopedia 🌿')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Plant Identification', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Take a photo or pick from gallery\nto identify any plant instantly', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 20),

        // Image picker area
        GestureDetector(
          onTap: () => _showPicker(),
          child: Container(
            width: double.infinity, height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _image != null ? AppTheme.primary : AppTheme.border, width: _image != null ? 2 : 1, style: BorderStyle.solid),
            ),
            child: _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(_image!, fit: BoxFit.cover))
                : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppTheme.textSecondary),
                    SizedBox(height: 8),
                    Text('Tap to add plant photo', style: TextStyle(color: AppTheme.textSecondary)),
                    SizedBox(height: 4),
                    Text('Camera or Gallery', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500, fontSize: 12)),
                  ]),
          ),
        ),

        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Camera'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary)),
          )),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library, size: 18),
            label: const Text('Gallery'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44), foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.primary)),
          )),
        ]),

        // Identifying loader
        if (_identifying) ...[
          const SizedBox(height: 24),
          const GkmCard(child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
              SizedBox(width: 16),
              Text('Identifying your plant...', style: TextStyle(fontWeight: FontWeight.w500)),
            ]),
          )),
        ],

        // Result
        if (_result != null) ...[
          const SizedBox(height: 20),
          GkmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Identification Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              if (_result!['confidence_score'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('${_result!['confidence_score']}% match', style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 16),
            _InfoRow('🌿 Plant Name', _result!['plant_name'] ?? 'Unknown'),
            if (_result!['scientific_name']?.isNotEmpty == true)
              _InfoRow('🔬 Scientific Name', _result!['scientific_name']),
            if (_result!['description']?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              const Text('About', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_result!['description'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            const Text('Care Guide', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            _CareCard('💧 Watering', _result!['watering_schedule'] ?? 'Water regularly'),
            _CareCard('☀️ Sunlight', _result!['sunlight_requirement'] ?? 'Moderate'),
            _CareCard('🌱 Fertilizer', _result!['fertilizer_tips'] ?? 'Monthly feeding'),
          ])),
        ],

        // History
        const SizedBox(height: 28),
        const Text('Identification History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (_loadingHistory)
          const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        else if (_history.isEmpty)
          const Text('No identifications yet', style: TextStyle(color: AppTheme.textSecondary))
        else
          ..._history.take(5).map((h) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: GkmCard(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(h['image_url'] ?? '', width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: AppTheme.border, child: const Icon(Icons.image))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h['plant_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(h['scientific_name'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ])),
              ]),
            ),
          )),
        const SizedBox(height: 80),
      ]),
    ),
  );

  void _showPicker() => showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt, color: AppTheme.primary), title: const Text('Take Photo'),
          onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
        ListTile(leading: const Icon(Icons.photo_library, color: AppTheme.primary), title: const Text('Choose from Gallery'),
          onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
      ]),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String k, v;
  const _InfoRow(this.k, this.v);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(k, style: const TextStyle(fontWeight: FontWeight.w500)),
      const Spacer(),
      Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))),
    ]),
  );
}

class _CareCard extends StatelessWidget {
  final String label, value;
  const _CareCard(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      const Spacer(),
      Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
    ]),
  );
}
