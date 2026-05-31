import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillpath_shared/skillpath_shared.dart';

import '../../main.dart' show globalStripePublishableKey, MainScreen;
import '../../providers/reservation_provider.dart';

class ReservationStep2PaymentScreen extends StatefulWidget {
  final ReservationDto reservation;
  final CourseDetailDto course;
  final CourseScheduleDto schedule;

  const ReservationStep2PaymentScreen({
    super.key,
    required this.reservation,
    required this.course,
    required this.schedule,
  });

  @override
  State<ReservationStep2PaymentScreen> createState() =>
      _ReservationStep2PaymentScreenState();
}

class _ReservationStep2PaymentScreenState
    extends State<ReservationStep2PaymentScreen> {
  bool _isProcessing = false;
  bool _paymentCompleted = false;
  String? _errorMessage;

  // Billing form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _countryController;
  late final TextEditingController _zipController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: '${widget.reservation.firstName} ${widget.reservation.lastName}',
    );
    _emailController = TextEditingController(
      text: widget.reservation.email,
    );
    _addressController = TextEditingController();
    _cityController = TextEditingController(text: 'Mostar');
    _countryController = TextEditingController(text: 'Bosna i Hercegovina');
    _zipController = TextEditingController(text: '88000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return NumberFormat.currency(locale: 'bs_BA', symbol: 'KM ').format(price);
  }

  String? get _stripePublishableKey {
    if (globalStripePublishableKey != null && globalStripePublishableKey!.isNotEmpty) {
      return globalStripePublishableKey;
    }
    return null;
  }

  bool get _isDesktop {
    try {
      return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  // ── Payment Sheet Init & Present ──

  Future<void> _initAndPresentPaymentSheet({
    required String clientSecret,
    required String ephemeralKey,
    required String customerId,
  }) async {
    // Ensure Stripe is initialized
    final publishableKey = _stripePublishableKey;
    if (publishableKey == null || publishableKey.isEmpty) {
      throw Exception('Stripe publishable key not configured');
    }

    try {
      final currentKey = Stripe.publishableKey;
      if (currentKey.isEmpty) {
        Stripe.publishableKey = publishableKey;
        Stripe.merchantIdentifier = 'merchant.com.skillpath';
        await Stripe.instance.applySettings();
      }
    } catch (_) {
      Stripe.publishableKey = publishableKey;
      Stripe.merchantIdentifier = 'merchant.com.skillpath';
      await Stripe.instance.applySettings();
    }

    // Init payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        customFlow: false,
        merchantDisplayName: 'SkillPath',
        paymentIntentClientSecret: clientSecret,
        customerEphemeralKeySecret: ephemeralKey,
        customerId: customerId,
        style: ThemeMode.system,
      ),
    );

    // Present to user
    await Stripe.instance.presentPaymentSheet();
  }

  // ── Item 28: Confirmation Dialog ──

  Future<bool> _showPaymentConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdite placanje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kurs: ${widget.course.title}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Termin: ${widget.schedule.dayOfWeek} ${widget.schedule.startTime} - ${widget.schedule.endTime}'),
            const SizedBox(height: 8),
            Text('Period: ${DateFormat('dd.MM.yyyy').format(widget.schedule.startDate)} - ${DateFormat('dd.MM.yyyy').format(widget.schedule.endDate)}'),
            const SizedBox(height: 12),
            Text(
              'Iznos: ${_formatPrice(widget.reservation.totalAmount)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Da li zelite nastaviti sa placanjem?',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkazi'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Potvrdite placanje'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Main Payment Handler (Items 2, 3: All Stripe calls go through backend) ──

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) return;

    // Item 28: Show confirmation dialog before payment
    final confirmed = await _showPaymentConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Call backend to create checkout (PaymentIntent + Customer + EphemeralKey)
      debugPrint('[PAYMENT] Creating checkout via backend...');
      final checkoutResponse = await ApiClient.post(
        '/api/Payment/create-checkout',
        {
          'reservationId': widget.reservation.id,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'country': _countryController.text.trim(),
          'zipCode': _zipController.text.trim(),
        },
      );

      if (checkoutResponse.statusCode != 200) {
        String errorMsg = 'Greska prilikom kreiranja placanja.';
        try {
          final body = jsonDecode(checkoutResponse.body) as Map<String, dynamic>;
          errorMsg = body['error']?['message'] as String? ?? errorMsg;
        } catch (_) {}
        throw Exception(errorMsg);
      }

      final checkoutData = jsonDecode(checkoutResponse.body) as Map<String, dynamic>;
      final clientSecret = checkoutData['clientSecret'] as String;
      final paymentIntentId = checkoutData['paymentIntentId'] as String;
      final ephemeralKeySecret = checkoutData['ephemeralKeySecret'] as String?;
      final customerId = checkoutData['customerId'] as String?;

      debugPrint('[PAYMENT] Checkout created: $paymentIntentId');

      // Step 2: Present PaymentSheet (mobile only)
      if (_isDesktop) {
        debugPrint('[PAYMENT] Desktop detected - skipping PaymentSheet');
      } else {
        if (ephemeralKeySecret != null && customerId != null) {
          debugPrint('[PAYMENT] Presenting PaymentSheet...');
          await _initAndPresentPaymentSheet(
            clientSecret: clientSecret,
            ephemeralKey: ephemeralKeySecret,
            customerId: customerId,
          );
          debugPrint('[PAYMENT] PaymentSheet completed successfully');
        } else {
          throw Exception('Stripe payment configuration incomplete.');
        }
      }

      // Step 3: Confirm payment on backend
      debugPrint('[PAYMENT] Confirming payment on backend...');
      final confirmResponse = await ApiClient.post(
        '/api/Payment/confirm',
        {'paymentIntentId': paymentIntentId},
      );

      if (confirmResponse.statusCode != 200) {
        throw Exception('Potvrda placanja nije uspjela.');
      }

      final confirmData = jsonDecode(confirmResponse.body) as Map<String, dynamic>;
      final paymentStatus = confirmData['status'] as String?;

      if (paymentStatus != 'Succeeded') {
        throw Exception('Placanje nije uspjelo. Status: $paymentStatus');
      }

      // Step 4: Confirm reservation on backend
      if (mounted) {
        final reservationProvider = context.read<ReservationProvider>();
        final reservationConfirmed = await reservationProvider.confirmReservation(
          widget.reservation.id,
          paymentIntentId,
        );

        if (reservationConfirmed && mounted) {
          setState(() => _paymentCompleted = true);
        } else if (mounted) {
          setState(() {
            _errorMessage = reservationProvider.errorMessage ??
                'Potvrda rezervacije nije uspjela.';
          });
        }
      }
    } on StripeException catch (e) {
      debugPrint('[PAYMENT] Stripe exception: ${e.error.message}');
      if (e.error.code == FailureCode.Canceled) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Placanje je otkazano.';
            _isProcessing = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.error.message ?? 'Greska prilikom placanja.';
        });
      }
    } catch (e) {
      debugPrint('[PAYMENT] Error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezervacija - Korak 2'),
      ),
      body: SafeArea(
        child: _paymentCompleted
            ? _buildPaymentSuccessScreen(primaryColor)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepIndicator(2),
                    const SizedBox(height: 24),
                    _buildAmountCard(primaryColor),
                    const SizedBox(height: 24),
                    _buildOrderSummaryCard(),
                    const SizedBox(height: 24),
                    _buildBillingForm(primaryColor),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      _buildErrorBanner(),
                      const SizedBox(height: 24),
                    ],
                    if (_isDesktop) ...[
                      _buildDesktopInfoBanner(),
                      const SizedBox(height: 24),
                    ],
                    _buildPayButton(primaryColor),
                    const SizedBox(height: 12),
                    _buildSecurityNote(),
                  ],
                ),
              ),
      ),
    );
  }

  // ── Payment Success Screen ──

  Widget _buildPaymentSuccessScreen(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Success icon & message
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 50,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Placanje uspjesno!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Vasa rezervacija je potvrdjena.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Reservation ticket card
          _buildReservationTicketCard(primaryColor),
          const SizedBox(height: 32),
          // Navigate to reservations
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                MainScreen.switchToTab(2);
              },
              child: const Text(
                'Moje rezervacije',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Pocetna', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationTicketCard(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PAID',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Perforation
          CustomPaint(
            painter: _PerforationPainter(),
            size: const Size(double.infinity, 1),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ticketRow('Student',
                    '${widget.reservation.firstName} ${widget.reservation.lastName}'),
                _ticketRow('Email', widget.reservation.email),
                _ticketRow('Instruktor', widget.course.instructorName),
                _ticketRow('Termin',
                    '${widget.schedule.dayOfWeek} | ${widget.schedule.startTime} - ${widget.schedule.endTime}'),
                _ticketRow('Period',
                    '${DateFormat('dd.MM.yyyy').format(widget.schedule.startDate)} - ${DateFormat('dd.MM.yyyy').format(widget.schedule.endDate)}'),
                _ticketRow('Iznos', _formatPrice(widget.reservation.totalAmount)),
                const SizedBox(height: 16),
                // Reservation code
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Broj potvrde',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        widget.reservation.reservationCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
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
    );
  }

  Widget _ticketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[700])),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  // ── Amount Card ──

  Widget _buildAmountCard(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
                ),
                child: Icon(Icons.school, color: primaryColor, size: 24),
              ),
              Text(
                'Iznos za placanje',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.05),
                  primaryColor.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Text(
                  _formatPrice(widget.reservation.totalAmount),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Order Summary ──

  Widget _buildOrderSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pregled narudzbe',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            _buildSummaryRow('Kurs', widget.course.title),
            const Divider(height: 24),
            _buildSummaryRow(
              'Termin',
              '${widget.schedule.dayOfWeek}\n${widget.schedule.startTime} - ${widget.schedule.endTime}',
            ),
            const Divider(height: 24),
            _buildSummaryRow(
              'Period',
              '${DateFormat('dd.MM.yyyy').format(widget.schedule.startDate)} - ${DateFormat('dd.MM.yyyy').format(widget.schedule.endDate)}',
            ),
            const Divider(height: 24),
            _buildSummaryRow('Instruktor', widget.course.instructorName),
            const Divider(height: 24),
            _buildSummaryRow('Ime i prezime',
                '${widget.reservation.firstName} ${widget.reservation.lastName}'),
            const Divider(height: 24),
            _buildSummaryRow('Email', widget.reservation.email),
            const Divider(height: 24),
            _buildSummaryRow('Telefon', widget.reservation.phoneNumber),
          ],
        ),
      ),
    );
  }

  // ── Billing Form ──

  Widget _buildBillingForm(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Podaci za naplatu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ime i prezime',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Unesite ime i prezime' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Unesite email adresu';
                final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
                if (!emailRegex.hasMatch(v.trim())) return 'Unesite ispravan email';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adresa',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Unesite adresu' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Grad',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Unesite grad' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _zipController,
                    decoration: const InputDecoration(
                      labelText: 'ZIP Code',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Unesite ZIP' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Drzava',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Unesite drzavu' : null,
            ),
          ],
        ),
      ),
    );
  }

  // ── Error / Info Banners ──

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Desktop mod: PaymentSheet nije dostupan na desktop platformi.',
              style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pay Button ──

  Widget _buildPayButton(Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        onPressed: _isProcessing ? null : _handlePayment,
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.payment),
        label: Text(
          _isProcessing ? 'Obrada placanja...' : 'Nastavi na placanje',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          'Sigurno placanje putem Stripe-a',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ── Helpers ──

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int currentStep) {
    return Row(
      children: [
        for (int i = 1; i <= 3; i++) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= currentStep
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
            ),
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  color: i <= currentStep ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (i < 3)
            Expanded(
              child: Container(
                height: 2,
                color: i < currentStep
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
              ),
            ),
        ],
      ],
    );
  }
}

class _PerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    double startX = 0;
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
