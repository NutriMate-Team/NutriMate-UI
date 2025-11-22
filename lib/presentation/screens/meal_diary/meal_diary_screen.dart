import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; 

import '../../providers/meal_log_provider.dart';
import '../../../models/meal_log_model.dart';

class MealDiaryScreen extends StatefulWidget {
  const MealDiaryScreen({super.key});

  @override
  State<MealDiaryScreen> createState() => _MealDiaryScreenState();
}

class _MealDiaryScreenState extends State<MealDiaryScreen> {
  @override
  void initState() {
    super.initState();
    // Tải dữ liệu khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MealLogProvider>(context, listen: false).fetchLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký ăn uống'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black, // Chữ màu đen
      ),
      backgroundColor: Colors.grey[50],
      body: Consumer<MealLogProvider>(
        builder: (context, provider, child) {
          // 1. Loading
          if (provider.status == MealLogStatus.loading && provider.logs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error
          if (provider.status == MealLogStatus.error) {
            return Center(child: Text('Lỗi: ${provider.errorMessage}'));
          }

          // 3. Empty
          if (provider.logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.no_meals, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có nhật ký hôm nay', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 4. List Data (Có Refresh)
          return RefreshIndicator(
            onRefresh: () => provider.fetchLogs(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.logs.length,
              itemBuilder: (context, index) {
                final log = provider.logs[index];
                return _buildLogItem(log, provider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogItem(MealLogModel log, MealLogProvider provider) {
    // Format ngày giờ
    String timeStr = "00:00";
    String dateStr = "Today";
    try {
      timeStr = DateFormat('HH:mm').format(log.loggedAt.toLocal());
      dateStr = DateFormat('dd/MM').format(log.loggedAt.toLocal());
    } catch (e) {
      // Fallback nếu lỗi format
    }

    return Dismissible(
      key: Key(log.id), // Key duy nhất để xác định item xóa
      direction: DismissDirection.endToStart, // Chỉ vuốt từ Phải sang Trái
      
      // Giao diện Thùng rác (hiện ra khi vuốt)
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            Text("Xóa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ],
        ),
      ),
      
      // Logic khi vuốt xong
      onDismissed: (direction) {
        provider.deleteLog(log.id, context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa ${log.food?.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },

      // Giao diện thẻ món ăn
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: _getMealTypeColor(log.mealType).withOpacity(0.2),
            child: Icon(
              Icons.restaurant, 
              color: _getMealTypeColor(log.mealType),
              size: 20,
            ),
          ),
          title: Text(
            log.food?.name ?? 'Món ăn',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('${log.quantity} g • ${log.mealType}'),
              Text(
                '$timeStr • $dateStr',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Text(
            '${log.totalCalories?.toStringAsFixed(0) ?? 0} kcal',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
        ),
      ),
    );
  }

  Color _getMealTypeColor(String type) {
    switch (type) {
      case 'Bữa sáng': return Colors.orange;
      case 'Bữa trưa': return Colors.blue;
      case 'Bữa tối': return Colors.purple;
      case 'Ăn nhẹ': return Colors.green;
      default: return Colors.grey;
    }
  }
}