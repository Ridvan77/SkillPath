import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/review_provider.dart';

class WriteReviewScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const WriteReviewScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _selectedRating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Odaberite ocjenu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final reviewProvider = context.read<ReviewProvider>();
    final success = await reviewProvider.createReview(
      widget.courseId,
      _selectedRating,
      _commentController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recenzija je uspjesno kreirana!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                reviewProvider.errorMessage ?? 'Greska prilikom kreiranja.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Napisi recenziju'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Name
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.05),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.school,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.courseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Rating Stars
              Text(
                'Vasa ocjena',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedRating = starIndex),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          starIndex <= _selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 48,
                          color: starIndex <= _selectedRating
                              ? Colors.amber
                              : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_selectedRating > 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _ratingLabel(_selectedRating),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Comment
              Text(
                'Vas komentar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 1000,
                decoration: const InputDecoration(
                  hintText: 'Podijelite vase iskustvo sa ovim kursom...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Unesite komentar.';
                  }
                  if (value.trim().length < 10) {
                    return 'Komentar mora imati najmanje 10 karaktera.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              Consumer<ReviewProvider>(
                builder: (context, reviewProvider, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          reviewProvider.isLoading ? null : _handleSubmit,
                      child: reviewProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Objavi recenziju'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Lose';
      case 2:
        return 'Ispod prosjeka';
      case 3:
        return 'Prosjecno';
      case 4:
        return 'Dobro';
      case 5:
        return 'Odlicno';
      default:
        return '';
    }
  }
}
