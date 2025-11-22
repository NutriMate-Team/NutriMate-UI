import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WeightChart extends StatelessWidget {
  // Bạn có thể truyền danh sách cân nặng lịch sử vào đây
  // final List<double> weightHistory; 
  
  const WeightChart({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    // Giả lập ngày
                    return Text('Day ${value.toInt()}'); 
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: 6, // 7 ngày
            minY: 40,
            maxY: 100,
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  // Dữ liệu giả lập (sau này lấy từ API)
                  FlSpot(0, 65),
                  FlSpot(1, 64.5),
                  FlSpot(2, 64.8),
                  FlSpot(3, 64.2),
                  FlSpot(4, 64.0),
                  FlSpot(5, 63.8),
                  FlSpot(6, 63.5),
                ],
                isCurved: true,
                gradient: const LinearGradient(colors: [Colors.green, Colors.blue]),
                barWidth: 5,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [Colors.green.withOpacity(0.3), Colors.blue.withOpacity(0.3)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}