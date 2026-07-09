import 'package:flutter/foundation.dart';

class ReviewModel {
  final String id;
  final String userName;
  final double rating;
  final String reviewText;
  final String userAvatarUrl;
  final DateTime timestamp;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.reviewText,
    required this.userAvatarUrl,
    required this.timestamp,
  });
}

class ReviewService {
  ReviewService._internal() {
    // Seed default review matching the user screenshot
    _reviews.add(
      ReviewModel(
        id: 'r1',
        userName: 'Marry jaine',
        rating: 4.0,
        reviewText: 'Best App for services and I find it easy to solve all my house task with this app.I like the app very much',
        userAvatarUrl: 'assets/images/onboarding1.png',
        timestamp: DateTime.now(),
      ),
    );
  }
  static final ReviewService instance = ReviewService._internal();

  final List<ReviewModel> _reviews = [];
  final List<VoidCallback> _listeners = [];

  List<ReviewModel> get reviews => List.unmodifiable(_reviews);

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

  void addReview({
    required String userName,
    required double rating,
    required String reviewText,
  }) {
    final newReview = ReviewModel(
      id: 'r_${DateTime.now().millisecondsSinceEpoch}',
      userName: userName,
      rating: rating,
      reviewText: reviewText,
      userAvatarUrl: 'assets/images/onboarding2.png',
      timestamp: DateTime.now(),
    );
    _reviews.insert(0, newReview);
    _notifyListeners();
  }
}
