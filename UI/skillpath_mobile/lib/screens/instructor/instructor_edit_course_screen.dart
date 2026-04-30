import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

class InstructorEditCourseScreen extends StatefulWidget {
  final CourseDetailDto course;

  const InstructorEditCourseScreen({super.key, required this.course});

  @override
  State<InstructorEditCourseScreen> createState() =>
      _InstructorEditCourseScreenState();
}

class _InstructorEditCourseScreenState
    extends State<InstructorEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _shortDescController;
  late final TextEditingController _descController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _imageUrlController;
  int? _selectedCategoryId;
  int _selectedDifficulty = 0;
  bool _isSaving = false;
  String? _error;
  List<CategoryDto> _categories = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course.title);
    _shortDescController =
        TextEditingController(text: widget.course.shortDescription);
    _descController = TextEditingController(text: widget.course.description);
    _priceController =
        TextEditingController(text: widget.course.price.toStringAsFixed(2));
    _durationController =
        TextEditingController(text: widget.course.durationWeeks.toString());
    _imageUrlController =
        TextEditingController(text: widget.course.imageUrl ?? '');
    _selectedCategoryId = widget.course.categoryId;
    _selectedDifficulty = _difficultyToInt(widget.course.difficultyLevel);
    _loadCategories();
  }

  int _difficultyToInt(String level) {
    switch (level.toLowerCase()) {
      case 'beginner': return 0;
      case 'intermediate': return 1;
      case 'advanced': return 2;
      default: return 0;
    }
  }

  Future<void> _loadCategories() async {
    try {
      final response = await ApiClient.get('/api/Category');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data is List ? data : (data['items'] as List? ?? data);
        setState(() {
          _categories = (items as List)
              .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final body = <String, dynamic>{
        'title': _titleController.text.trim(),
        'shortDescription': _shortDescController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0,
        'durationWeeks': int.tryParse(_durationController.text.trim()) ?? 1,
        'categoryId': _selectedCategoryId,
        'difficultyLevel': _selectedDifficulty,
      };
      final imageUrl = _imageUrlController.text.trim();
      if (imageUrl.isNotEmpty) body['imageUrl'] = imageUrl;

      final response = await ApiClient.put(
        '/api/Course/${widget.course.id}',
        body,
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kurs uspjesno azuriran.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context, true);
        } else {
          final data = jsonDecode(response.body);
          setState(() {
            _error = data['error']?['message'] as String? ??
                data['message'] as String? ??
                'Greska (${response.statusCode})';
          });
        }
      }
    } catch (e) {
      setState(() => _error = 'Greska: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uredi kurs'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sacuvaj',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: Colors.red.shade700, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Naziv kursa',
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Unesite naziv.' : null,
              ),
              const SizedBox(height: 16),

              // Short description
              TextFormField(
                controller: _shortDescController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Kratki opis',
                  prefixIcon: Icon(Icons.short_text),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Unesite kratki opis.'
                    : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Opis kursa',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Unesite opis.' : null,
              ),
              const SizedBox(height: 16),

              // Price & Duration row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cijena (KM)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Unesite cijenu.';
                        if (double.tryParse(v.trim()) == null) return 'Nevazeca cijena.';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Trajanje (sedmica)',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Unesite trajanje.';
                        if (int.tryParse(v.trim()) == null) return 'Nevazeci broj.';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image URL
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL slike (opcionalno)',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Kategorija',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) => v == null ? 'Odaberite kategoriju.' : null,
              ),
              const SizedBox(height: 16),

              // Difficulty selector
              const Text('Nivo tezine',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildDifficultyOption('Pocetni', 0, Colors.green),
                  const SizedBox(width: 10),
                  _buildDifficultyOption('Srednji', 1, Colors.orange),
                  const SizedBox(width: 10),
                  _buildDifficultyOption('Napredni', 2, Colors.red),
                ],
              ),
              const SizedBox(height: 16),

              // Rating info (read-only)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _infoRow('Ocjena',
                    '${widget.course.averageRating.toStringAsFixed(1)} (${widget.course.reviewCount} recenzija)'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOption(String label, int value, Color color) {
    final isSelected = _selectedDifficulty == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDifficulty = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
