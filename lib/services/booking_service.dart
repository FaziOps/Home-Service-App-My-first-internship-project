import 'package:flutter/foundation.dart';

class BookingModel {
  final String id;
  final String serviceTitle;
  final String providerName;
  final String date;
  final String status; // "In Process", "Assigned", "Completed", "Cancelled"
  final double price;
  final String localImageAssetKey;

  BookingModel({
    required this.id,
    required this.serviceTitle,
    required this.providerName,
    required this.date,
    required this.status,
    required this.price,
    required this.localImageAssetKey,
  });
}

class BookingService {
  BookingService._internal() {
    // Seed initial bookings matching the user screenshot
    _bookings.addAll([
      BookingModel(
        id: 'b1',
        serviceTitle: 'Full House Cleaning',
        providerName: 'Jaylon Cleaning Services',
        date: 'Jan 4, 2022 at 4am',
        status: 'In Process',
        price: 2599,
        localImageAssetKey: 'assets/images/cleaning_default.png',
      ),
      BookingModel(
        id: 'b2',
        serviceTitle: 'Kitchen Cleaning',
        providerName: 'Sj Cleaning Services',
        date: 'Dec 4, 2022 at 6am',
        status: 'Assigned',
        price: 3000,
        localImageAssetKey: 'assets/images/cleaning_default.png',
      ),
      BookingModel(
        id: 'b3',
        serviceTitle: 'Bedroom Cleaning',
        providerName: 'John Cleaning Services',
        date: 'Feb 17, 2022 at 6am',
        status: 'Assigned',
        price: 2499,
        localImageAssetKey: 'assets/images/cleaning_default.png',
      ),
    ]);
  }
  static final BookingService instance = BookingService._internal();

  final List<BookingModel> _bookings = [];
  final List<VoidCallback> _listeners = [];

  List<BookingModel> get bookings => List.unmodifiable(_bookings);

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  void addBooking({
    required String serviceTitle,
    required String providerName,
    required double price,
    required String localImageAssetKey,
  }) {
    final newBooking = BookingModel(
      id: 'b_${DateTime.now().millisecondsSinceEpoch}',
      serviceTitle: serviceTitle,
      providerName: providerName,
      date: 'Today at ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      status: 'Assigned',
      price: price,
      localImageAssetKey: localImageAssetKey,
    );
    _bookings.insert(0, newBooking);
    _notifyListeners();
  }

  void cancelBooking(String id) {
    final index = _bookings.indexWhere((b) => b.id == id);
    if (index != -1) {
      final old = _bookings[index];
      _bookings[index] = BookingModel(
        id: old.id,
        serviceTitle: old.serviceTitle,
        providerName: old.providerName,
        date: old.date,
        status: 'Cancelled',
        price: old.price,
        localImageAssetKey: old.localImageAssetKey,
      );
      _notifyListeners();
    }
  }
}
