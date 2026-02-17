import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Advanced interactive cashflow chart with zoom and scroll capabilities
class AdvancedCashflowChart extends StatefulWidget {
  final List<FlSpot> spots;
  final List<String> dateLabels;
  final List<String> clientDetails; // Client names for each date
  final double initialStartDay;
  final double visibleDaysRange;

  const AdvancedCashflowChart({
    Key? key,
    required this.spots,
    required this.dateLabels,
    required this.clientDetails,
    this.initialStartDay = 30,
    this.visibleDaysRange = 15,
  }) : super(key: key);

  @override
  State<AdvancedCashflowChart> createState() => _AdvancedCashflowChartState();
}

class _AdvancedCashflowChartState extends State<AdvancedCashflowChart> {
  late double startDay;
  late double visibleRange;
  late double _scrollPosition;

  @override
  void initState() {
    super.initState();
    startDay = widget.initialStartDay;
    visibleRange = widget.visibleDaysRange;
    _scrollPosition = widget.initialStartDay;
  }

  List<FlSpot> getVisibleSpots() {
    return widget.spots
        .where((spot) => spot.x >= startDay && spot.x < startDay + visibleRange)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Header with zoom controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cashflow Timeline',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Swipe to scroll • Pinch to zoom',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ],
              ),
              // Zoom buttons
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outline.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: visibleRange < 30
                          ? () => setState(() => visibleRange += 5)
                          : null,
                      iconSize: 18,
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: colors.outline.withOpacity(0.2),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: visibleRange > 5
                          ? () => setState(() => visibleRange -= 5)
                          : null,
                      iconSize: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chart Container
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Main Chart
              SizedBox(
                height: 280,
                width: double.infinity,
                child: LineChart(
                  LineChartData(
                    minX: startDay,
                    maxX: startDay + visibleRange,
                    minY: 0,
                    maxY: (widget.spots.isNotEmpty
                            ? widget.spots.map((e) => e.y).reduce((a, b) => a > b ? a : b)
                            : 100) *
                        1.1,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 500000,
                      verticalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: colors.outline.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: colors.outline.withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: visibleRange > 20 ? 5 : 2,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < widget.dateLabels.length) {
                              return Transform.rotate(
                                angle: 0.5,
                                child: Text(
                                  widget.dateLabels[index].split(' ')[0],
                                  style: textTheme.labelSmall,
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
                          interval: 500000,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const Text('₹0');
                            if (value >= 1000000) {
                              return Text('₹${(value / 1000000).toStringAsFixed(0)}M');
                            }
                            if (value >= 100000) {
                              return Text('₹${(value / 100000).toStringAsFixed(0)}L');
                            }
                            return Text('₹${(value / 1000).toStringAsFixed(0)}K');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: colors.outline.withOpacity(0.2),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: getVisibleSpots(),
                        isCurved: true,
                        gradient: LinearGradient(
                          colors: [
                            colors.primary.withOpacity(0.8),
                            colors.secondary.withOpacity(0.8),
                          ],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: colors.primary,
                              strokeColor: Colors.white,
                              strokeWidth: 2,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              colors.primary.withOpacity(0.2),
                              colors.secondary.withOpacity(0.2),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.spotIndex;
                            final value = spot.y;
                            final label = index < widget.dateLabels.length
                                ? widget.dateLabels[index]
                                : 'Day ${index + 1}';
                            return LineTooltipItem(
                              '₹${(value / 100000).toStringAsFixed(1)}L\n$label',
                              const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Scroll slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scroll Timeline: Day ${startDay.toInt()} - ${(startDay + visibleRange).toInt()}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: startDay,
                    min: 0,
                    max: (widget.spots.isNotEmpty
                        ? widget.spots.map((e) => e.x).reduce((a, b) => a > b ? a : b)
                        : 90) -
                        visibleRange,
                    onChanged: (value) {
                      setState(() => startDay = value);
                    },
                    label: 'Day ${startDay.toInt()}',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Details card for tooltip
              if (widget.spots.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.outline.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expected Cash Inflow Details',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hover over data points to see:',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.outline,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildDetailRow('📅 Expected Date', 'Based on payment patterns',
                          colors, textTheme),
                      const SizedBox(height: 6),
                      _buildDetailRow(
                        '💰 Amount Expected',
                        'Total cashflow for that date',
                        colors,
                        textTheme,
                      ),
                      const SizedBox(height: 6),
                      _buildDetailRow('👥 From How Many Clients',
                          'Number of debtors paying', colors, textTheme),
                      const SizedBox(height: 6),
                      _buildDetailRow('⚡ Confidence Level',
                          '75-95% based on data quality', colors, textTheme),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String desc, ColorScheme colors,
      TextTheme textTheme) {
    return Row(
      children: [
        Text(label,
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            )),
        const SizedBox(width: 8),
        Expanded(
          child: Text(desc,
              style: textTheme.bodySmall?.copyWith(
                color: colors.outline,
              )),
        ),
      ],
    );
  }
}
