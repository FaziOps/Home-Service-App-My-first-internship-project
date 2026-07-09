import 'package:flutter/material.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final String categoryName;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  const BookingConfirmedScreen({
    super.key,
    required this.categoryName,
    required this.selectedDate,
    required this.selectedTime,
  });

  final List<String> _months = const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  final List<String> _weekdays = const [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final weekdayName = _weekdays[selectedDate.weekday - 1];
    final formattedTime = _formatTimeOfDay(selectedTime);
    final formattedDate = '${selectedDate.day} ${_months[selectedDate.month - 1]}, ${selectedDate.year}';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // 1. Success checkmark icon inside circle
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 64,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // 2. Title "Confirmed"
              const Text(
                'Confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 24),

              // 3. Confirm description text
              Text(
                'Your booking has been confirmed for $formattedDate\nYou will get an email with the booking details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // 4. Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$formattedTime on $weekdayName',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // 5. Go Back Home button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Pop all the way back to the root tab/HomeScreen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text(
                    'Go Back Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
