import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Advanced interactive cashflow chart with native zoom and click handling
class AdvancedCashflowChartV2 extends StatefulWidget {
  final List<double> cashflowData; // 90 days of data
  final Map<int, Map<String, dynamic>>? detailedData; // Index -> {client, amount, date}

  const AdvancedCashflowChartV2({
    Key? key,
    required this.cashflowData,
    this.detailedData,
  }) : super(key: key);

  @override
  State<AdvancedCashflowChartV2> createState() =>
      _AdvancedCashflowChartV2State();
}

class _AdvancedCashflowChartV2State extends State<AdvancedCashflowChartV2> {
  late double minX;
  late double maxX;
  Map<int, Map<String, dynamic>>? clickedPointData;

  @override
  void initState() {
    super.initState();
    // Show first 30 days initially
    minX = 0;
    maxX = 30;
  }

  // Generate spots from data - 1 point per 3 days for light spacing
  List<FlSpot> getSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < widget.cashflowData.length; i += 3) {
      spots.add(FlSpot(
        (i / 3).toDouble(),
        widget.cashflowData[i],
      ));
    }
    return spots;
  }

  // Format currency values
  String formatCurrency(double value) {
    if (value >= 10000000) return '₹${(value / 10000000).toStringAsFixed(1)}Cr';
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
    return '₹${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final spots = getSpots();
    final maxValue = widget.cashflowData.reduce((a, b) => a > b ? a : b);
    final minValue = widget.cashflowData.reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        // Chart Title with zoom info
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cashflow Timeline',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap points to see client details • Scroll to zoom',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Chart
        SizedBox(
          height: 280,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minValue * 0.9,
              maxY: maxValue * 1.1,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxValue - minValue) / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 0.8,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: (maxValue - minValue) / 4,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        formatCurrency(value),
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.right,
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      final dayNum = (value * 3).toInt();
                      return Text(
                        'D$dayNum',
                        style: const TextStyle(fontSize: 9),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF42A5F5),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isClicked = clickedPointData != null;
                      return FlDotCirclePainter(
                        radius: isClicked ? 5 : 4,
                        color: const Color(0xFF42A5F5),
                        strokeWidth: isClicked ? 2 : 1,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF42A5F5).withOpacity(0.3),
                        const Color(0xFF42A5F5).withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                )
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final dayIndex = (spot.x * 3).toInt();
                      final clientData = widget.detailedData?[dayIndex];

                      return LineTooltipItem(
                        clientData != null
                            ? '${clientData['client'] ?? 'Client'}\n${formatCurrency(clientData['amount'] ?? spot.y)}\n${clientData['date'] ?? 'D$dayIndex'}'
                            : '${formatCurrency(spot.y)}\nDay $dayIndex',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Zoom controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Viewing: Day 0 - ${maxX.toInt()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _zoomOut,
                    icon: const Icon(Icons.remove),
                    tooltip: 'Zoom Out',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _zoomIn,
                    icon: const Icon(Icons.add),
                    tooltip: 'Zoom In',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _zoomIn() {
    setState(() {
      final center = (minX + maxX) / 2;
      final newRange = (maxX - minX) / 1.5;
      minX = (center - newRange / 2).clamp(0, 30 - newRange);
      maxX = minX + newRange;
    });
  }

  void _zoomOut() {
    setState(() {
      if (maxX - minX >= 90) return; // Max zoom out
      final center = (minX + maxX) / 2;
      final newRange = (maxX - minX) * 1.5;
      minX = (center - newRange / 2).clamp(0, 90 - newRange);
      maxX = (minX + newRange).clamp(minX + 10, 90);
    });
  }
}
