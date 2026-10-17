import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/dashboard_controller.dart';
import '../model/dashboard_model.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());

  static const Color appRed = Color(0xFFD50000);
  static const Color green = Color(0xFF16A34A);
  static const Color rejectedRed = Color(0xFFDC2626);
  static const Color muted = Color(0xFF858585);

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Call Dashboard',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Obx(
                () => IconButton(
              tooltip: 'Download dashboard PDF',
              onPressed: controller.isDownloadingPdf.value
                  ? null
                  : controller.downloadAndOpenPdf,
              icon: controller.isDownloadingPdf.value
                  ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.fetchDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.dashboard.value == null) {
          return const Center(
            child: CircularProgressIndicator(color: appRed),
          );
        }

        if (controller.errorMessage.value.isNotEmpty &&
            controller.dashboard.value == null) {
          return _ErrorView(
            message: controller.errorMessage.value,
            onRetry: controller.fetchDashboard,
          );
        }

        final data = controller.dashboard.value;
        if (data == null) {
          return const Center(child: Text('No dashboard data available.'));
        }

        return RefreshIndicator(
          color: appRed,
          onRefresh: controller.fetchDashboard,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
            children: [
              _filterTabs(),
              const SizedBox(height: 10),
              _filterSelector(context),
              const SizedBox(height: 20),

              _heading('Call Overview'),
              const SizedBox(height: 12),
              _kpiCards(data),

              const SizedBox(height: 24),
              _heading('Hourly Calls'),
              const SizedBox(height: 12),
              _hourlyChart(data.hourlyChart),

              const SizedBox(height: 24),
              _heading('Recent Calls'),
              const SizedBox(height: 12),
              _recentCalls(data.recentCalls),
            ],
          ),
        );
      }),
    );
  }

  // ── Filter tabs ──────────────────────────────────────────────

  Widget _filterTabs() {
    return Obx(() {
      final active = controller.filterType.value;

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _filterTab(
              label: 'Day',
              selected: active == DashboardFilterType.day,
              onTap: () =>
                  controller.chooseFilterType(DashboardFilterType.day),
            ),
            _filterTab(
              label: 'Date',
              selected: active == DashboardFilterType.date,
              onTap: () =>
                  controller.chooseFilterType(DashboardFilterType.date),
            ),
            _filterTab(
              label: 'Range',
              selected: active == DashboardFilterType.range,
              onTap: () =>
                  controller.chooseFilterType(DashboardFilterType.range),
            ),
          ],
        ),
      );
    });
  }

  Widget _filterTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? appRed : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF555555),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // The active tab's picker/dropdown appears directly below the tabs.
  Widget _filterSelector(BuildContext context) {
    return Obx(() {
      switch (controller.filterType.value) {
        case DashboardFilterType.day:
          return _dayDropdown();

        case DashboardFilterType.date:
          return _dateSelector(context);

        case DashboardFilterType.range:
          return _rangeSelector(context);
      }
    });
  }

  Widget _dayDropdown() {
    return Obx(() {
      return _selectorContainer(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: controller.selectedDay.value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: appRed),
            items: const [
              DropdownMenuItem(value: 'today', child: Text('Today')),
              DropdownMenuItem(value: 'yesterday', child: Text('Yesterday')),
            ],
            onChanged: (value) {
              if (value != null) controller.chooseDay(value);
            },
          ),
        ),
      );
    });
  }

  Widget _dateSelector(BuildContext context) {
    return Obx(() {
      return _selectorContainer(
        child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: controller.selectedDate.value,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: appRed,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              await controller.chooseDate(picked);
            }
          },
          child: Row(
            children: [
              const Icon(Icons.calendar_month_outlined,
                  color: appRed, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDate(controller.selectedDate.value),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: appRed),
            ],
          ),
        ),
      );
    });
  }

  Widget _rangeSelector(BuildContext context) {
    return Obx(() {
      final start = controller.rangeStart.value;
      final end = controller.rangeEnd.value;

      return _selectorContainer(
        child: InkWell(
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: DateTimeRange(
                start: start.isBefore(end) ? start : end,
                end: start.isBefore(end) ? end : start,
              ),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: appRed,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (picked != null) {
              await controller.chooseRange(picked.start, picked.end);
            }
          },
          child: Row(
            children: [
              const Icon(Icons.date_range_rounded, color: appRed, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${_formatDate(start)}  –  ${_formatDate(end)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: appRed),
            ],
          ),
        ),
      );
    });
  }

  Widget _selectorContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: child,
    );
  }

  // ── Dashboard sections ───────────────────────────────────────

  Widget _heading(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: Color(0xFF202020),
      ),
    );
  }

  Widget _kpiCards(DashboardModel data) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            title: 'Total Calls',
            value: data.totalCalls,
            icon: Icons.call_rounded,
            color: appRed,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiCard(
            title: 'Accepted',
            value: data.acceptedCalls,
            icon: Icons.call_received_rounded,
            color: green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiCard(
            title: 'Rejected',
            value: data.rejectedCalls,
            icon: Icons.call_end_rounded,
            color: rejectedRed,
          ),
        ),
      ],
    );
  }

  Widget _hourlyChart(List<HourlyCallModel> hourly) {
    final values = hourly.isEmpty
        ? List.generate(
      24,
          (i) => HourlyCallModel(
        hour: i,
        total: 0,
        accepted: 0,
        rejected: 0,
      ),
    )
        : hourly;

    final highest = values.fold<int>(0, (max, item) {
      final rowMax = [
        item.total,
        item.accepted,
        item.rejected,
      ].reduce((a, b) => a > b ? a : b);
      return rowMax > max ? rowMax : max;
    });

    final maxY = highest == 0 ? 4.0 : (highest + 1).toDouble();

    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(12, 16, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        children: [
          const Wrap(
            spacing: 13,
            children: [
              _Legend(color: appRed, text: 'Total'),
              _Legend(color: green, text: 'Accepted'),
              _Legend(color: rejectedRed, text: 'Rejected'),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 23,
                minY: 0,
                maxY: maxY,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFEFEFEF),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: muted),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3,
                      reservedSize: 23,
                      getTitlesWidget: (value, _) {
                        final hour = value.toInt();
                        if (hour % 3 != 0 || hour > 23) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          '${hour.toString().padLeft(2, '0')}:00',
                          style: const TextStyle(fontSize: 9, color: muted),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  _line(values, (v) => v.total, appRed),
                  _line(values, (v) => v.accepted, green),
                  _line(values, (v) => v.rejected, rejectedRed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _line(
      List<HourlyCallModel> values,
      int Function(HourlyCallModel) getValue,
      Color color,
      ) {
    return LineChartBarData(
      spots: values
          .map((v) => FlSpot(v.hour.toDouble(), getValue(v).toDouble()))
          .toList(),
      isCurved: true,
      color: color,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }

  Widget _recentCalls(List<RecentCallModel> calls) {
    if (calls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFECECEC)),
        ),
        child: const Center(
          child: Text(
            'No recent calls for this filter.',
            style: TextStyle(color: muted),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < calls.length; i++) ...[
            _RecentCallTile(call: calls[i]),
            if (i != calls.length - 1)
              const Divider(
                height: 1,
                indent: 15,
                endIndent: 15,
                color: Color(0xFFF0F0F0),
              ),
          ],
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 9),
          Text(
            '$value',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF202020),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF777777)),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
      ],
    );
  }
}

