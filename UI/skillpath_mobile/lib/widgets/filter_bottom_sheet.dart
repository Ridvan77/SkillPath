import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

/// Full filter bottom sheet with multi-select support.
/// Filters: category, difficulty, price range, instructor.
class FilterBottomSheet extends StatefulWidget {
  final VoidCallback onApply;
  const FilterBottomSheet({super.key, required this.onApply});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  Set<int> _selectedCategories = {};
  Set<int> _selectedDifficulties = {};
  RangeValues _priceRange = const RangeValues(0, 1000);
  Set<String> _selectedInstructorIds = {};

  List<_InstructorOption> _instructors = [];
  List<_InstructorOption> _filteredInstructors = [];
  bool _instructorsLoaded = false;
  final _instructorSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cp = context.read<CourseProvider>();

    // Restore current filters from multi-select state
    _selectedCategories = Set.from(cp.selectedCategoryIds);
    _selectedDifficulties = Set.from(cp.selectedDifficultyLevels);
    _priceRange = RangeValues(
      cp.minPrice ?? 0,
      cp.maxPrice ?? 1000,
    );
    _selectedInstructorIds = Set.from(cp.selectedInstructorIds);

    _instructorSearchController.addListener(_filterInstructors);
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    try {
      // Load instructors from courses (public endpoint, no auth needed)
      final response = await ApiClient.get('/api/Course?pageSize=100');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List? ?? [];

        // Extract unique instructors from courses
        final instructorMap = <String, String>{};
        for (final course in items) {
          final id = course['instructorId'] as String?;
          final name = course['instructorName'] as String?;
          if (id != null && name != null) {
            instructorMap[id] = name;
          }
        }

        setState(() {
          _instructors = instructorMap.entries
              .map((e) => _InstructorOption(id: e.key, name: e.value))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          _filteredInstructors = List.from(_instructors);
          _instructorsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load instructors: $e');
      setState(() => _instructorsLoaded = true);
    }
  }

  void _filterInstructors() {
    final query = _instructorSearchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredInstructors = List.from(_instructors);
      } else {
        _filteredInstructors = _instructors
            .where((i) => i.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _instructorSearchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedCategories = {};
      _selectedDifficulties = {};
      _priceRange = const RangeValues(0, 1000);
      _selectedInstructorIds = {};
      _instructorSearchController.clear();
      _filteredInstructors = List.from(_instructors);
    });
  }

  void _apply() {
    final cp = context.read<CourseProvider>();

    // Apply multi-select filters (client-side filtering)
    cp.applyFilters(
      categoryIds: _selectedCategories,
      difficultyLevels: _selectedDifficulties,
      instructorIds: _selectedInstructorIds,
      minPrice: _priceRange.start,
      maxPrice: _priceRange.end,
    );
    widget.onApply();
  }

  void _toggleCategory(int id) {
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.remove(id);
      } else {
        _selectedCategories.add(id);
      }
    });
  }

  void _toggleDifficulty(int value) {
    setState(() {
      if (_selectedDifficulties.contains(value)) {
        _selectedDifficulties.remove(value);
      } else {
        _selectedDifficulties.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.read<CategoryProvider>().categories;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title + Reset
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filteri',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _resetFilters,
                    child: const Text('Resetuj'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---- 1. Kategorija (multi-select) ----
              _sectionTitle('Kategorija'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _selectedCategories.contains(cat.id);
                  return _buildChip(
                    label: cat.name,
                    isSelected: isSelected,
                    onTap: () => _toggleCategory(cat.id),
                  );
                }).toList(),
              ),
              if (_selectedCategories.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Sve kategorije',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              const SizedBox(height: 24),

              // ---- 2. Nivo tezine (multi-select) ----
              _sectionTitle('Nivo tezine'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildDifficultyChip('Pocetni', 0, Colors.green),
                  _buildDifficultyChip('Srednji', 1, Colors.orange),
                  _buildDifficultyChip('Napredni', 2, Colors.red),
                ],
              ),
              if (_selectedDifficulties.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Svi nivoi',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
              const SizedBox(height: 24),

              // ---- 3. Cijena ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Cijena'),
                  Text(
                    '${_priceRange.start.round()} - ${_priceRange.end.round()} KM',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5B5FC7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 1000,
                divisions: 20,
                activeColor: const Color(0xFF5B5FC7),
                labels: RangeLabels(
                  '${_priceRange.start.round()} KM',
                  '${_priceRange.end.round()} KM',
                ),
                onChanged: (v) => setState(() => _priceRange = v),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0 KM', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    Text('1000 KM', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ---- 4. Predavac (searchable multi-select) ----
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Predavac'),
                  if (_selectedInstructorIds.isNotEmpty)
                    Text(
                      '${_selectedInstructorIds.length} odabrano',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF5B5FC7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Search field
              TextField(
                controller: _instructorSearchController,
                decoration: InputDecoration(
                  hintText: 'Pretrazi predavace...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Selected instructors shown as removable chips
              if (_selectedInstructorIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedInstructorIds.map((id) {
                      final name = _instructors
                          .where((i) => i.id == id)
                          .map((i) => i.name)
                          .firstOrNull ?? id;
                      return Chip(
                        label: Text(name, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white70),
                        onDeleted: () => setState(() => _selectedInstructorIds.remove(id)),
                        backgroundColor: const Color(0xFF5B5FC7),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ),
              // Instructor list
              if (!_instructorsLoaded)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )),
                )
              else if (_filteredInstructors.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _instructorSearchController.text.isEmpty
                        ? 'Nema dostupnih predavaca.'
                        : 'Nema rezultata za "${_instructorSearchController.text}"',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                )
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _filteredInstructors.length,
                    itemBuilder: (_, index) {
                      final instructor = _filteredInstructors[index];
                      final isSelected = _selectedInstructorIds.contains(instructor.id);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedInstructorIds.remove(instructor.id);
                            } else {
                              _selectedInstructorIds.add(instructor.id);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF5B5FC7).withOpacity(0.06)
                                : null,
                            border: index < _filteredInstructors.length - 1
                                ? Border(bottom: BorderSide(color: Colors.grey.shade100))
                                : null,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isSelected
                                    ? const Color(0xFF5B5FC7).withOpacity(0.15)
                                    : Colors.grey.shade200,
                                child: Icon(
                                  isSelected ? Icons.check : Icons.person,
                                  size: 14,
                                  color: isSelected
                                      ? const Color(0xFF5B5FC7)
                                      : Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                instructor.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF5B5FC7)
                                      : Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 32),

              // ---- Buttons ----
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B5FC7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _apply,
                  child: Text(
                    _activeFilterCount > 0
                        ? 'Primijeni filtere ($_activeFilterCount)'
                        : 'Primijeni filtere',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int get _activeFilterCount {
    int count = 0;
    count += _selectedCategories.length;
    count += _selectedDifficulties.length;
    if (_priceRange.start > 0 || _priceRange.end < 1000) count++;
    count += _selectedInstructorIds.length;
    return count;
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B5FC7) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B5FC7) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(String label, int value, Color color) {
    final isSelected = _selectedDifficulties.contains(value);
    return GestureDetector(
      onTap: () => _toggleDifficulty(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructorOption {
  final String id;
  final String name;
  _InstructorOption({required this.id, required this.name});
}
