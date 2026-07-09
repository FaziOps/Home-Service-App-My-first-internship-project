import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/service_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../admin/admin_panel_screen.dart';
import '../splash/onboarding_screen.dart';
import 'service_details_screen.dart';
import 'service_providers_screen.dart';
import '../../services/booking_service.dart';
import '../../services/review_service.dart';
import 'apartment_booking_screen.dart';
import 'my_profile_screen.dart';
import 'view_all_categories_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _bottomNavIndex = 0;
  int _bookingsTabSelected = 0; // 0 = Active, 1 = History
  String? _selectedCategory; // null = "All"
  String _searchQuery = '';

  StreamSubscription? _userSub;
  StreamSubscription? _adminSub;
  String _userName = 'John Smith';
  String _userEmail = 'johnsmith@gmail.com';
  String _userAbout = 'I am great to accept any service at free of cost. Provider please contact me if any issue is faced. Thank you.';
  String _userProfileImageUrl = '';
  String _userUid = '';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    BookingService.instance.addListener(_onBookingsChanged);
    ReviewService.instance.addListener(_onReviewsChanged);
    _listenToUserProfile();
  }

  void _listenToUserProfile() {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      _userUid = user.uid;
      final displayName = user.displayName ?? '';
      if (displayName.startsWith('PHONE:')) {
        final phone = FirestoreService.normalizePhone(displayName.substring(6));
        _userSub = FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: phone)
            .limit(1)
            .snapshots()
            .listen((snap) {
          if (snap.docs.isNotEmpty) {
            final doc = snap.docs.first;
            final data = doc.data();
            if (mounted) {
              setState(() {
                _userUid = doc.id;
                _userName = data['fullName'] ?? 'John Smith';
                _userEmail = data['email'] ?? 'johnsmith@gmail.com';
                _userAbout = data['about'] ?? 'I am great to accept any service at free of cost. Provider please contact me if any issue is faced. Thank you.';
                _userProfileImageUrl = data['profileImageUrl'] ?? '';
              });

              _adminSub?.cancel();
              _adminSub = FirebaseFirestore.instance
                  .collection('admins')
                  .doc(_userUid)
                  .snapshots()
                  .listen((adminDoc) {
                if (mounted) {
                  setState(() {
                    _isAdmin = adminDoc.exists;
                  });
                }
              });
            }
          }
        });
      } else {
        _userEmail = user.email ?? 'johnsmith@gmail.com';
        _userName = user.displayName ?? 'John Smith';
        
        _userSub = FirestoreService.instance.streamUserProfile(user.uid).listen((doc) {
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (mounted) {
              setState(() {
                _userUid = user.uid;
                _userName = data['fullName'] ?? _userName;
                _userEmail = data['email'] ?? _userEmail;
                _userAbout = data['about'] ?? 'I am great to accept any service at free of cost. Provider please contact me if any issue is faced. Thank you.';
                _userProfileImageUrl = data['profileImageUrl'] ?? '';
              });

              _adminSub?.cancel();
              _adminSub = FirebaseFirestore.instance
                  .collection('admins')
                  .doc(_userUid)
                  .snapshots()
                  .listen((adminDoc) {
                if (mounted) {
                  setState(() {
                    _isAdmin = adminDoc.exists;
                  });
                }
              });
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    BookingService.instance.removeListener(_onBookingsChanged);
    ReviewService.instance.removeListener(_onReviewsChanged);
    _userSub?.cancel();
    _adminSub?.cancel();
    super.dispose();
  }

  void _onBookingsChanged() {
    if (mounted) setState(() {});
  }

  void _onReviewsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBody() {
    switch (_bottomNavIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildSearchTab();
      case 2:
        return _buildBookingsTab();
      case 3:
        return _buildAccountTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final greetingName = (_userName.isEmpty || _userName == 'John Smith') ? 'there' : _userName;

    return StreamBuilder<List<ServiceModel>>(
      stream: FirestoreService.instance.streamAllServices(),
      builder: (context, snapshot) {
        final allServices = snapshot.data ?? [];
        final filtered = allServices.where((s) {
          final matchesCategory = _selectedCategory == null ||
              s.category.toLowerCase() == _selectedCategory!.toLowerCase();
          
          if (_searchQuery.isEmpty) return matchesCategory;

          final query = _searchQuery.toLowerCase().trim();
          final title = s.title.toLowerCase();
          final category = s.category.toLowerCase();
          final description = s.description.toLowerCase();

          // 1. Direct contains match
          bool isMatch = title.contains(query) || 
                         category.contains(query) || 
                         description.contains(query);

          // 2. Query contains title/category
          if (!isMatch) {
            isMatch = query.contains(title) || query.contains(category);
          }

          // 3. Prefix stem match (e.g. "plumbers" matching "plumbing" via first 4 letters)
          if (!isMatch && query.length >= 4) {
            final stem = query.substring(0, 4);
            isMatch = title.contains(stem) || category.contains(stem) || description.contains(stem);
          }

          return matchesCategory && isMatch;
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Custom Top Bar (Menu & Notification)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none_outlined, color: Colors.black, size: 28),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // 2. Greeting Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Hello ',
                          style: TextStyle(fontSize: 22, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '👋',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                    Text(
                      greetingName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    textInputAction: TextInputAction.search,
                    onSubmitted: (q) => setState(() => _searchQuery = q),
                    onChanged: (q) => setState(() => _searchQuery = q),
                    decoration: InputDecoration(
                      hintText: 'Search services',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_searchQuery.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Search Results (${filtered.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No services found matching "$_searchQuery"',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final s = filtered[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: s.localImageAssetKey.isNotEmpty
                                ? Image.asset(s.localImageAssetKey, width: 60, height: 60, fit: BoxFit.cover)
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.build_outlined, color: Colors.grey),
                                  ),
                          ),
                          title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text('\$${s.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F4A40))),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ApartmentBookingScreen(
                                  categoryName: s.title,
                                  imagePath: s.localImageAssetKey.isNotEmpty ? s.localImageAssetKey : 'assets/images/plumbing_default.png',
                                  basePriceFactor: s.price / 100.0,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ] else ...[
                // 4. Promo Slider
                const _PromoSlider(),
                const SizedBox(height: 28),

                // 5. Home Services Section
                _buildSectionHeader(
                  'Home Services',
                  onTrailingTap: () => _openViewAllCategories('Home Services'),
                ),
                const SizedBox(height: 16),
                _buildHomeServicesRow(),
                const SizedBox(height: 28),

                // 6. Home Construction Section
                _buildSectionHeader(
                  'Home Construction',
                  onTrailingTap: () => _openViewAllCategories('Home Construction'),
                ),
                const SizedBox(height: 16),
                _buildHomeConstructionRow(),
                const SizedBox(height: 28),

                // 7. Renovate your home Section
                _buildSectionHeader(
                  'Renovate your home',
                  onTrailingTap: () => _openViewAllCategories('Renovate your home'),
                ),
                const SizedBox(height: 16),
                _buildRenovateYourHomeRow(),
                const SizedBox(height: 28),

                // 8. Combos And Subscriptions Section
                _buildSectionHeader(
                  'Combos And Subscriptions',
                  onTrailingTap: () => _openViewAllCategories('Combos And Subscriptions'),
                ),
                const SizedBox(height: 16),
                _buildCombosAndSubscriptionsRow(),
                const SizedBox(height: 28),

                // 9. What our customers say Section
                _buildSectionHeader(
                  'What our customers say',
                  trailingText: '+ Add Review',
                  onTrailingTap: _showAddReviewBottomSheet,
                ),
                const SizedBox(height: 16),
                _buildWhatOurCustomersSayRow(),
                const SizedBox(height: 32),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openViewAllCategories(String sectionTitle) {
    String bannerImage = 'assets/images/onboarding1.png';
    List<ViewAllCategoryItem> items = [];

    if (sectionTitle == 'Home Services') {
      bannerImage = 'assets/images/plumbing_default.png';
      items = [
        ViewAllCategoryItem(
          title: 'Plumbers',
          image: 'assets/images/plumbing_default.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Plumbers')),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Electricians',
          image: 'assets/images/electrical_default.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Electricians')),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Painters',
          image: 'assets/images/painting_default.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Painters')),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Carpenters',
          image: 'assets/images/carpentry_default.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Carpenters')),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Home Cleaning',
          image: 'assets/images/cleaning_default.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Home Cleaning')),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Car Washers',
          image: 'assets/images/appliance_default.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Car Washers')),
          ),
        ),
      ];
    } else if (sectionTitle == 'Home Construction') {
      bannerImage = 'assets/images/onboarding3.png';
      items = [
        ViewAllCategoryItem(
          title: 'Construction',
          image: 'assets/images/onboarding2.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Construction')),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Architects',
          image: 'assets/images/onboarding1.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Architects')),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Interior Design',
          image: 'assets/images/onboarding3.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Interior Design')),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Furniture',
          image: 'assets/images/carpentry_default.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ServiceProvidersScreen(category: 'Furniture')),
          ),
        ),
      ];
    } else if (sectionTitle == 'Renovate your home') {
      bannerImage = 'assets/images/onboarding1.png';
      items = [
        ViewAllCategoryItem(
          title: 'Home Interiors',
          image: 'assets/images/onboarding1.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ApartmentBookingScreen(
                categoryName: 'Home Interiors',
                imagePath: 'assets/images/onboarding1.png',
                basePriceFactor: 1.5,
              ),
            ),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Modular Kitchen',
          image: 'assets/images/onboarding3.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ApartmentBookingScreen(
                categoryName: 'Modular Kitchen',
                imagePath: 'assets/images/onboarding3.png',
                basePriceFactor: 2.0,
              ),
            ),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Construction',
          image: 'assets/images/onboarding2.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ApartmentBookingScreen(
                categoryName: 'Construction',
                imagePath: 'assets/images/onboarding2.png',
                basePriceFactor: 1.0,
              ),
            ),
          ),
        ),
      ];
    } else if (sectionTitle == 'Combos And Subscriptions') {
      bannerImage = 'assets/images/onboarding2.png';
      items = [
        ViewAllCategoryItem(
          title: 'Pest Control',
          image: 'assets/images/onboarding2.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ApartmentBookingScreen(
                categoryName: 'Pest Control',
                imagePath: 'assets/images/onboarding2.png',
                basePriceFactor: 0.4,
              ),
            ),
          ),
        ),
        ViewAllCategoryItem(
          title: 'Full House Cleaning',
          image: 'assets/images/cleaning_default.png',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const ApartmentBookingScreen(
                categoryName: 'Full House Cleaning',
                imagePath: 'assets/images/cleaning_default.png',
                basePriceFactor: 1.0,
              ),
            ),
          ),
        ),
      ];
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ViewAllCategoriesScreen(
          title: sectionTitle,
          bannerImage: bannerImage,
          items: items,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String trailingText = 'View All', VoidCallback? onTrailingTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (trailingText.isNotEmpty)
            GestureDetector(
              onTap: onTrailingTap ?? () {},
              child: Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA726),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRenovateYourHomeRow() {
    final items = [
      {'name': 'Home Interiors', 'image': 'assets/images/onboarding1.png'},
      {'name': 'Modular Kitchen', 'image': 'assets/images/onboarding3.png'},
      {'name': 'Construction', 'image': 'assets/images/onboarding2.png'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.map((item) {
          return GestureDetector(
            onTap: () {
              final cat = item['name']!;
              final img = item['image']!;
              double multiplier = 1.0;
              if (cat == 'Home Interiors') {
                multiplier = 1.5;
              } else if (cat == 'Modular Kitchen') {
                multiplier = 2.0;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ApartmentBookingScreen(
                    categoryName: cat,
                    imagePath: img,
                    basePriceFactor: multiplier,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      item['image']!,
                      width: 180,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['name']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCombosAndSubscriptionsRow() {
    final items = [
      {'name': 'Pest Control', 'image': 'assets/images/onboarding2.png'},
      {'name': 'Full House Cleaning', 'image': 'assets/images/cleaning_default.png'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: items.map((item) {
          return GestureDetector(
            onTap: () {
              final cat = item['name']!;
              final img = item['image']!;
              double multiplier = 1.0;
              if (cat == 'Pest Control') {
                multiplier = 0.4;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ApartmentBookingScreen(
                    categoryName: cat,
                    imagePath: img,
                    basePriceFactor: multiplier,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      item['image']!,
                      width: 180,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['name']!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWhatOurCustomersSayRow() {
    final reviews = ReviewService.instance.reviews;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: reviews.map((r) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage(r.userAvatarUrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.userName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < r.rating.floor()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: const Color(0xFFFFA726),
                                  size: 16,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    r.reviewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAddReviewBottomSheet() {
    String name = '';
    double rating = 5.0;
    String comment = '';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Write a Review',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1.0;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              rating = starValue;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              rating >= starValue ? Icons.star : Icons.star_border,
                              color: const Color(0xFFFFA726),
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter your name',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                      onChanged: (v) => name = v,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Review comment',
                        hintText: 'Share your experience',
                      ),
                      maxLines: 3,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your review comment' : null,
                      onChanged: (v) => comment = v,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          ReviewService.instance.addReview(
                            userName: name.trim(),
                            rating: rating,
                            reviewText: comment.trim(),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Review submitted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Submit Review'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHomeServicesRow() {
    final services = [
      {'name': 'Plumber', 'category': 'Plumbing', 'icon': Icons.plumbing_outlined},
      {'name': 'Electrician', 'category': 'Electrical', 'icon': Icons.electrical_services_outlined},
      {'name': 'Painting', 'category': 'Painting', 'icon': Icons.format_paint_outlined},
      {'name': 'Carpenter', 'category': 'Carpentry', 'icon': Icons.carpenter_outlined},
      {'name': 'Cleaning', 'category': 'Cleaning', 'icon': Icons.cleaning_services_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: services.map((s) {
          final isSelected = _selectedCategory == s['category'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCategoryCircle(
              label: s['name'] as String,
              icon: s['icon'] as IconData,
              isSelected: isSelected,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ServiceProvidersScreen(category: s['name'] as String),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHomeConstructionRow() {
    final constructionItems = [
      {'name': 'Construction', 'icon': Icons.home_work_outlined},
      {'name': 'Architects', 'icon': Icons.architecture_outlined},
      {'name': 'Interior Design', 'icon': Icons.chair_outlined},
      {'name': 'Furniture', 'icon': Icons.table_restaurant_outlined},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: constructionItems.map((c) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildCategoryCircle(
              label: c['name'] as String,
              icon: c['icon'] as IconData,
              isSelected: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ServiceProvidersScreen(category: c['name'] as String),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCircle({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : const Color(0xFFF6F6F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularServicesRow(List<ServiceModel> services) {
    if (services.isEmpty) {
      // Fallback dummy services when database is empty
      final dummyServices = [
        const ServiceModel(
          id: 'dummy_plumber',
          title: 'Emergency Plumbing',
          description: 'Fix leakages, pipe bursts, and fixture installations.',
          price: 120,
          category: 'Plumbing',
          localImageAssetKey: 'assets/images/plumbing_default.png',
        ),
        const ServiceModel(
          id: 'dummy_painter',
          title: 'Full House Painting',
          description: 'Premium wall finish and expert color consult.',
          price: 450,
          category: 'Painting',
          localImageAssetKey: 'assets/images/painting_default.png',
        ),
        const ServiceModel(
          id: 'dummy_cleaner',
          title: 'Express Home Cleaning',
          description: 'Deep kitchen, room dust, and floor sanitization.',
          price: 80,
          category: 'Cleaning',
          localImageAssetKey: 'assets/images/cleaning_default.png',
        ),
      ];
      return _buildHorizontalServiceCards(dummyServices);
    }
    return _buildHorizontalServiceCards(services);
  }

  Widget _buildHorizontalServiceCards(List<ServiceModel> list) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final s = list[index];
          return GestureDetector(
            onTap: () {
              if (s.id.startsWith('dummy')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Mock service "${s.title}" selected!')),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ServiceDetailsScreen(serviceId: s.id),
                ),
              );
            },
            child: Container(
              width: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Card Top half
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.asset(
                        s.localImageAssetKey,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF6F6F6),
                          child: const Icon(Icons.handyman_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  // Text Card Bottom half
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${s.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.star, color: Color(0xFFFFA726), size: 14),
                                SizedBox(width: 2),
                                Text(
                                  '4.8',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchTab() {
    final searchCategories = [
      {
        'title': 'Plumbers',
        'desc': 'Who helps you in plumbing works',
        'image': 'assets/images/plumbing_default.png'
      },
      {
        'title': 'Electricians',
        'desc': 'Who helps you in electrical works',
        'image': 'assets/images/electrical_default.png'
      },
      {
        'title': 'Painters',
        'desc': 'Who helps you in painting anything',
        'image': 'assets/images/painting_default.png'
      },
      {
        'title': 'Carpenters',
        'desc': 'Who helps you in carpenting works',
        'image': 'assets/images/carpentry_default.png'
      },
      {
        'title': 'Home Cleaning',
        'desc': 'Who helps you in cleaning the house',
        'image': 'assets/images/cleaning_default.png'
      },
      {
        'title': 'Car Washers',
        'desc': 'Who helps you in cleaning the car',
        'image': 'assets/images/appliance_default.png'
      },
    ];

    final filteredCategories = searchCategories.where((cat) {
      if (_searchQuery.isEmpty) return true;

      final query = _searchQuery.toLowerCase().trim();
      final title = cat['title']!.toLowerCase();
      final desc = cat['desc']!.toLowerCase();

      // 1. Direct contains match
      bool isMatch = title.contains(query) || desc.contains(query);

      // 2. Query contains title/desc
      if (!isMatch) {
        isMatch = query.contains(title) || query.contains(desc);
      }

      // 3. Prefix stem match (e.g. "plumbers" matching "plumbing" / "plumbing work")
      if (!isMatch && query.length >= 4) {
        final stem = query.substring(0, 4);
        isMatch = title.contains(stem) || desc.contains(stem);
      }

      return isMatch;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Search',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: (q) => setState(() => _searchQuery = q),
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                hintText: 'Search for services',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredCategories.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No categories found matching "$_searchQuery"',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ServiceProvidersScreen(category: cat['title']!),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          cat['image']!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat['title']!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat['desc']!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    final allBookings = BookingService.instance.bookings;
    final activeBookings = allBookings.where((b) => b.status == 'In Process' || b.status == 'Assigned').toList();
    final historyBookings = allBookings.where((b) => b.status == 'Completed' || b.status == 'Cancelled').toList();

    final currentList = _bookingsTabSelected == 0 ? activeBookings : historyBookings;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Bookings',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _bookingsTabSelected = 0),
                  child: Column(
                    children: [
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _bookingsTabSelected == 0 ? FontWeight.bold : FontWeight.w500,
                          color: _bookingsTabSelected == 0 ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        color: _bookingsTabSelected == 0 ? Colors.black : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _bookingsTabSelected = 1),
                  child: Column(
                    children: [
                      Text(
                        'History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _bookingsTabSelected == 1 ? FontWeight.bold : FontWeight.w500,
                          color: _bookingsTabSelected == 1 ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 2,
                        color: _bookingsTabSelected == 1 ? Colors.black : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: currentList.isEmpty
                ? Center(
                    child: Text(
                      'No bookings found.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  )
                : ListView.separated(
                    itemCount: currentList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final b = currentList[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F6F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  b.serviceTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  b.status,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: b.status == 'In Process' ? Colors.orange : Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    b.localImageAssetKey,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.providerName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            b.date,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${b.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (_bookingsTabSelected == 0) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1, color: Colors.black12),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  BookingService.instance.cancelBooking(b.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Booking cancelled successfully!')),
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: const Text(
                                    'Cancel',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab() {
    final userName = _userName.isEmpty ? 'John Smith' : _userName;
    final userEmail = _userEmail.isEmpty ? 'johnsmith@gmail.com' : _userEmail;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Text(
            'Account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: _userProfileImageUrl.isNotEmpty
                  ? NetworkImage(_userProfileImageUrl) as ImageProvider
                  : const AssetImage('assets/images/john_smith_profile.png'),
              backgroundColor: const Color(0xFFF6F6F6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            userName.isEmpty ? 'John Smith' : userName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail.isEmpty ? 'johnsmith@gmail.com' : userEmail,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // List options
          _buildAccountOption(
            icon: Icons.person_outline,
            title: 'My Profile',
            trailing: const Icon(Icons.edit, size: 20, color: Colors.black),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MyProfileScreen(
                    uid: _userUid,
                    initialName: _userName,
                    initialEmail: _userEmail,
                    initialAbout: _userAbout,
                    initialProfileImageUrl: _userProfileImageUrl,
                  ),
                ),
              );
            },
          ),
          _buildAccountOption(
            icon: Icons.favorite_border,
            title: 'My Favourites',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('My Favourites: Plumbing, Full House Cleaning')),
              );
            },
          ),
          _buildAccountOption(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          _buildAccountOption(
            icon: Icons.calendar_today_outlined,
            title: 'My bookings',
            onTap: () {
              setState(() => _bottomNavIndex = 2); // Switch to Bookings tab (index 2)
            },
          ),
          _buildAccountOption(
            icon: Icons.monetization_on_outlined,
            title: 'Refer and earn',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Refer and Earn'),
                  content: const Text('Share your referral code: HOMESERVE50\nEarn ₹50 for every friend who signs up!'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildAccountOption(
            icon: Icons.mail_outline,
            title: 'Contact Us',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact support at support@homeservice.com')),
              );
            },
          ),
          _buildAccountOption(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help Center: FAQ list loaded!')),
              );
            },
          ),
          _buildAccountOption(
            icon: Icons.local_offer_outlined,
            title: 'Offers And Coupons',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offers: 20% discount on first booking!')),
              );
            },
          ),
          if (_isAdmin) ...[
            const Divider(height: 1, color: Colors.black12),
            _buildAccountOption(
              icon: Icons.dashboard_customize_outlined,
              title: 'Admin Panel',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                );
              },
            ),
          ],
          _buildAccountOption(
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: _signOut,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    final userName = _userName.isEmpty ? 'John Smith' : _userName;
    final userEmail = _userEmail.isEmpty ? 'johnsmith@gmail.com' : _userEmail;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.black,
                    backgroundImage: _userProfileImageUrl.isNotEmpty
                        ? NetworkImage(_userProfileImageUrl)
                        : null,
                    child: _userProfileImageUrl.isEmpty
                        ? Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'J',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    userName.isEmpty ? 'John Smith' : userName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail.isEmpty ? 'johnsmith@gmail.com' : userEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerOption(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MyProfileScreen(
                            uid: _userUid,
                            initialName: _userName,
                            initialEmail: _userEmail,
                            initialAbout: _userAbout,
                            initialProfileImageUrl: _userProfileImageUrl,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildDrawerOption(
                    icon: Icons.favorite_border,
                    title: 'My Favourites',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('My Favourites: Plumbing, Full House Cleaning')),
                      );
                    },
                  ),
                  _buildDrawerOption(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No new notifications')),
                      );
                    },
                  ),
                  _buildDrawerOption(
                    icon: Icons.calendar_today_outlined,
                    title: 'My bookings',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _bottomNavIndex = 2); // Switch to Bookings tab
                    },
                  ),
                  _buildDrawerOption(
                    icon: Icons.monetization_on_outlined,
                    title: 'Refer and earn',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Refer and Earn'),
                          content: const Text('Share your referral code: HOMESERVE50\nEarn ₹50 for every friend who signs up!'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildDrawerOption(
                    icon: Icons.mail_outline,
                    title: 'Contact Us',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact support at support@homeservice.com')),
                      );
                    },
                  ),
                  _buildDrawerOption(
                    icon: Icons.help_outline,
                    title: 'Help Center',
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help Center: FAQ list loaded!')),
                      );
                    },
                  ),
                  _buildDrawerOption(
                    icon: Icons.exit_to_app,
                    title: 'Logout',
                    onTap: () {
                      Navigator.pop(context);
                      _signOut();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

class _PromoSlider extends StatefulWidget {
  const _PromoSlider();

  @override
  State<_PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<_PromoSlider> {
  int _currentSlide = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            itemCount: 3,
            onPageChanged: (index) {
              setState(() {
                _currentSlide = index;
              });
            },
            itemBuilder: (context, index) {
              final String assetKey;
              if (index == 0) {
                assetKey = 'assets/images/super_sale_banner.png';
              } else if (index == 1) {
                assetKey = 'assets/images/sale_banner.png';
              } else {
                assetKey = 'assets/images/red_offer_banner.png';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    assetKey,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final active = index == _currentSlide;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 16 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

