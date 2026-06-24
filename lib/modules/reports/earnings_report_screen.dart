import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';
import 'package:intl/intl.dart';

// ── Earnings Report Screen ────────────────────────────────────────────────────
class EarningsReportScreen extends StatefulWidget {
  const EarningsReportScreen({super.key});

  @override
  State<EarningsReportScreen> createState() => _EarningsReportScreenState();
}

class _EarningsReportScreenState extends State<EarningsReportScreen> {
  final _client = Supabase.instance.client;

  // State
  bool _isLoading = true;
  int _selectedFilter = 0; // 0=This Month, 1=Last 3 Months, 2=All Time

  // Data
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _tenants = [];

  // Theme mapping for light/dark mode
  Color get _bgColor => context.appColors.background;
  Color get _cardColor => context.appColors.surface;
  Color get _cardBorder => context.appColors.outlineVariant;
  Color get _accentBlue => context.appColors.primary;
  Color get _accentGreen => context.appColors.success;
  Color get _accentAmber => context.appColors.warning;
  Color get _accentRed => context.appColors.error;
  Color get _textPrimary => context.appColors.textPrimary;
  Color get _textSecondary => context.appColors.textSecondary;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // ── Data Fetching ─────────────────────────────────────────────────────────

  Future<void> _fetchData() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Always fetch the last 6 months to ensure the bar chart has data
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      // Fetch payments where current user is receiver (owner)
      var paymentsQuery = _client
          .from('payments')
          .select('*, users!payments_sender_id_fkey(id, full_name, avatar_url)')
          .eq('receiver_id', userId)
          .gte('payment_date', sixMonthsAgo.toIso8601String());

      final paymentsRes = await paymentsQuery.order(
        'payment_date',
        ascending: false,
      );

      // Fetch listings owned by this user
      final listingsRes = await _client
          .from('listings')
          .select('id, title, city, state, monthly_rent, status')
          .eq('owner_id', userId);

      // Fetch tenants for owner's listings
      final listingIds = (listingsRes as List).map((l) => l['id']).toList();
      List<Map<String, dynamic>> tenantsRes = [];
      if (listingIds.isNotEmpty) {
        final res = await _client
            .from('rental_tenants')
            .select('*, users(id, full_name), listings(title)')
            .inFilter('listing_id', listingIds)
            .eq('status', 'active');
        tenantsRes = List<Map<String, dynamic>>.from(res);
      }

      debugPrint('==== EARNINGS REPORT DATA ====');
      debugPrint('Payments loaded: ${(paymentsRes as List).length}');
      debugPrint('Listings loaded: ${(listingsRes as List).length}');
      debugPrint('Tenants loaded: ${tenantsRes.length}');
      debugPrint('==============================');

