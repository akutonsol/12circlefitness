import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../data/nutrition_service.dart';

const _card    = Color(0xFF0D0D1E);
const _brand   = Color(0xFFA855F7);
const _white   = Colors.white;
const _muted   = Color(0xFF888898);
const _green   = Color(0xFF6FFBBE);
const _redChip = Color(0xFFFFB4AB);

class ScanItem {
  final String name;
  final double calories, protein, carbs, fat;
  const ScanItem({required this.name, required this.calories,
    required this.protein, required this.carbs, required this.fat});
}

class ScanResult {
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final int confidence;
  final List<ScanItem> items;

  const ScanResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.confidence,
    this.items = const [],
  });

  /// Scales the whole estimate by a portion multiplier (for the slider).
  ScanResult scaled(double f) => ScanResult(
        name: name, confidence: confidence, items: items,
        calories: calories * f, protein: protein * f,
        carbs: carbs * f, fat: fat * f,
      );
}

class AiScanView extends StatefulWidget {
  final void Function(ScanResult result) onAccept;
  const AiScanView({super.key, required this.onAccept});

  @override
  State<AiScanView> createState() => _AiScanViewState();
}

enum _ScanStage { idle, scanning, result }

class _AiScanViewState extends State<AiScanView> {
  final _picker = ImagePicker();
  final _descCtrl = TextEditingController();
  XFile? _image;
  _ScanStage _stage = _ScanStage.idle;
  ScanResult? _result;
  double _portion = 1.0; // serving multiplier applied before logging

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  ScanResult _parse(Map<String, dynamic> r) {
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0;
    final rawItems = (r['items'] as List?) ?? const [];
    return ScanResult(
      name: (r['name'] as String?)?.trim().isNotEmpty == true
          ? r['name'] as String : 'Scanned meal',
      calories: d(r['calories']),
      protein: d(r['protein_g']),
      carbs: d(r['carbs_g']),
      fat: d(r['fat_g']),
      confidence: (r['confidence'] as num?)?.toInt() ?? 0,
      items: rawItems.whereType<Map>().map((m) => ScanItem(
        name: (m['name'] as String?) ?? 'Item',
        calories: d(m['calories']), protein: d(m['protein_g']),
        carbs: d(m['carbs_g']), fat: d(m['fat_g']),
      )).toList(),
    );
  }

