import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/service_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class ServiceDetailsScreen extends StatelessWidget {
  final String serviceId;
  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<ServiceModel>(
        stream: FirestoreService.instance.streamService(serviceId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('This service could not be loaded.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final service = snapshot.data!;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 260,
                backgroundColor: AppColors.primaryDark,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Image.asset(
                    service.localImageAssetKey,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: AppColors.primaryDark,
                      child: Icon(iconForCategory(service.category),
                          size: 72, color: Colors.white24),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(iconForCategory(service.category),
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(service.category,
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(service.title,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      Text('\$${service.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent)),
                      const Divider(height: 40),
                      Text('About this service',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        service.description.isEmpty
                            ? 'No description provided.'
                            : service.description,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 15, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Booking flow is out of scope for this build — see PRD scope note.'),
                ),
              );
            },
            child: const Text('Book This Service'),
          ),
        ),
      ),
    );
  }
}
