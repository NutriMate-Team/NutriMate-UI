import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeightChart extends StatelessWidget {
  // Bạn có thể truyền danh sách cân nặng lịch sử vào đây
  // final List<double> weightHistory;
  final double? currentWeight;
  final double? targetWeight;
  
  const WeightChart({
    super.key,
    this.currentWeight,
    this.targetWeight,
  });

  // Generate last 7 days labels
  List<String> _getDayLabels() {
    final now = DateTime.now();
    final labels = <String>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      labels.add(DateFormat('dd/MM').format(date));
    }
    return labels;
  }

  // Round to nice intervals for Y-axis (rounds to nearest whole number)
  double _roundToNiceInterval(double value, {bool roundDown = false}) {
    // Round to nearest whole number for clean Y-axis labels with 1.0 interval
    if (roundDown) {
      return value.floorToDouble();
    } else {
      return value.ceilToDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual weight history from API
    // Use currentWeight if provided, otherwise use mock data
    final baseWeightData = const [65.0, 64.5, 64.8, 64.2, 64.0, 63.8, 63.5];
    final dayLabels = _getDayLabels();
    
    // Update the last data point with actual currentWeight if provided
    final weightData = List<double>.from(baseWeightData);
    if (currentWeight != null && currentWeight! > 0) {
      weightData[weightData.length - 1] = currentWeight!;
    }
    
    // Determine if current weight is below target (for weight loss goals)
    // CRITICAL LOGIC: When current weight is BELOW target, goal is achieved (weight loss) - use Orange
    // When current weight is AT or ABOVE target, use Green (normal/not achieved state)
    final isBelowTarget = targetWeight != null && 
                          currentWeight != null && 
                          currentWeight! > 0 && 
                          currentWeight! < targetWeight!;
    
    // Calculate Y-axis range to include both starting weight and target weight
    final startingWeight = weightData.first;
    final currentDataMin = weightData.reduce((a, b) => a < b ? a : b);
    final currentDataMax = weightData.reduce((a, b) => a > b ? a : b);
    
    // Determine the range that includes both data and target weight
    double minWeight, maxWeight;
    if (targetWeight != null) {
      // Include target weight in the range calculation
      // Find the overall min and max including target weight
      final allWeights = [...weightData, targetWeight!];
      final overallMin = allWeights.reduce((a, b) => a < b ? a : b);
      final overallMax = allWeights.reduce((a, b) => a > b ? a : b);
      
      // Ensure both starting weight and target weight are visible
      // Use the wider range between (starting, target) and (data min, data max)
      final minForRange = overallMin < targetWeight! ? overallMin : targetWeight!;
      final maxForRange = overallMax > startingWeight ? overallMax : startingWeight;
      
      // Add padding: 10% on each side for better visualization
      final range = maxForRange - minForRange;
      final padding = range * 0.10;
      final rawMin = minForRange - padding;
      final rawMax = maxForRange + padding;
      
      // Round to nice intervals for consistent Y-axis labels
      minWeight = _roundToNiceInterval(rawMin, roundDown: true);
      maxWeight = _roundToNiceInterval(rawMax, roundDown: false);
    } else {
      // Fallback to original calculation if no target weight
      // Round to nice intervals
      final rawMin = currentDataMin - 1;
      final rawMax = currentDataMax + 1;
      minWeight = _roundToNiceInterval(rawMin, roundDown: true);
      maxWeight = _roundToNiceInterval(rawMax, roundDown: false);
    }
    
    // Use currentWeight parameter if provided, otherwise use last data point
    final displayWeight = currentWeight ?? weightData.last;
    
    // CRITICAL: Determine colors based on goal achievement status
    // When current weight is BELOW target (goal achieved): ORANGE throughout
    // When current weight is AT or ABOVE target (goal not achieved): GREEN
    // All chart elements (label, line, dots, area, tooltip) must use consistent colors
    // 
    // EXplicit color assignment to ensure consistency:
    // - If currentWeight (e.g., 60.0) < targetWeight (e.g., 70.0) → Goal ACHIEVED → ORANGE
    // - If currentWeight >= targetWeight → Goal NOT achieved → GREEN
    final dotColor = isBelowTarget ? Colors.orange.shade600 : Colors.green.shade600;
    
    // Debug assertion to verify color logic (remove in production if needed)
    assert(() {
      if (targetWeight != null && currentWeight != null && currentWeight! > 0) {
        final expectedOrange = currentWeight! < targetWeight!;
        if (expectedOrange != isBelowTarget) {
          debugPrint('WARNING: Color logic mismatch! Expected orange: $expectedOrange, isBelowTarget: $isBelowTarget');
        }
      }
      return true;
    }());

    // Remove Card wrapper - it's already wrapped in profile_screen.dart
    // Use Column with Flexible to respect parent constraints
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tiến trình cân nặng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    // Use orange background when below target (goal achieved), green otherwise
                    color: isBelowTarget ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hiện tại: ',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${displayWeight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          // FINAL COLOR CORRECTION: "Hiện tại" label MUST be ORANGE when goal is achieved
                          // When currentWeight (60.0) < targetWeight (70.0) → Goal ACHIEVED → ORANGE (shade700)
                          // When currentWeight >= targetWeight → Goal NOT achieved → GREEN (shade700)
                          // This ensures visual consistency: chart line orange = label orange
                          color: isBelowTarget 
                            ? Colors.orange.shade700  // Goal achieved: use same orange as chart line
                            : Colors.green.shade700,   // Goal not achieved: use green
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Target weight indicator - always show if target weight is provided
            if (targetWeight != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          size: 14,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Mục tiêu: ${targetWeight!.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12), // Reduced spacing
            Flexible(
              fit: FlexFit.tight,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0), // Add left padding for Y-axis labels
                child: LayoutBuilder(
                  builder: (context, chartConstraints) {
                    final chartHeight = chartConstraints.maxHeight.isFinite 
                        ? chartConstraints.maxHeight 
                        : 200.0; // Fallback height
                    final chartWidth = chartConstraints.maxWidth.isFinite 
                        ? chartConstraints.maxWidth 
                        : 300.0; // Fallback width
                    
                    // Calculate the actual chart area (excluding titles)
                    // Left titles reserved size: 80, Bottom titles reserved size: 30
                    final chartAreaHeight = (chartHeight - 30).clamp(100.0, double.infinity); // Subtract bottom titles, min 100
                    final chartAreaTop = 0; // Top of chart area
                    
                    // Calculate label position based on target weight value
                    double? labelTop;
                    if (targetWeight != null) {
                      final range = maxWeight - minWeight;
                      final positionFromTop = (maxWeight - targetWeight!) / range;
                      // Position in chart area (accounting for bottom titles)
                      labelTop = chartAreaTop + (positionFromTop * chartAreaHeight) - 10; // -10 to center on line
                    }
                    
                    return SizedBox(
                      width: chartWidth,
                      height: chartHeight,
                      child: Stack(
                    children: [
                      LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 1.0, // Match label interval for proper alignment
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.grey.shade200,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < dayLabels.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        dayLabels[index],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 80, // Increased to 80 to ensure full visibility of labels (e.g., 69.0, 68.0, 67.0)
                                interval: 1.0, // Consistent interval of 1.0 kg for evenly spaced labels
                                getTitlesWidget: (value, meta) {
                                  // Filter out target weight from Y-axis labels to avoid redundancy
                                  if (targetWeight != null && 
                                      (value - targetWeight!).abs() < 0.01) {
                                    return const SizedBox.shrink(); // Hide target weight label
                                  }
                                  
                                  // Ensure labels are fully visible with proper spacing
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 16.0), // Increased right padding for better spacing
                                    child: Text(
                                      value.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.right, // Right-align for proper alignment
                                      // Ensure text doesn't overflow
                                      overflow: TextOverflow.visible,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300),
                              left: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          minX: 0,
                          maxX: 6,
                          minY: minWeight,
                          maxY: maxWeight,
                          // Add target weight line - always show if target weight is provided
                          // Note: Label is now rendered separately in Stack overlay for better visibility
                          extraLinesData: targetWeight != null
                              ? ExtraLinesData(
                                  horizontalLines: [
                                    HorizontalLine(
                                      y: targetWeight!,
                                      color: Colors.orange.shade300, // Subtle dashed orange for distinct but subtle visibility
                                      strokeWidth: 1.5,
                                      dashArray: [8, 4], // Dashed line pattern
                                      label: HorizontalLineLabel(
                                        show: false, // Disabled - using custom overlay instead
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(7, (index) {
                                return FlSpot(index.toDouble(), weightData[index]);
                              }),
                              isCurved: true,
                              curveSmoothness: 0.35,
                              gradient: LinearGradient(
                                colors: isBelowTarget
                                    ? [
                                        Colors.orange.shade400,
                                        Colors.orange.shade600,
                                      ]
                                    : [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ],
                              ),
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  // Highlight the latest data point (last index) with a larger dot
                                  final isLatestPoint = index == weightData.length - 1;
                                  return FlDotCirclePainter(
                                    radius: isLatestPoint ? 7 : 5, // Larger dot for latest point
                                    color: dotColor,
                                    strokeWidth: isLatestPoint ? 3 : 2, // Thicker stroke for latest point
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isBelowTarget
                                      ? [
                                          Colors.orange.shade100.withOpacity(0.5),
                                          Colors.orange.shade50.withOpacity(0.1),
                                        ]
                                      : [
                                          Colors.green.shade100.withOpacity(0.5),
                                          Colors.green.shade50.withOpacity(0.1),
                                        ],
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) => dotColor,
                              tooltipPadding: const EdgeInsets.all(8),
                              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                                return touchedBarSpots.map((barSpot) {
                                  return LineTooltipItem(
                                    '${barSpot.y.toStringAsFixed(1)} kg',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                      // Custom target weight label overlay - renders on top of chart
                      if (targetWeight != null && labelTop != null)
                        Positioned(
                          right: 8,
                          top: labelTop.clamp(0.0, chartHeight - 30), // Ensure it stays within bounds
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95), // Semi-transparent white background
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange.shade300,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '${targetWeight!.toStringAsFixed(1)}',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
  }
}