class _RecentCallTile extends StatelessWidget {
  const _RecentCallTile({required this.call});

  final RecentCallModel call;

  static const Color green = Color(0xFF16A34A);
  static const Color red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final accepted = call.isAccepted;
    final statusColor = accepted ? green : red;
    final time = call.callTime;
    final timeText = time == null ? 'Time unavailable' : _time(time);

    IconData callIcon;
    if (!accepted) {
      callIcon = Icons.call_end_rounded;
    } else if (call.direction.contains('incoming') ||
        call.direction.contains('inbound')) {
      callIcon = Icons.call_received_rounded;
    } else if (call.direction.contains('outgoing') ||
        call.direction.contains('outbound')) {
      callIcon = Icons.call_made_rounded;
    } else {
      callIcon = Icons.call_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(callIcon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$timeText  •  ${_duration(call.callDuration)}',
                  style: TextStyle(fontSize: 10, color: Color(0xFF858585)),
                ),
                const SizedBox(height: 3),
                Text(
                  'Marked: ${call.userStatus}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF858585)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              accepted ? 'Accepted' : 'Rejected',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _duration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return minutes == 0
        ? '${remaining}s'
        : '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD50000), size: 42),
            const SizedBox(height: 12),
            const Text(
              'Could not load dashboard',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD50000),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}