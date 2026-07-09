import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';
import '../../models/service_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

/// Standalone admin view (routed inside the same app, per the PRD's
/// "Web or Separate Flutter View" option). Anyone who can reach this
/// route can write to `services` — see the README note on Firestore
/// security rules before shipping this to real users.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String _selectedCategory = kCategories.first.name;
  bool _submitting = false;
  bool _checkingAdmin = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String uidToCheck = user.uid;
        final displayName = user.displayName ?? '';
        if (displayName.startsWith('PHONE:')) {
          final phone = FirestoreService.normalizePhone(displayName.substring(6));
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();
          if (snap.docs.isNotEmpty) {
            uidToCheck = snap.docs.first.id;
          }
        }
        final doc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(uidToCheck)
            .get();
        if (mounted) {
          setState(() {
            _isAdmin = doc.exists;
            _checkingAdmin = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _checkingAdmin = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _checkingAdmin = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _assetKeyForCategory(String category) {
    for (final c in kCategories) {
      if (c.name == category) return c.iconAssetKey;
    }
    return 'assets/images/placeholder.png';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await FirestoreService.instance.addService(
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        localImageAssetKey: _assetKeyForCategory(_selectedCategory),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${_titleController.text}" added to $_selectedCategory.')),
      );
      _titleController.clear();
      _descriptionController.clear();
      _priceController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAdmin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This section is only accessible to authorized administrator accounts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add a new service',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text(
                'Saves directly to the services collection in Firestore. It appears in the user app under the selected category within seconds.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Service title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Price', prefixText: '\$ '),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid non-negative number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: kCategories
                    .map((c) => DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: AppColors.primaryDark),
                      )
                    : const Text('Save Service'),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 12),
              const Text('Existing services',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              StreamBuilder<List<ServiceModel>>(
                stream: FirestoreService.instance.streamAllServices(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final services = snapshot.data!;
                  if (services.isEmpty) {
                    return const Text('No services yet.',
                        style: TextStyle(color: AppColors.textSecondary));
                  }
                  return Column(
                    children: services
                        .map((s) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(s.title),
                                subtitle: Text(
                                    '${s.category} · \$${s.price.toStringAsFixed(2)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: AppColors.error),
                                  onPressed: () => FirestoreService.instance
                                      .deleteService(s.id),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
