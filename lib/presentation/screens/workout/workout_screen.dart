import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/workout_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../models/exercise_model.dart';
import '../../../domain/entities/create_workout_log_dto.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    // Tải danh sách bài tập khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchExercises();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _iconForExercise(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('chạy') || lower.contains('run')) {
      return Icons.directions_run;
    }
    if (lower.contains('đạp') || lower.contains('xe') || lower.contains('bike')) {
      return Icons.directions_bike;
    }
    if (lower.contains('yoga')) {
      return Icons.self_improvement;
    }
    if (lower.contains('bơi')) {
      return Icons.pool;
    }
    if (lower.contains('tạ') || lower.contains('gym') || lower.contains('strength')) {
      return Icons.fitness_center;
    }
    if (lower.contains('đi bộ') || lower.contains('walk')) {
      return Icons.directions_walk;
    }
    return Icons.sports_motorsports;
  }

  double _calculateEstimatedCalories(double caloriesPerHour, double minutes) {
    if (minutes <= 0) return 0;
    return caloriesPerHour * (minutes / 60);
  }

  Widget _buildDialogStepper({required IconData icon, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: const Color(0xFFE0F2F1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(
              icon,
              color: const Color(0xFF00BFA5),
            ),
          ),
        ),
      ),
    );
  }

  // Hàm xử lý khi chọn bài tập
  void _onExerciseSelected(ExerciseModel exercise) {
    final durationController = TextEditingController(text: '30');
    double currentMinutes = 30;
    double estimatedCalories = _calculateEstimatedCalories(
      exercise.caloriesBurnedPerHour,
      currentMinutes,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          void updateMinutes(double minutes) {
            currentMinutes = minutes.clamp(0, 600);
            durationController.value = durationController.value.copyWith(
              text: currentMinutes.toStringAsFixed(0),
              selection: TextSelection.collapsed(
                offset: currentMinutes.toStringAsFixed(0).length,
              ),
            );
            estimatedCalories = _calculateEstimatedCalories(
              exercise.caloriesBurnedPerHour,
              currentMinutes,
            );
            setStateDialog(() {});
          }

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ghi log: ${exercise.name}'),
                const SizedBox(height: 4),
                Text(
                  '${exercise.caloriesBurnedPerHour.toStringAsFixed(0)} calo/giờ',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thời lượng (phút)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildDialogStepper(
                      icon: Icons.remove,
                      onTap: () {
                        final value = double.tryParse(durationController.text) ?? 0;
                        updateMinutes((value - 5).clamp(0, 600));
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'Bạn đã tập bao nhiêu phút?',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                        onChanged: (value) {
                          final minutes = double.tryParse(value) ?? 0;
                          updateMinutes(minutes);
                        },
                      ),
                    ),
                    _buildDialogStepper(
                      icon: Icons.add,
                      onTap: () {
                        final value = double.tryParse(durationController.text) ?? 0;
                        updateMinutes((value + 5).clamp(0, 600));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Calo đốt cháy dự kiến: ${estimatedCalories.toStringAsFixed(0)} calo',
                  style: const TextStyle(
                    color: Color(0xFFFF7043),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                child: const Text(
                  'Hủy',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () async {
                  final minutes = double.tryParse(durationController.text);
                  if (minutes == null || minutes <= 0) return;

                  Navigator.of(ctx).pop();

                  final provider = Provider.of<WorkoutProvider>(context, listen: false);
                  final dto = CreateWorkoutLogDto(
                    exerciseId: exercise.id,
                    durationMin: minutes,
                  );

                  final success = await provider.saveLog(dto);

                  if (mounted) {
                    if (success) {
                      Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã ghi nhận buổi tập!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: ${provider.errorMessage}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Lưu'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn bài tập')),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.status == WorkoutStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.status == WorkoutStatus.error) {
            return Center(child: Text('Lỗi: ${provider.errorMessage}'));
          }

          if (provider.exercises.isEmpty) {
            return const Center(child: Text('Không có bài tập nào.'));
          }

          final filteredExercises = provider.exercises.where((exercise) {
            if (_searchQuery.isEmpty) return true;
            return exercise.name.toLowerCase().contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm bài tập...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredExercises.isEmpty
                    ? const Center(
                        child: Text('Không tìm thấy bài tập phù hợp.'),
                      )
                    : ListView.builder(
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 3,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _onExerciseSelected(exercise),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2F1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(
                                          _iconForExercise(exercise.name),
                                          color: const Color(0xFF00BFA5),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.local_fire_department,
                                                  size: 18,
                                                  color: Color(0xFFFF7043),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  '${exercise.caloriesBurnedPerHour.toStringAsFixed(0)} calo/giờ',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFFFF7043),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}