      if (mounted) {
        setState(() {
          _payments = List<Map<String, dynamic>>.from(paymentsRes);
          _listings = List<Map<String, dynamic>>.from(listingsRes);
          _tenants = tenantsRes;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching earnings data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Computed Values ───────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filteredPayments {
    if (_selectedFilter == 2) return _payments; // All Time (or last 6 months fetched)
    final now = DateTime.now();
    DateTime fromDate;
    if (_selectedFilter == 0) {
      fromDate = DateTime(now.year, now.month, 1);
    } else {
      fromDate = DateTime(now.year, now.month - 3, 1);
    }
    return _payments.where((p) {
      if (p['payment_date'] == null) return false;
      final d = DateTime.parse(p['payment_date']);
      return d.isAfter(fromDate) || d.isAtSameMomentAs(fromDate);
    }).toList();
  }

  double get _totalEarned => _filteredPayments
      .where((p) => p['status'] == 'paid')
      .fold(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());

  double get _pendingAmount => _filteredPayments
      .where((p) => p['status'] == 'pending')
      .fold(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());

  int get _paidCount =>
      _filteredPayments.where((p) => p['status'] == 'paid').length;

  int get _pendingCount =>
      _filteredPayments.where((p) => p['status'] == 'pending').length;

  int get _overdueCount =>
      _filteredPayments.where((p) => p['status'] == 'overdue' || p['status'] == 'failed').length;

  /// Returns monthly totals for the last 6 months for the bar chart.
  List<double> get _monthlyTotals {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final month = now.month - 5 + i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;
      return _payments
          .where((p) {
            if (p['payment_date'] == null) return false;
            final d = DateTime.parse(p['payment_date']);
            return d.month == adjustedMonth &&
                d.year == year &&
                p['status'] == 'paid';
          })
          .fold(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _accentBlue))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildFilterChips()),
                  SliverToBoxAdapter(child: _buildKpiRow()),
                  SliverToBoxAdapter(child: _buildBarChartSection()),
                  SliverToBoxAdapter(child: _buildDonutChartSection()),
                  SliverToBoxAdapter(child: _buildPropertiesSection()),
                  SliverToBoxAdapter(child: _buildRecentPaymentsSection()),
                  SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textPrimary,
                size: 18,
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Earnings Report',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chips ──────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    final filters = ['This Month', 'Last 3 Months', 'All Time'];
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(filters.length, (i) {
          final selected = _selectedFilter == i;
          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = i;
                  _isLoading = true;
                });
                _fetchData();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? _accentBlue : _cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? _accentBlue : _cardBorder,
                  ),
                ),
                child: Text(
                  filters[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
        ),
      ),
    );
  }

  // ── KPI Cards Row ─────────────────────────────────────────────────────────

  Widget _buildKpiRow() {
    final currencyFormat = NumberFormat('#,##0.00', 'en_US');
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildKpiCard(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Total Earned',
              value: 'RM ${currencyFormat.format(_totalEarned)}',
              valueColor: _accentGreen,
              iconColor: _accentGreen,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              icon: Icons.hourglass_top_rounded,
              label: 'Pending',
              value: 'RM ${currencyFormat.format(_pendingAmount)}',
              valueColor: _accentAmber,
              iconColor: _accentAmber,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _buildKpiCard(
              icon: Icons.people_rounded,
              label: 'Tenants',
              value: '${_tenants.length}',
              valueColor: _accentBlue,
              iconColor: _accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    required Color iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: _textSecondary)),
        ],
      ),
    );
  }

  // ── Bar Chart ─────────────────────────────────────────────────────────────

  Widget _buildBarChartSection() {
    final now = DateTime.now();
    final monthLabels = List.generate(6, (i) {
      final month = now.month - 5 + i;
      final adjustedMonth = month <= 0 ? month + 12 : month;
      return DateFormat('MMM').format(DateTime(2024, adjustedMonth));
    });

    final totals = _monthlyTotals;
    final maxY = totals.isEmpty
        ? 100.0
        : (totals.reduce((a, b) => a > b ? a : b) * 1.25).clamp(
            100.0,
            double.infinity,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    color: _accentBlue,
                    size: 16,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Monthly Earnings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  minY: 0,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'RM ${rod.toY.toStringAsFixed(0)}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= monthLabels.length) {
                            return SizedBox.shrink();
                          }
                          return Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text(
                              monthLabels[idx],
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return Text(
                              'RM 0',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 10,
                              ),
                            );
                          }
                          return Text(
                            'RM ${value.toInt()}',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: _cardBorder, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(6, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: totals[i],
                          width: 24,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          gradient: LinearGradient(
                            colors: [_accentBlue, _accentGreen],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: _cardBorder.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Donut Chart ───────────────────────────────────────────────────────────

  Widget _buildDonutChartSection() {
    final total = _paidCount + _pendingCount + _overdueCount;
    final paidPct = total == 0 ? 0.0 : (_paidCount / total * 100);
    final pendingPct = total == 0 ? 0.0 : (_pendingCount / total * 100);
    final overduePct = total == 0 ? 0.0 : (_overdueCount / total * 100);

    final sections = total == 0
        ? [
            PieChartSectionData(
              value: 1,
              color: _cardBorder,
              title: '',
              radius: 40,
            ),
          ]
        : [
            if (_paidCount > 0)
              PieChartSectionData(
                value: _paidCount.toDouble(),
                color: _accentGreen,
                title: '',
                radius: 40,
              ),
            if (_pendingCount > 0)
              PieChartSectionData(
                value: _pendingCount.toDouble(),
                color: _accentAmber,
                title: '',
                radius: 40,
              ),
            if (_overdueCount > 0)
              PieChartSectionData(
                value: _overdueCount.toDouble(),
                color: _accentRed,
                title: '',
                radius: 40,
              ),
          ];

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.donut_large_rounded,
                    color: _accentGreen,
                    size: 16,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Payment Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 34,
                      sectionsSpace: 3,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendRow(
                        _accentGreen,
                        'Paid',
                        '${paidPct.toStringAsFixed(0)}%',
                        _paidCount,
                      ),
                      SizedBox(height: 10),
                      _buildLegendRow(
                        _accentAmber,
                        'Pending',
                        '${pendingPct.toStringAsFixed(0)}%',
                        _pendingCount,
                      ),
                      SizedBox(height: 10),
                      _buildLegendRow(
                        _accentRed,
                        'Overdue',
                        '${overduePct.toStringAsFixed(0)}%',
                        _overdueCount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label, String pct, int count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: _textPrimary),
          ),
        ),
        Text(
          '$pct ($count)',
          style: TextStyle(
            fontSize: 12,
            color: _textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Properties ────────────────────────────────────────────────────────────

  Widget _buildPropertiesSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.home_work_rounded, 'My Properties'),
          SizedBox(height: 12),
          if (_listings.isEmpty)
            _buildEmptyCard('No listings found')
          else
            ..._listings.map((listing) => _buildPropertyCard(listing)),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> listing) {
    final tenantCount = _tenants
        .where((t) => t['listing_id'] == listing['id'])
        .length;
    final isOccupied = tenantCount > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.home_rounded, color: _accentBlue, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing['title'] ?? 'Untitled',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  '${listing['city'] ?? ''}, ${listing['state'] ?? ''}',
                  style: TextStyle(fontSize: 12, color: _textSecondary),
                ),
                SizedBox(height: 4),
                Text(
                  'RM ${listing['monthly_rent']?.toStringAsFixed(0) ?? '0'}/mo  •  $tenantCount tenant${tenantCount != 1 ? 's' : ''}',
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOccupied
                  ? _accentGreen.withValues(alpha: 0.15)
                  : _cardBorder,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isOccupied ? 'Active' : 'Vacant',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isOccupied ? _accentGreen : _textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recent Payments ───────────────────────────────────────────────────────

  Widget _buildRecentPaymentsSection() {
    final recentPayments = _filteredPayments.take(10).toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(Icons.receipt_long_rounded, 'Recent Payments'),
          SizedBox(height: 12),
          if (recentPayments.isEmpty)
            _buildEmptyCard('No payments yet')
          else
            ...recentPayments.map((p) => _buildPaymentRow(p)),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment) {
    final sender = payment['users'] as Map<String, dynamic>?;
    final name = sender?['full_name'] ?? 'Unknown';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final status = payment['status'] as String? ?? 'pending';
    final dateStr = payment['payment_date'];
    String formattedDate = '';
    if (dateStr != null) {
      formattedDate = DateFormat('MMM d, y').format(DateTime.parse(dateStr));
    }

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'paid':
        statusColor = _accentGreen;
        statusLabel = 'Paid';
        break;
      case 'pending':
        statusColor = _accentAmber;
        statusLabel = 'Pending';
        break;
      default:
        statusColor = _accentRed;
        statusLabel = 'Overdue';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accentBlue, Color(0xFF2575C8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Name & date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 11, color: _textSecondary),
                ),
              ],
            ),
          ),
          // Amount & status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+RM ${amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _accentGreen,
                ),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _accentBlue, size: 18),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, color: _textSecondary, size: 36),
          SizedBox(height: 8),
          Text(message, style: TextStyle(color: _textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
