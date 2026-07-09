import 'package:flutter/material.dart';
import 'payment_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String categoryName;
  final String imagePath;
  final String bhkSize;
  final String sqftArea;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final double unitPrice;

  const OrderSummaryScreen({
    super.key,
    required this.categoryName,
    required this.imagePath,
    required this.bhkSize,
    required this.sqftArea,
    required this.selectedDate,
    required this.selectedTime,
    required this.unitPrice,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  int _quantity = 1;
  final TextEditingController _couponController = TextEditingController();
  bool _isCouponApplied = false;
  double _discountPercentage = 0.0;
  bool _isBillExpanded = true;

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _couponController.addListener(_onCouponChanged);
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _onCouponChanged() {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'SAVE10') {
      if (!_isCouponApplied) {
        setState(() {
          _isCouponApplied = true;
          _discountPercentage = 10.0;
        });
      }
    } else {
      if (_isCouponApplied) {
        setState(() {
          _isCouponApplied = false;
          _discountPercentage = 0.0;
        });
      }
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  double get _subtotal => widget.unitPrice * _quantity;
  double get _discount => _isCouponApplied ? (_subtotal * (_discountPercentage / 100.0)) : 0.0;
  double get _tax => (_subtotal - _discount) * 0.05; // 5% tax
  double get _totalPrice => _subtotal - _discount + _tax;

  @override
  Widget build(BuildContext context) {
    final weekdayName = _weekdays[widget.selectedDate.weekday - 1];
    final formattedTime = _formatTimeOfDay(widget.selectedTime);

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
          'Order Summery',
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
                  // 1. Service Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                widget.imagePath,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.categoryName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'John Cleaning Services',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$formattedTime on $weekdayName',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Quantity selector (- 1 +) in Yellow
                            Container(
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_quantity > 1) {
                                        setState(() {
                                          _quantity--;
                                        });
                                      }
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '-',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _quantity++;
                                      });
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '+',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.sqftArea.isEmpty ? "Default" : widget.sqftArea} Sqft  |  ${widget.bhkSize}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '\$${_subtotal.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 2. Address Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.black54, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Address',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '2nd Street, Shushruthi Nagar, E City',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black54, size: 20),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 3. Apply Coupon Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_num_outlined, color: Colors.black54, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              'Apply Coupon',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Enter Coupon (Try: SAVE10)',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey, width: 0.5),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black, width: 1.0),
                            ),
                          ),
                        ),
                        if (_isCouponApplied) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Coupon "SAVE10" applied! 10% discount.',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Detailed Bill Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F6F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isBillExpanded = !_isBillExpanded;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Detailed Bill',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Icon(
                                _isBillExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                        if (_isBillExpanded) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Base Price (${widget.bhkSize} x $_quantity)', style: const TextStyle(color: Colors.grey)),
                              Text('\$${_subtotal.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                          if (_isCouponApplied) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Coupon Discount (10%)', style: TextStyle(color: Colors.green)),
                                Text('-\$${_discount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Taxes & Fees (5%)', style: TextStyle(color: Colors.grey)),
                              Text('\$${_tax.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '\$${_totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
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
          ),

          // 5. Persistent capsule footer
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
                    '\$ ${_totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentScreen(
                            categoryName: widget.categoryName,
                            imagePath: widget.imagePath,
                            bhkSize: widget.bhkSize,
                            sqftArea: widget.sqftArea,
                            selectedDate: widget.selectedDate,
                            selectedTime: widget.selectedTime,
                            totalPrice: _totalPrice,
                          ),
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        Text(
                          'Proceed to Pay',
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
