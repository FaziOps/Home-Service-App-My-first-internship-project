import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors the `services` Firestore collection defined in the PRD:
/// title, description, price, category, local_image_asset_key.
class ServiceModel {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String localImageAssetKey;
  final DateTime? createdAt;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.localImageAssetKey,
    this.createdAt,
  });

  factory ServiceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ServiceModel(
      id: doc.id,
      title: (data['title'] as String?) ?? 'Untitled service',
      description: (data['description'] as String?) ?? '',
      price: _toDouble(data['price']),
      category: (data['category'] as String?) ?? 'General',
      localImageAssetKey: (data['local_image_asset_key'] as String?) ??
          'assets/images/placeholder.png',
      createdAt: (data['created_at'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'local_image_asset_key': localImageAssetKey,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }
}