  // Describe a meal in words instead of a photo.
  Future<void> _describe() async {
    final text = _descCtrl.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _image = null; _stage = _ScanStage.scanning; });
    try {
      final r = await NutritionService().analyzeFood(description: text);
      if (!mounted) return;
      setState(() { _result = _parse(r); _portion = 1.0; _stage = _ScanStage.result; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _ScanStage.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't estimate that. Try again.\n$e"), backgroundColor: _redChip));
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, imageQuality: 80);
      if (file == null) return;
      setState(() {
        _image = file;
        _stage = _ScanStage.scanning;
      });
      await _analyze();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't access camera/gallery: $e")),
        );
      }
    }
  }

  Future<void> _analyze() async {
    final file = _image;
    if (file == null) return;
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.toLowerCase().split('.').last;
      final mime = ext == 'png' ? 'image/png'
          : ext == 'webp' ? 'image/webp'
          : ext == 'heic' ? 'image/heic' : 'image/jpeg';
      final r = await NutritionService().analyzeFood(
        imageBytes: bytes, mediaType: mime);
      if (!mounted) return;
      setState(() {
        _result = _parse(r);
        _portion = 1.0;
        _stage = _ScanStage.result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _stage = _ScanStage.idle);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't analyze that photo. Try again or add manually.\n$e"),
          backgroundColor: _redChip));
    }
  }

  void _retake() {
    setState(() {
      _image = null;
      _result = null;
      _stage = _ScanStage.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _ScanStage.idle:    return _buildIdle();
      case _ScanStage.scanning: return _buildScanning();
      case _ScanStage.result:  return _buildResult();
    }
  }

  Widget _buildIdle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          // ── Camera placeholder ─────────────────────────────────────
          Container(
            width: double.infinity,
            height: 230,
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _brand.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _brand.withValues(alpha: 0.08),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // subtle radial glow
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _brand.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _brand.withValues(alpha: 0.08),
                        border: Border.all(color: _brand.withValues(alpha: 0.2)),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: _muted.withValues(alpha: 0.6),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Take or upload a photo of your meal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted.withValues(alpha: 0.6),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // ── Scan Meal button ───────────────────────────────────────
          GestureDetector(
            onTap: () => _pickImage(kIsWeb ? ImageSource.gallery : ImageSource.camera),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFB44CF0)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: _brand.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.camera_alt_rounded, color: _white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Scan Meal',
                    style: TextStyle(
                      color: _white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ── Choose from Gallery button ─────────────────────────────
          GestureDetector(
            onTap: () => _pickImage(ImageSource.gallery),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _brand.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, color: _muted, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Or describe your meal in words ─────────────────────────
          Row(children: [
            Expanded(child: Divider(color: _muted.withValues(alpha: 0.15))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('or describe it', style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 12))),
            Expanded(child: Divider(color: _muted.withValues(alpha: 0.15))),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: _white, fontSize: 14),
            minLines: 1, maxLines: 2,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _describe(),
            decoration: InputDecoration(
              hintText: 'e.g. grilled chicken salad with avocado',
              hintStyle: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 13),
              filled: true, fillColor: _card,
              suffixIcon: IconButton(
                icon: const Icon(Icons.auto_awesome, color: _brand, size: 20),
                onPressed: _describe),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: _brand.withValues(alpha: 0.25))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _brand)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanning() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: double.infinity,
              height: 260,
              child: _image == null
                  ? Container(color: _card)
                  : (kIsWeb
                      ? Image.network(_image!.path, fit: BoxFit.cover)
                      : Image.file(File(_image!.path), fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFB44CF0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: _white, strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Analyzing your meal...',
                  style: TextStyle(
                    color: _white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    final r = _result!;
    final disp = r.scaled(_portion); // values after the portion multiplier
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Image preview ────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              width: double.infinity,
              height: 180,
              child: _image == null
                  ? Container(color: _card)
                  : (kIsWeb
                      ? Image.network(_image!.path, fit: BoxFit.cover)
                      : Image.file(File(_image!.path), fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 14),
          // ── Scan result card ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _brand.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      r.name,
                      style: const TextStyle(
                        color: _white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '${r.confidence}% match',
                        style: const TextStyle(
                          color: _green,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${disp.calories.toInt()} kcal',
                  style: const TextStyle(color: _white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroChip('Protein', disp.protein.toInt(), _brand),
                    _MacroChip('Carbs', disp.carbs.toInt(), _green),
                    _MacroChip('Fat', disp.fat.toInt(), _redChip),
                  ],
                ),
                const SizedBox(height: 12),
                // ── Portion adjuster ────────────────────────────────
                Row(children: [
                  Icon(Icons.tune_rounded, color: _muted.withValues(alpha: 0.7), size: 16),
                  const SizedBox(width: 6),
                  Text('Portion', style: TextStyle(color: _muted.withValues(alpha: 0.7), fontSize: 12)),
                  const Spacer(),
                  Text('${_portion.toStringAsFixed(2)}×',
                    style: const TextStyle(color: _brand, fontSize: 13, fontWeight: FontWeight.w700)),
                ]),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: _brand, inactiveTrackColor: _brand.withValues(alpha: 0.2),
                    thumbColor: _brand, overlayColor: _brand.withValues(alpha: 0.15),
                    trackHeight: 3),
                  child: Slider(
                    value: _portion, min: 0.25, max: 3.0, divisions: 11,
                    onChanged: (v) => setState(() => _portion = v)),
                ),
                // ── Per-item breakdown ──────────────────────────────
                if (r.items.length > 1) ...[
                  Divider(color: _muted.withValues(alpha: 0.12)),
                  const SizedBox(height: 4),
                  Text('INCLUDES', style: TextStyle(color: _muted.withValues(alpha: 0.5),
                    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  ...r.items.map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Expanded(child: Text(it.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _muted.withValues(alpha: 0.85), fontSize: 12))),
                      Text('${(it.calories * _portion).toInt()} kcal',
                        style: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 12)),
                    ]),
                  )),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Retake / Accept ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _retake,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _brand.withValues(alpha: 0.3), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Retake',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onAccept(disp),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFB44CF0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: _brand.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Log This Meal',
                      style: TextStyle(
                        color: _white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            '${value}g',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(color: _muted.withValues(alpha: 0.5), fontSize: 10),
          ),
        ],
      );
}
