import 'package:flutter/material.dart';

/// Fixed, pre-seeded categories — matches the PRD's "Pre-seeded Dropdown
/// choices" requirement for the Admin Panel's category field, and drives
/// the category chips on the Home screen.
class CategoryModel {
  final String name;
  final IconData icon;
  final String iconAssetKey;

  const CategoryModel({
    required this.name,
    required this.icon,
    required this.iconAssetKey,
  });
}

const List<CategoryModel> kCategories = [
  CategoryModel(
    name: 'Plumbing',
    icon: Icons.plumbing_outlined,
    iconAssetKey: 'assets/images/plumbing_default.png',
  ),
  CategoryModel(
    name: 'Cleaning',
    icon: Icons.cleaning_services_outlined,
    iconAssetKey: 'assets/images/cleaning_default.png',
  ),
  CategoryModel(
    name: 'Electrical',
    icon: Icons.electrical_services_outlined,
    iconAssetKey: 'assets/images/electrical_default.png',
  ),
  CategoryModel(
    name: 'Painting',
    icon: Icons.format_paint_outlined,
    iconAssetKey: 'assets/images/painting_default.png',
  ),
  CategoryModel(
    name: 'Appliance Repair',
    icon: Icons.kitchen_outlined,
    iconAssetKey: 'assets/images/appliance_default.png',
  ),
  CategoryModel(
    name: 'Carpentry',
    icon: Icons.carpenter_outlined,
    iconAssetKey: 'assets/images/carpentry_default.png',
  ),
];

/// Falls back to a generic icon for any category string that doesn't
/// match the pre-seeded list (e.g. legacy data added outside the admin
/// panel's dropdown).
IconData iconForCategory(String category) {
  for (final c in kCategories) {
    if (c.name.toLowerCase() == category.toLowerCase()) return c.icon;
  }
  return Icons.home_repair_service_outlined;
}
