import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Beautiful cashflow chart with floating tooltip on tap
class BeautifulCashflowChart extends StatefulWidget {
  final List<double> cashflowData; // 90 days of data
  final Map<int, Map<String, dynamic>>? detailedData; // Index -> {client, amount, date, type}

  const BeautifulCashflowChart({
    Key? key,
    required this.cashflowData,
    this.detailedData,
  }) : super(key: key);

  @override
  State<BeautifulCashflowChart> createState() => _BeautifulCashflowChartState();
}

class _BeautifulCashflowChartState extends State<BeautifulCashflowChart> {
  int? selectedSpotIndex;
  Offset? touchPos;

  @override
  void initState() {
    super.initState();
  }

  // Generate spots from data - 1 point per 3 days
  List<FlSpot> getSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < widget.cashflowData.length; i += 3) {
      spots.add(FlSpot((i / 3).toDouble(), widget.cashflowData[i]));
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
    final maxValue = widget.cashflowData.isNotEmpty
        ? widget.cashflowData.reduce((a, b) => a > b ? a : b)
        : 1000000;
    final minValue = widget.cashflowData.isNotEmpty
        ? widget.cashflowData.reduce((a, b) => a < b ? a : b)
        : 0;

    return Column(
      children: [
        const Text(
          'Cashflow Timeline',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hover over points to view details',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 380,
              padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (widget.cashflowData.length / 3).toDouble(),
                  minY: minValue.toDouble(),
                  maxY: maxValue.toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: ((maxValue - minValue) / 4).abs() > 0 ? ((maxValue - minValue) / 4).abs() : 1000,
                    verticalInterval: 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 0.8,
                        dashArray: [5, 5],
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.05),
                        strokeWidth: 0.5,
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
                        reservedSize: 60,
                        interval: ((maxValue - minValue) / 4).abs() > 0 ? ((maxValue - minValue) / 4).abs() : 1000,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            formatCurrency(value),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
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
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'D${(value * 3).toInt()}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1.2,
                      ),
                      left: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1.2,
                      ),
                      right: BorderSide(
                        color: Colors.transparent,
                      ),
                      top: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.4,
                      color: const Color(0xFF66BB6A), // Light Green
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final hasDetails = widget.detailedData?.containsKey(
                                  (spot.x * 3).toInt()) ??
                              false;
                          final isSelected = selectedSpotIndex == (spot.x * 3).toInt();

                          return FlDotCirclePainter(
                            radius: isSelected ? 5 : 3.5,
                            color: Colors.white,
                            strokeWidth: isSelected ? 2.5 : 1.5,
                            strokeColor: const Color(0xFF66BB6A), // Light Green
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF66BB6A).withOpacity(0.15),
                            const Color(0xFF66BB6A).withOpacity(0.01),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                      setState(() {
                        // Show tooltip on hover/touch
                        if (response?.lineBarSpots != null && response!.lineBarSpots!.isNotEmpty) {
                          final spotIndex = (response.lineBarSpots!.first.x * 3).toInt();
                          final details = widget.detailedData?[spotIndex];
                          if (details != null) {
                            selectedSpotIndex = spotIndex;
                            touchPos = event.localPosition;
                          }
                        } else {
                          // Clear selection when not hovering over any spot
                          selectedSpotIndex = null;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            // Floating Tooltip
            if (selectedSpotIndex != null && widget.detailedData?.containsKey(selectedSpotIndex) == true)
              _buildFloatingTooltip(widget.detailedData![selectedSpotIndex]!),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingTooltip(Map<String, dynamic> details) {
    final partyName = details['client'] ?? 'Unknown';
    final amount = details['amount'] ?? 0;
    final date = details['date'] ?? 'Unknown';

    return Positioned(
      top: 20,
      right: 20,
      child: GestureDetector(
        onTap: () {
          setState(() => selectedSpotIndex = null);
        },
        child: Container(
          constraints: const BoxConstraints(maxWidth: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF66BB6A).withOpacity(0.25),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF66BB6A).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with green accent
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF66BB6A),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Party Name',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.85),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              partyName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => selectedSpotIndex = null);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Details
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF66BB6A).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Amount',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatCurrency(amount.toDouble()),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF66BB6A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF66BB6A).withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Due Date',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              date,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
