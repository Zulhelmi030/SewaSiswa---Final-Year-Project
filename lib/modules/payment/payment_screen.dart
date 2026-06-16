import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/payment_service.dart';
import '../../core/services/image_service.dart';
import 'package:finalyearproject/core/styles/app_theme_extensions.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = true;
  bool _isHouseLeader = false;
  double _rentPerPerson = 0.0;
  String _listingId = '';
  String _ownerId = '';
  String? _masterReceiptUrl;
  double _totalRent = 0.0;
  Duration _timeLeft = const Duration();
  List<Map<String, dynamic>> _housemates = [];

  Future<void> _loadData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final myRental = await supabase
          .from('rental_tenants')
          .select('listing_id, due_day')
          .eq('user_id', user.id)
          .single();

      final listingId = myRental['listing_id'];
      final dueDay = myRental['due_day'] as int;

      final now = DateTime.now();
      DateTime dueDate = DateTime(now.year, now.month, dueDay);
      if (now.isAfter(dueDate)) {
        dueDate = DateTime(now.year, now.month + 1, dueDay);
      }

      final listing = await supabase
          .from('listings')
          .select('owner_id, monthly_rent')
          .eq('id', listingId)
          .single();

      final isLeader = listing['owner_id'] == user.id;

      // Fetch all tenants with their user info
      final tenantsData = await supabase
          .from('rental_tenants')
          .select('user_id, status, users(full_name)')
          .eq('listing_id', listingId);

      // Fetch this month's payments for this listing to get receipt_url & paid status
      final firstOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      final paymentsData = await supabase
          .from('payments')
          .select('sender_id, status, receipt_url')
          .eq('rental_id', listingId)
          .gte('payment_date', firstOfMonth);

      // Build a map: user_id -> payment record
      final Map<String, Map<String, dynamic>> paymentByUser = {};
      for (var p in paymentsData) {
        paymentByUser[p['sender_id']] = p;
      }

      final totalTenants = tenantsData.length;
      final totalRent = (listing['monthly_rent'] as num?)?.toDouble() ?? 0.0;

      // Fetch the master receipt (leader to owner) for this month
      final masterPaymentData = await supabase
          .from('payments')
          .select('receipt_url')
          .eq('rental_id', listingId)
          .eq('method', 'master_receipt')
          .gte('payment_date', firstOfMonth)
          .maybeSingle();

      final List<Map<String, dynamic>> parsedHousemates = [];
      for (var t in tenantsData) {
        final userData = t['users'] as Map<String, dynamic>?;
        final tenantUserId = t['user_id'] as String;
        final payment = paymentByUser[tenantUserId];
        parsedHousemates.add({
          'user_id': tenantUserId,
          'name': userData?['full_name'] ?? 'Unknown Member',
          // A member is 'paid' if their payment record status is 'succeeded' or 'paid'
          'status':
              (payment?['status'] == 'paid' ||
                  payment?['status'] == 'succeeded')
              ? 'paid'
              : 'pending',
          'receipt_url': payment?['receipt_url'],
        });
      }

      if (mounted) {
        setState(() {
          _isHouseLeader = isLeader;
          _listingId = listingId;
          _ownerId = listing['owner_id'];
          _masterReceiptUrl = masterPaymentData?['receipt_url'];
          _totalRent = totalRent;
          _timeLeft = dueDate.difference(now);
          if (totalTenants > 0) {
            _rentPerPerson = totalRent / totalTenants;
          }
          _housemates = parsedHousemates;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading payment data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_timeLeft.inSeconds <= 0) {
        _countdownTimer?.cancel();
        return;
      }
      setState(() => _timeLeft -= const Duration(seconds: 1));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Payment',
          style: context.appTextStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopCard(),
                    const SizedBox(height: 24),
                    _buildPaidToOwnerCard(),
                    const SizedBox(height: 24),
                    _buildHousematesCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: (!_isLoading && !_isHouseLeader)
          ? _buildStickyBottomBar()
          : null,
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMakePaymentButton(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 14,
                color: context.appColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Secure encrypted payment',
                style: context.appTextStyles.labelSmall.copyWith(
                  color: context.appColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard() {
    // Alias so the rest of the method is unchanged
    return _buildCountdownCard();
  }

  Widget _buildCountdownCard() {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours.remainder(24);
    final minutes = _timeLeft.inMinutes.remainder(60);
    final seconds = _timeLeft.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: context.appColors.primary, width: 4)),
        boxShadow: [
          BoxShadow(
            color: context.appColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'DUE TO NEXT PAYMENT',
            style: context.appTextStyles.labelCaps.copyWith(
              color: context.appColors.primary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimerUnit(_pad(days), 'Days'),
              _buildTimerDivider(),
              _buildTimerUnit(_pad(hours), 'Hours'),
              _buildTimerDivider(),
              _buildTimerUnit(_pad(minutes), 'Mins'),
              _buildTimerDivider(),
              _buildTimerUnit(_pad(seconds), 'Secs'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Your Split: RM ${_rentPerPerson.toStringAsFixed(2)}',
            style: context.appTextStyles.titleMedium.copyWith(
              color: context.appColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  Widget _buildTimerUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: context.appColors.primary,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: context.appTextStyles.labelSmall.copyWith(
            color: context.appColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDivider() {
    return Text(
      ':',
      style: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: context.appColors.outlineVariant,
      ),
    );
  }

  Widget _buildMakePaymentButton() {
    return FilledButton(
      onPressed: () async {
        final amountInCents = (_rentPerPerson * 100).toInt();
        if (amountInCents <= 0) return;

        setState(() => _isLoading = true);
        final paymentService = PaymentService();
        await paymentService.makePayment(
          context: context,
          amountInCents: amountInCents,
          currency: 'myr',
          metadata: {
            'rental_id': _listingId,
            'sender_id': Supabase.instance.client.auth.currentUser!.id,
            'receiver_id': _ownerId,
            'method': 'gateway',
          },
        );
        setState(() => _isLoading = false);
      },
      style: FilledButton.styleFrom(
        backgroundColor: context.appColors.primary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(
        'Make Payment (RM ${_rentPerPerson.toStringAsFixed(2)})',
        style: context.appTextStyles.titleMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Housemates Card ───────────────────────────────────────────────────────

  Widget _buildHousematesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
          child: Text(
            'Housemates',
            style: context.appTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Column(
          children: _housemates
              .map((member) => _buildHousemateRow(member))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildHousemateRow(Map<String, dynamic> member) {
    final isPaid = member['status'] == 'paid';
    final String? receiptUrl = member['receipt_url'] as String?;
    final bool isMe =
        member['user_id'] == Supabase.instance.client.auth.currentUser?.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.appColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Avatar placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.appColors.surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      member['name'][0].toUpperCase(),
                      style: context.appTextStyles.titleLarge.copyWith(
                        color: context.appColors.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'],
                        style: context.appTextStyles.titleMedium.copyWith(
                          color: context.appColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? context.appColors.tertiaryContainer
                                  : context.appColors.warningContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isPaid ? 'Paid' : 'Pending',
                              style: context.appTextStyles.labelSmall.copyWith(
                                color: isPaid
                                    ? context.appColors.onTertiaryContainer
                                    : context.appColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'RM ${_rentPerPerson.toStringAsFixed(0)}',
                            style: context.appTextStyles.bodySmall.copyWith(
                              color: context.appColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Receipt actions
          if (receiptUrl != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showReceiptDialog(receiptUrl),
                  icon: const Icon(Icons.receipt_long_rounded),
                  color: context.appColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: context.appColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _uploadReceipt(member),
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    color: context.appColors.onSurfaceVariant,
                  ),
                ],
              ],
            )
          else if (isMe)
            IconButton(
              onPressed: () => _uploadReceipt(member),
              icon: const Icon(Icons.upload_file_rounded),
              color: context.appColors.onSurfaceVariant,
              style: IconButton.styleFrom(
                backgroundColor: context.appColors.surfaceContainerHigh,
              ),
            ),
        ],
      ),
    );
  }

  /// Opens the system file manager so the current member can upload their receipt.
  Future<void> _uploadReceipt(Map<String, dynamic> member) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);
    final file = File(result.files.single.path!);
    final imageService = ImageService(Supabase.instance.client);
    final publicUrl = await imageService.uploadReceiptImage(file);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (publicUrl != null) {
      try {
        final supabase = Supabase.instance.client;
        final now = DateTime.now();
        final firstOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

        // Try to update an existing payment record for this month first
        final existing = await supabase
            .from('payments')
            .select('id')
            .eq('rental_id', _listingId)
            .eq('sender_id', member['user_id'])
            .gte('payment_date', firstOfMonth)
            .maybeSingle();

        if (existing != null) {
          await supabase
              .from('payments')
              .update({'receipt_url': publicUrl})
              .eq('id', existing['id']);
        } else {
          // Insert a new manual payment record with the receipt
          await supabase.from('payments').insert({
            'rental_id': _listingId,
            'sender_id': member['user_id'],
            'receiver_id': _ownerId,
            'amount': _rentPerPerson,
            'status': 'pending',
            'method': 'manual',
            'receipt_url': publicUrl,
          });
        }

        // Notify the owner
        try {
          await supabase.from('notifications').insert({
            'user_id': _ownerId,
            'title': 'Receipt Uploaded',
            'message': '${member['name']} has uploaded a manual payment receipt for RM ${_rentPerPerson.toStringAsFixed(0)}.',
            'type': 'payment',
          });
        } catch (_) {}

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Receipt uploaded!')));
        _loadData(); // Refresh to show the new receipt icon
      } catch (e) {
        debugPrint('DB error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploaded but failed to save to database.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload receipt.')),
      );
    }
  }

  /// Shows a full-screen dialog to view the uploaded receipt image or PDF link.
  void _showReceiptDialog(String url) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Payment Receipt',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (url.endsWith('.pdf'))
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.picture_as_pdf,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'PDF Receipt',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      url,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Could not load image.'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Paid to Owner Card ────────────────────────────────────────────────────

  Widget _buildPaidToOwnerCard() {
    // Count how many members are marked paid this month
    final paidCount = _housemates.where((m) => m['status'] == 'paid').length;
    final total = _housemates.length;
    final allPaid = paidCount == total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                'Paid to House Owner',
                style: context.appTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.appColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                allPaid ? 'All Paid' : 'Due Soon',
                style: context.appTextStyles.labelSmall.copyWith(
                  color: context.appColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF243B82) 
                    : const Color(0xFF1B3A8C),
                Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF182C66) 
                    : const Color(0xFF14296B),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: context.appColors.primary.withValues(alpha: 0.15),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Collected',
                style: context.appTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFFC7D4F5), // on-primary-container
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'RM ${(_totalRent).toStringAsFixed(0)}',
                    style: context.appTextStyles.headlineLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '.00',
                    style: context.appTextStyles.titleMedium.copyWith(
                      color: const Color(0xFFC7D4F5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_masterReceiptUrl != null)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showReceiptDialog(_masterReceiptUrl!),
                        icon: const Icon(Icons.visibility_rounded, size: 20),
                        label: const Text('View Master Receipt'),
                        style: FilledButton.styleFrom(
                          backgroundColor: context.appColors.secondaryContainer,
                          foregroundColor: context.appColors.onSecondaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    if (_isHouseLeader) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _uploadMasterReceipt,
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ],
                )
              else if (_isHouseLeader)
                FilledButton.icon(
                  onPressed: _uploadMasterReceipt,
                  icon: const Icon(Icons.upload_file_rounded, size: 20),
                  label: const Text('Upload Master Receipt'),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.appColors.secondaryContainer,
                    foregroundColor: context.appColors.onSecondaryContainer,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens the system file manager so the house leader can upload the master receipt.
  Future<void> _uploadMasterReceipt() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _isLoading = true);
    final file = File(result.files.single.path!);
    final imageService = ImageService(Supabase.instance.client);
    final publicUrl = await imageService.uploadReceiptImage(file);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (publicUrl != null) {
      try {
        final supabase = Supabase.instance.client;
        final now = DateTime.now();
        final firstOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

        // Try to update an existing master receipt record for this month
        final existing = await supabase
            .from('payments')
            .select('id')
            .eq('rental_id', _listingId)
            .eq('method', 'master_receipt')
            .gte('payment_date', firstOfMonth)
            .maybeSingle();

        if (existing != null) {
          await supabase
              .from('payments')
              .update({'receipt_url': publicUrl})
              .eq('id', existing['id']);
        } else {
          // Insert a new master receipt record
          await supabase.from('payments').insert({
            'rental_id': _listingId,
            'sender_id': supabase.auth.currentUser!.id,
            'receiver_id': _ownerId,
            'amount': _totalRent,
            'status': 'paid',
            'method': 'master_receipt',
            'receipt_url': publicUrl,
          });
        }

        // Notify the owner
        try {
          await supabase.from('notifications').insert({
            'user_id': _ownerId,
            'title': 'Master Receipt Uploaded',
            'message': 'The house leader has uploaded the master payment receipt for RM ${_totalRent.toStringAsFixed(0)}.',
            'type': 'payment',
          });
        } catch (_) {}

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Owner receipt uploaded!')),
        );
        _loadData(); // Refresh to show the new receipt icon
      } catch (e) {
        debugPrint('DB error: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uploaded but failed to save to database.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload receipt.')),
      );
    }
  }
}
