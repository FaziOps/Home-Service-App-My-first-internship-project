import 'package:flutter/material.dart';
import '../../services/booking_service.dart';

class ServiceProvider {
  final String name;
  final String categoryName;
  final double rating;
  final double hourlyRate;
  final String imageAsset;
  bool isFavorite;

  ServiceProvider({
    required this.name,
    required this.categoryName,
    required this.rating,
    required this.hourlyRate,
    required this.imageAsset,
    this.isFavorite = false,
  });
}

class ServiceProvidersScreen extends StatefulWidget {
  final String category;

  const ServiceProvidersScreen({super.key, required this.category});

  @override
  State<ServiceProvidersScreen> createState() => _ServiceProvidersScreenState();
}

class _ServiceProvidersScreenState extends State<ServiceProvidersScreen> {
  late List<ServiceProvider> _providers;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  void _loadProviders() {
    // Mock data matching user screenshot categories and employee details
    final allMockProviders = [
      ServiceProvider(
        name: 'Michel smith',
        categoryName: 'Plumbers',
        rating: 3.5,
        hourlyRate: 330,
        imageAsset: 'assets/images/plumbing_default.png',
      ),
      ServiceProvider(
        name: 'John carter',
        categoryName: 'Plumbers',
        rating: 4.5,
        hourlyRate: 250,
        imageAsset: 'assets/images/plumbing_default.png',
      ),
      ServiceProvider(
        name: 'Michel smith',
        categoryName: 'Electrician',
        rating: 3.5,
        hourlyRate: 250,
        imageAsset: 'assets/images/electrical_default.png',
      ),
      ServiceProvider(
        name: 'Sammy jaine',
        categoryName: 'Electrician',
        rating: 4.0,
        hourlyRate: 280,
        imageAsset: 'assets/images/electrical_default.png',
      ),
      ServiceProvider(
        name: 'Michel smith',
        categoryName: 'painter',
        rating: 3.5,
        hourlyRate: 150,
        imageAsset: 'assets/images/painting_default.png',
      ),
      ServiceProvider(
        name: 'Carry John',
        categoryName: 'painter',
        rating: 4.2,
        hourlyRate: 180,
        imageAsset: 'assets/images/painting_default.png',
      ),
      ServiceProvider(
        name: 'Michel John',
        categoryName: 'Home Clean',
        rating: 3.5,
        hourlyRate: 350,
        imageAsset: 'assets/images/cleaning_default.png',
      ),
      ServiceProvider(
        name: 'John carter',
        categoryName: 'Home Clean',
        rating: 4.5,
        hourlyRate: 220,
        imageAsset: 'assets/images/cleaning_default.png',
      ),
      ServiceProvider(
        name: 'John Doe',
        categoryName: 'Carpenters',
        rating: 4.1,
        hourlyRate: 290,
        imageAsset: 'assets/images/carpentry_default.png',
      ),
      ServiceProvider(
        name: 'David Miller',
        categoryName: 'Carpenters',
        rating: 4.6,
        hourlyRate: 310,
        imageAsset: 'assets/images/carpentry_default.png',
      ),
    ];

    // Filter by category
    final filterCat = widget.category.toLowerCase();
    _providers = allMockProviders.where((p) {
      final nameMatches = p.categoryName.toLowerCase().contains(filterCat) ||
          filterCat.contains(p.categoryName.toLowerCase()) ||
          (filterCat == 'plumbing' && p.categoryName.toLowerCase() == 'plumbers') ||
          (filterCat == 'electrical' && p.categoryName.toLowerCase() == 'electrician') ||
          (filterCat == 'painting' && p.categoryName.toLowerCase() == 'painter') ||
          (filterCat == 'carpentry' && p.categoryName.toLowerCase() == 'carpenters') ||
          (filterCat == 'cleaning' && p.categoryName.toLowerCase() == 'home clean');
      return nameMatches;
    }).toList();

    // Fallback if no matching provider found, display some default plumbing/cleaning
    if (_providers.isEmpty) {
      _providers = [
        ServiceProvider(
          name: 'Michel smith',
          categoryName: widget.category,
          rating: 3.5,
          hourlyRate: 250,
          imageAsset: 'assets/images/placeholder.png',
        ),
      ];
    }
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
          'Service Providers',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _providers.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final p = _providers[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Image Stack
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        p.imageAsset,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            p.isFavorite = !p.isFavorite;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            p.isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: p.isFavorite ? Colors.red : Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Center-Right Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.categoryName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFA726), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Pricing and Book button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${p.hourlyRate.toStringAsFixed(0)}/hr',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        debugPrint('Book button pressed for ${p.name}');
                        // Add booking
                        BookingService.instance.addBooking(
                          serviceTitle: '${widget.category} Service',
                          providerName: p.name,
                          price: p.hourlyRate,
                          localImageAssetKey: p.imageAsset,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully booked ${p.name}!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                      child: const Text('Book'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
