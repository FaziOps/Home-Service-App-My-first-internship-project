import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import 'order_summary_screen.dart';

class ApartmentBookingScreen extends StatefulWidget {
  final String categoryName;
  final String imagePath;
  final double basePriceFactor;

  const ApartmentBookingScreen({
    super.key,
    this.categoryName = 'Apartment Cleaning',
    this.imagePath = 'assets/images/onboarding1.png',
    this.basePriceFactor = 1.0,
  });

  @override
  State<ApartmentBookingScreen> createState() => _ApartmentBookingScreenState();
}

class _ApartmentBookingScreenState extends State<ApartmentBookingScreen> {
  // State variables
  String? _selectedBhk = '2 BHK'; // Pre-selected to match reference image 1
  final TextEditingController _areaController = TextEditingController();
  late DateTime _currentMonth;
  DateTime? _selectedDate = DateTime(2026, 7, 3); // Pre-selected to match "3 Fri" in reference image 1
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 15); // Pre-selected to match "7:15 AM" in reference image 2

  final List<String> _bhkOptions = [
    '1 BHK',
    '2 BHK',
    '2.5 BHK',
    '3 BHK',
    '3.5 BHK',
    '4 BHK',
    '4.5 BHK',
  ];

  final Map<String, double> _bhkPrices = {
    '1 BHK': 800,
    '2 BHK': 1000,
    '2.5 BHK': 1050,
    '3 BHK': 1150,
    '3.5 BHK': 1200,
    '4 BHK': 1250,
    '4.5 BHK': 1350,
  };

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(2026, 7); // Initialized to July 2026 to match reference images
    _areaController.addListener(_onAreaChanged);
  }

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  void _onAreaChanged() {
    setState(() {}); // Rebuild to update dynamic pricing
  }

  double get _totalPrice {
    double base = 0;
    if (_selectedBhk != null) {
      base = (_bhkPrices[_selectedBhk] ?? 0) * widget.basePriceFactor;
    }
    double surcharge = 0;
    final sqftText = _areaController.text;
    if (sqftText.isNotEmpty) {
      final sqft = double.tryParse(sqftText);
      if (sqft != null) {
        surcharge = sqft * 0.25; // $0.25 per sqft
      }
    }
    return base + surcharge;
  }

  int _daysInMonth(DateTime date) {
    var firstDayNextMonth = DateTime(date.year, date.month + 1, 1);
    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _incrementSqft() {
    setState(() {
      int currentVal = int.tryParse(_areaController.text) ?? 0;
      // Start at 1000 if empty, otherwise increment by 100
      if (currentVal == 0) {
        _areaController.text = '1000';
      } else {
        _areaController.text = (currentVal + 100).toString();
      }
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _submitBooking() {
    if (_selectedBhk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an apartment size.')),
      );
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          categoryName: widget.categoryName,
          imagePath: widget.imagePath,
          bhkSize: _selectedBhk!,
          sqftArea: _areaController.text,
          selectedDate: _selectedDate!,
          selectedTime: _selectedTime,
          unitPrice: (_bhkPrices[_selectedBhk] ?? 0) * widget.basePriceFactor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int days = _daysInMonth(_currentMonth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Cover Image Section
                  Stack(
                    children: [
                      Container(
                        height: 280,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(widget.imagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Gradient Overlay for readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Overlay Back Button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 16,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Apartment Size Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Text(
                      'Apartment Size',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _bhkOptions.map((option) {
                        final isSelected = _selectedBhk == option;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBhk = option;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.black : const Color(0xFFF6F6F6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3. Area in Sqft Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Text(
                      'Area in Sqft',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F6F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _areaController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Area in squre fit',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.black),
                            onPressed: _incrementSqft,
                            padding: const EdgeInsets.only(right: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 4. Pick a Date Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Text(
                      'Pick a date',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Month Navigator Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
                          onPressed: _previousMonth,
                        ),
                        Text(
                          '${_months[_currentMonth.month - 1]} ${_currentMonth.year}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.black, size: 28),
                          onPressed: _nextMonth,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Horizontal Dates ListView
                  SizedBox(
                    height: 84,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: days,
                      itemBuilder: (context, index) {
                        final date = DateTime(_currentMonth.year, _currentMonth.month, index + 1);
                        final isSelected = _selectedDate != null &&
                            _selectedDate!.year == date.year &&
                            _selectedDate!.month == date.month &&
                            _selectedDate!.day == date.day;
                        
                        // We construct weekday offset correctly
                        final weekdayStr = _weekdays[date.weekday - 1];

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            child: Container(
                              width: 64,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black : const Color(0xFFF6F6F6),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    weekdayStr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 5. Pick a Time Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Text(
                      'Pick a Time',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Selected time: ${_formatTimeOfDay(_selectedTime)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _pickTime,
                        child: const Text(
                          'SELECT TIME',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Persistent Capsule Footer
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
                    onTap: _submitBooking,
                    child: const Row(
                      children: [
                        Text(
                          'Continue',
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
