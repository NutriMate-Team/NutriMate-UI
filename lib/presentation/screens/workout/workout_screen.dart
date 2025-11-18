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
  @override
  void initState() {
    super.initState();
    // Tải danh sách bài tập khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WorkoutProvider>(context, listen: false).fetchExercises();
    });
  }

  // Hàm xử lý khi chọn bài tập
  void _onExerciseSelected(ExerciseModel exercise) {
    final durationController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ghi log: ${exercise.name}'),
        content: TextField(
          controller: durationController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Thời gian tập (phút)',
            hintText: 'Ví dụ: 30',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final minutes = double.tryParse(durationController.text);
              if (minutes == null || minutes <= 0) return;

              // 1. Đóng hộp thoại
              Navigator.of(ctx).pop();

              // 2. Gọi API Lưu
              final provider = Provider.of<WorkoutProvider>(context, listen: false);
              final dto = CreateWorkoutLogDto(
                exerciseId: exercise.id,
                durationMin: minutes,
              );

              final success = await provider.saveLog(dto);

              if (mounted) {
                if (success) {
                  // 3. Làm mới Dashboard và quay về
                  Provider.of<DashboardProvider>(context, listen: false).fetchSummary();
                  Navigator.of(context).pop(); // Quay về Dashboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã ghi nhận buổi tập!'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${provider.errorMessage}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
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

          return ListView.builder(
            itemCount: provider.exercises.length,
            itemBuilder: (context, index) {
              final exercise = provider.exercises[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(exercise.name[0]), // Ký tự đầu
                ),
                title: Text(exercise.name),
                subtitle: Text('${exercise.caloriesBurnedPerHour} calo/giờ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onExerciseSelected(exercise),
              );
            },
          );
        },
      ),
    );
  }
}