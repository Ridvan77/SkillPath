import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../config/theme.dart';
import '../../providers/course_management_provider.dart';
import '../../widgets/loading_widget.dart';

class CourseFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingCourse;

  const CourseFormScreen({super.key, this.existingCourse});

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _isSaving = false;
  bool _loadingDropdowns = true;

  // Form fields
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _shortDescCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  int _difficultyLevel = 0;
  bool _isFeatured = false;
  bool _isUploadingImage = false;
  int? _selectedCategoryId;
  String? _selectedInstructorId;

  // Schedules
  List<_ScheduleEntry> _scheduleEntries = [];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.existingCourse != null;
    if (_isEdit) {
      _populateFields();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CourseManagementProvider>().fetchDropdownData();
      if (_isEdit) {
        final courseId = widget.existingCourse!['id']?.toString() ?? '';
        if (courseId.isNotEmpty) {
          await context
              .read<CourseManagementProvider>()
              .fetchSchedules(courseId);
          final schedules =
              context.read<CourseManagementProvider>().schedules;
          setState(() {
            _scheduleEntries = schedules
                .map((s) => _ScheduleEntry(
                      id: s.id,
                      dayOfWeek: s.dayOfWeek,
                      startTime: s.startTime,
                      endTime: s.endTime,
                      startDate: s.startDate,
                      endDate: s.endDate,
                      maxCapacity: s.maxCapacity,
                    ))
                .toList();
          });
        }
      }
      if (mounted) setState(() => _loadingDropdowns = false);
    });
  }

  void _populateFields() {
    final c = widget.existingCourse!;
    _titleCtrl.text = c['title'] as String? ?? '';
    _descCtrl.text = c['description'] as String? ?? '';
    _shortDescCtrl.text = c['shortDescription'] as String? ?? '';
    _priceCtrl.text = (c['price'] as num?)?.toString() ?? '';
    _durationCtrl.text = (c['durationWeeks'] as num?)?.toString() ?? '';
    _imageUrlCtrl.text = c['imageUrl'] as String? ?? '';
    _isFeatured = c['isFeatured'] as bool? ?? false;
    _selectedCategoryId = c['categoryId'] as int?;
    _selectedInstructorId = c['instructorId'] as String?;

    final diff = c['difficultyLevel'];
    if (diff is int) {
      _difficultyLevel = diff;
    } else if (diff is String) {
      const levels = ['Beginner', 'Intermediate', 'Advanced'];
      final idx = levels.indexWhere(
          (l) => l.toLowerCase() == diff.toLowerCase());
      _difficultyLevel = idx >= 0 ? idx : 0;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _shortDescCtrl.dispose();
    _priceCtrl.dispose();
    _durationCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final filePath = result.files.single.path!;
      final response =
          await ApiClient.uploadFile('/api/Course/upload-image', filePath);

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final data = jsonDecode(body) as Map<String, dynamic>;
        setState(() {
          _imageUrlCtrl.text = data['imageUrl'] as String? ?? '';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Greška pri uploadu slike (${response.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e')),
        );
      }
    }

    if (mounted) setState(() => _isUploadingImage = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = context.read<CourseManagementProvider>();

    final data = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'shortDescription': _shortDescCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 0,
      'durationWeeks': int.tryParse(_durationCtrl.text) ?? 1,
      'difficultyLevel': _difficultyLevel,
      'imageUrl': _imageUrlCtrl.text.trim().isNotEmpty
          ? _imageUrlCtrl.text.trim()
          : null,
      'isFeatured': _isFeatured,
      'categoryId': _selectedCategoryId,
      'instructorId': _selectedInstructorId,
    };

    bool success;
    String? courseId;
    if (_isEdit) {
      courseId = widget.existingCourse!['id']?.toString() ?? '';
      success = await provider.updateCourse(courseId, data);
    } else {
      courseId = await provider.createCourse(data);
      success = courseId != null;
    }

    if (success && courseId != null && mounted) {
      // Save schedules
      for (final entry in _scheduleEntries) {
        final scheduleData = {
          'courseId': courseId,
          'dayOfWeek': entry.dayOfWeek,
          'startTime': entry.startTime,
          'endTime': entry.endTime,
          'startDate': entry.startDate.toIso8601String(),
          'endDate': entry.endDate.toIso8601String(),
          'maxCapacity': entry.maxCapacity,
        };
        await provider.createSchedule(scheduleData);
      }

      provider.fetchCourses(page: 1);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isEdit ? 'Kurs uspjesno azuriran' : 'Kurs uspjesno kreiran'),
        ),
      );
    }

    if (mounted) setState(() => _isSaving = false);
  }

  void _addScheduleEntry() {
    setState(() {
      _scheduleEntries.add(_ScheduleEntry(
        dayOfWeek: 1,
        startTime: '09:00',
        endTime: '11:00',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 90)),
        maxCapacity: 20,
      ));
    });
  }

  void _removeScheduleEntry(int index) {
    setState(() => _scheduleEntries.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.contentBackground,
      appBar: AppBar(
        title: Text(_isEdit ? 'Uredi kurs' : 'Novi kurs'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEdit ? 'Sacuvaj' : 'Kreiraj'),
            ),
          ),
        ],
      ),
      body: _loadingDropdowns
          ? const LoadingWidget(message: 'Ucitavanje...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column - main fields
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionCard(
                            title: 'Osnovni podaci',
                            children: [
                              TextFormField(
                                controller: _titleCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Naziv kursa'),
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Obavezno polje'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _shortDescCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Kratak opis'),
                                maxLines: 2,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Obavezno polje'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Puni opis (opcionalno)'),
                                maxLines: 5,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _sectionCard(
                            title: 'Raspored',
                            children: [
                              if (_scheduleEntries.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Nema rasporeda. Dodajte termin.',
                                    style: AppTheme.bodySmall,
                                  ),
                                ),
                              for (int i = 0;
                                  i < _scheduleEntries.length;
                                  i++) ...[
                                _buildScheduleRow(i),
                                if (i < _scheduleEntries.length - 1)
                                  const Divider(height: 24),
                              ],
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _addScheduleEntry,
                                icon:
                                    const Icon(Icons.add_rounded, size: 18),
                                label: const Text('Dodaj termin'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right column - metadata
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionCard(
                            title: 'Detalji',
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _priceCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Cijena (KM)',
                                        prefixIcon:
                                            Icon(Icons.payments_rounded),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (v) =>
                                          v == null || v.isEmpty
                                              ? 'Obavezno'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _durationCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Trajanje (sedmica)',
                                        prefixIcon:
                                            Icon(Icons.timer_rounded),
                                      ),
                                      keyboardType: TextInputType.number,
                                      validator: (v) =>
                                          v == null || v.isEmpty
                                              ? 'Obavezno'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Consumer<CourseManagementProvider>(
                                builder: (_, p, __) =>
                                    DropdownButtonFormField<int>(
                                  value: _selectedCategoryId,
                                  decoration: const InputDecoration(
                                      labelText: 'Kategorija'),
                                  items: p.categories.map((c) {
                                    return DropdownMenuItem<int>(
                                      value: c['id'] as int,
                                      child:
                                          Text(c['name'] as String? ?? ''),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(
                                      () => _selectedCategoryId = v),
                                  validator: (v) =>
                                      v == null ? 'Obavezno' : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Consumer<CourseManagementProvider>(
                                builder: (_, p, __) =>
                                    DropdownButtonFormField<String>(
                                  value: _selectedInstructorId,
                                  decoration: const InputDecoration(
                                      labelText: 'Instruktor'),
                                  items: p.instructors.map((u) {
                                    final name =
                                        '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'
                                            .trim();
                                    return DropdownMenuItem<String>(
                                      value: u['id'] as String,
                                      child: Text(
                                        name.isNotEmpty ? name : u['email'] as String? ?? '',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(
                                      () => _selectedInstructorId = v),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Obavezno'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text('Nivo tezine',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _DifficultyRadio(
                                    label: 'Pocetni',
                                    value: 0,
                                    groupValue: _difficultyLevel,
                                    onChanged: (v) => setState(
                                        () => _difficultyLevel = v!),
                                  ),
                                  const SizedBox(width: 12),
                                  _DifficultyRadio(
                                    label: 'Srednji',
                                    value: 1,
                                    groupValue: _difficultyLevel,
                                    onChanged: (v) => setState(
                                        () => _difficultyLevel = v!),
                                  ),
                                  const SizedBox(width: 12),
                                  _DifficultyRadio(
                                    label: 'Napredni',
                                    value: 2,
                                    groupValue: _difficultyLevel,
                                    onChanged: (v) => setState(
                                        () => _difficultyLevel = v!),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _sectionCard(
                            title: 'Slika i opcije',
                            children: [
                              // Image preview
                              if (_imageUrlCtrl.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _imageUrlCtrl.text.startsWith('http')
                                          ? _imageUrlCtrl.text
                                          : '${ApiClient.baseUrl}${_imageUrlCtrl.text}',
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        height: 120,
                                        color: Colors.grey[200],
                                        child: const Center(
                                            child: Icon(Icons.broken_image,
                                                size: 40)),
                                      ),
                                    ),
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _imageUrlCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'URL slike',
                                        prefixIcon:
                                            Icon(Icons.image_rounded),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _isUploadingImage
                                        ? null
                                        : _pickAndUploadImage,
                                    icon: _isUploadingImage
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.upload_file_rounded,
                                            size: 18),
                                    label: Text(_isUploadingImage
                                        ? 'Upload...'
                                        : 'Odaberi'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                title: const Text('Istaknuti kurs'),
                                subtitle: const Text(
                                    'Prikazuje se na pocetnoj stranici'),
                                value: _isFeatured,
                                onChanged: (v) =>
                                    setState(() => _isFeatured = v),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Otkazi'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _save,
                                  child: Text(
                                      _isEdit ? 'Sacuvaj' : 'Kreiraj'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.headingSmall),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildScheduleRow(int index) {
    final entry = _scheduleEntries[index];
    const dayNames = [
      'Nedjelja',
      'Ponedjeljak',
      'Utorak',
      'Srijeda',
      'Cetvrtak',
      'Petak',
      'Subota'
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: entry.dayOfWeek,
            decoration: const InputDecoration(labelText: 'Dan'),
            items: List.generate(
              7,
              (i) => DropdownMenuItem(value: i, child: Text(dayNames[i])),
            ),
            onChanged: (v) =>
                setState(() => _scheduleEntries[index].dayOfWeek = v ?? 1),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: TextFormField(
            initialValue: entry.startTime,
            decoration: const InputDecoration(labelText: 'Od'),
            onChanged: (v) => _scheduleEntries[index].startTime = v,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: TextFormField(
            initialValue: entry.endTime,
            decoration: const InputDecoration(labelText: 'Do'),
            onChanged: (v) => _scheduleEntries[index].endTime = v,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: TextFormField(
            initialValue: entry.maxCapacity.toString(),
            decoration: const InputDecoration(labelText: 'Kapacitet'),
            keyboardType: TextInputType.number,
            onChanged: (v) =>
                _scheduleEntries[index].maxCapacity = int.tryParse(v) ?? 20,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: entry.startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _scheduleEntries[index].startDate = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Pocetak'),
              child: Text(
                DateFormat('dd.MM.yyyy').format(entry.startDate),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: entry.endDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _scheduleEntries[index].endDate = picked);
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Kraj'),
              child: Text(
                DateFormat('dd.MM.yyyy').format(entry.endDate),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.remove_circle_rounded, color: AppTheme.error),
          onPressed: () => _removeScheduleEntry(index),
          tooltip: 'Ukloni',
        ),
      ],
    );
  }
}

class _DifficultyRadio extends StatelessWidget {
  final String label;
  final int value;
  final int groupValue;
  final ValueChanged<int?> onChanged;

  const _DifficultyRadio({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<int>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _ScheduleEntry {
  String? id;
  int dayOfWeek;
  String startTime;
  String endTime;
  DateTime startDate;
  DateTime endDate;
  int maxCapacity;

  _ScheduleEntry({
    this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    required this.endDate,
    required this.maxCapacity,
  });
}
