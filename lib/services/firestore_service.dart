import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_model.dart';

/// All Firestore reads/writes for the `services` collection live here so
/// screens never talk to Firestore directly. Keeps the sync boundary in
/// one place and makes the <2s replication requirement from the PRD easy
/// to reason about — it's just snapshot listeners end to end.
class FirestoreService {
  FirestoreService._internal();
  static final FirestoreService instance = FirestoreService._internal();

  final CollectionReference<Map<String, dynamic>> _servicesRef =
      FirebaseFirestore.instance.collection('services');

  /// Live stream of all services, newest first. The Home screen groups
  /// these by category client-side.
  Stream<List<ServiceModel>> streamAllServices() {
    return _servicesRef
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ServiceModel.fromFirestore).toList());
  }

  Stream<ServiceModel> streamService(String id) {
    return _servicesRef
        .doc(id)
        .snapshots()
        .map((doc) => ServiceModel.fromFirestore(doc));
  }

  Future<void> addService({
    required String title,
    required String description,
    required double price,
    required String category,
    required String localImageAssetKey,
  }) {
    final model = ServiceModel(
      id: '',
      title: title.trim(),
      description: description.trim(),
      price: price,
      category: category,
      localImageAssetKey: localImageAssetKey,
    );
    return _servicesRef.add(model.toFirestore());
  }

  static String normalizePhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92') && digits.length > 10) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  Future<void> createUserProfile(
    String uid, {
    required String fullName,
    required String email,
    required String phone,
  }) {
    return FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phone': normalizePhone(phone),
      'about': 'I am great to accept any service at free of cost. Provider please contact me if any issue is faced. Thank you.',
      'profileImageUrl': '',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserProfile(
    String uid, {
    required String fullName,
    required String email,
    required String about,
    required String profileImageUrl,
  }) {
    return FirebaseFirestore.instance.collection('users').doc(uid).update({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'about': about.trim(),
      'profileImageUrl': profileImageUrl,
    });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserProfile(String uid) {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Future<void> deleteService(String id) => _servicesRef.doc(id).delete();
}
