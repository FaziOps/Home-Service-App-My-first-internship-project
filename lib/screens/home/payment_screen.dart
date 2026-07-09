import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import 'booking_confirmed_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String categoryName;
  final String imagePath;
  final String bhkSize;
  final String sqftArea;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final double totalPrice;

  const PaymentScreen({
    super.key,
    required this.categoryName,
    required this.imagePath,
    required this.bhkSize,
    required this.sqftArea,
    required this.selectedDate,
    required this.selectedTime,
    required this.totalPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'Credit & Debit Cards';

  final List<Map<String, dynamic>> _methods = [
    {'name': 'Credit & Debit Cards', 'icon': Icons.credit_card},
    {'name': 'Net Banking', 'icon': Icons.account_balance},
    {'name': 'Cash On Delivery', 'icon': Icons.local_shipping_outlined},
    {'name': 'Wallets', 'icon': Icons.account_balance_wallet_outlined},
  ];

  final List<Map<String, dynamic>> _upis = [
    {'name': 'Paytm', 'color': Color(0xFF00B9F5), 'textColor': Colors.white},
    {'name': 'PhonePe', 'color': Color(0xFF5F259F), 'textColor': Colors.white},
    {'name': 'Amazon Pay', 'color': Color(0xFFFF9900), 'textColor': Colors.black},
    {'name': 'Freecharge', 'color': Color(0xFFFF5A5F), 'textColor': Colors.white},
    {'name': 'Ola Money', 'color': Color(0xFF00D100), 'textColor': Colors.white},
  ];

  void _onPayPressed() {
    // Add the booking to BookingService on confirmation/payment success!
    BookingService.instance.addBooking(
      serviceTitle: '${widget.categoryName} (${widget.bhkSize})',
      providerName: 'Premium Cleaners Inc.',
      price: widget.totalPrice,
      localImageAssetKey: widget.imagePath,
    );

    // Route to confirmation screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingConfirmedScreen(
          categoryName: widget.categoryName,
          selectedDate: widget.selectedDate,
          selectedTime: widget.selectedTime,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Payment Methods List
                  ..._methods.map((method) {
                    final isSelected = _selectedMethod == method['name'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedMethod = method['name'] as String;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F6F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(method['icon'] as IconData, color: Colors.black, size: 24),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  method['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Colors.black, size: 20)
                              else
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey, width: 1.5),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // 2. UPIs Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.phone_android, color: Colors.black54, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'UPIs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _upis.map((upi) {
                            final isSelected = _selectedMethod == upi['name'];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedMethod = upi['name'] as String;
                                });
                              },
                              child: Container(
                                width: 90,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? Colors.black : Colors.transparent,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: upi['color'] as Color,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (upi['name'] as String).split(' ')[0],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: upi['textColor'] as Color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      upi['name'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Persistent capsule footer
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$ ${widget.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: _onPayPressed,
                    child: const Row(
                      children: [
                        Text(
                          'Pay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
