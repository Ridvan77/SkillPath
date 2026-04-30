import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../providers/instructor_provider.dart';

class InstructorReservationsScreen extends StatefulWidget {
  const InstructorReservationsScreen({super.key});

  @override
  State<InstructorReservationsScreen> createState() =>
      _InstructorReservationsScreenState();
}

class _InstructorReservationsScreenState
    extends State<InstructorReservationsScreen> {
  final Set<String> _expandedCourses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      context.read<InstructorProvider>().fetchInstructorCourses(userId);
    }
  }

  String _dayOfWeekLabel(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return 'Ponedjeljak';
      case 'tuesday':
        return 'Utorak';
      case 'wednesday':
        return 'Srijeda';
      case 'thursday':
        return 'Cetvrtak';
      case 'friday':
        return 'Petak';
      case 'saturday':
        return 'Subota';
      case 'sunday':
        return 'Nedjelja';
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Raspored i upisi'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: Consumer<InstructorProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.courses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.courses.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Nemate kurseva sa rasporedima.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Filter to courses that have schedules
            final coursesWithSchedules =
                provider.courses.where((c) => c.schedules.isNotEmpty).toList();

            if (coursesWithSchedules.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Nema dostupnih rasporeda.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: coursesWithSchedules.length,
              itemBuilder: (context, index) {
                final course = coursesWithSchedules[index];
                final isExpanded = _expandedCourses.contains(course.id);
                final totalEnrolled = course.schedules
                    .fold<int>(0, (sum, s) => sum + s.currentEnrollment);
                final totalCapacity = course.schedules
                    .fold<int>(0, (sum, s) => sum + s.maxCapacity);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Course header (tappable to expand)
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedCourses.remove(course.id);
                            } else {
                              _expandedCourses.add(course.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF1A237E).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.menu_book,
                                    color: Color(0xFF1A237E), size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      course.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$totalEnrolled / $totalCapacity upisanih  |  ${course.schedules.length} termina',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Enrollment progress indicator
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: totalCapacity > 0
                                          ? totalEnrolled / totalCapacity
                                          : 0,
                                      strokeWidth: 3,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation(
                                        totalEnrolled >= totalCapacity
                                            ? Colors.red
                                            : Colors.teal,
                                      ),
                                    ),
                                    Text(
                                      totalCapacity > 0
                                          ? '${(totalEnrolled / totalCapacity * 100).round()}%'
                                          : '0%',
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Expanded schedule list
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        ...course.schedules.map((schedule) {
                          final fillPercent = schedule.maxCapacity > 0
                              ? schedule.currentEnrollment /
                                  schedule.maxCapacity
                              : 0.0;
                          final isFull = schedule.isFull;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 16,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_dayOfWeekLabel(schedule.dayOfWeek)} ${schedule.startTime} - ${schedule.endTime}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isFull
                                            ? Colors.red.shade50
                                            : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isFull ? 'Popunjen' : 'Slobodno',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isFull
                                              ? Colors.red.shade700
                                              : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('dd.MM.yyyy').format(schedule.startDate)} - ${DateFormat('dd.MM.yyyy').format(schedule.endDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Enrollment bar
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: fillPercent,
                                          minHeight: 8,
                                          backgroundColor:
                                              Colors.grey.shade200,
                                          valueColor:
                                              AlwaysStoppedAnimation(
                                            isFull
                                                ? Colors.red
                                                : Colors.teal,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${schedule.currentEnrollment}/${schedule.maxCapacity}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
