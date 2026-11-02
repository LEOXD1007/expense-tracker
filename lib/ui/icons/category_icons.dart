import 'package:flutter/material.dart';

const categoryIconChoices = <String, IconData>{
  'restaurant': Icons.restaurant_rounded,
  'transit': Icons.directions_subway_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'entertainment': Icons.sports_esports_rounded,
  'housing': Icons.home_rounded,
  'medical': Icons.medical_services_rounded,
  'education': Icons.school_rounded,
  'comms': Icons.phone_iphone_rounded,
  'daily': Icons.local_mall_rounded,
  'other': Icons.more_horiz_rounded,
  'salary': Icons.payments_rounded,
  'bonus': Icons.emoji_events_rounded,
  'invest': Icons.trending_up_rounded,
  'parttime': Icons.work_rounded,
  'other_income': Icons.add_circle_outline_rounded,
  'coffee': Icons.coffee_rounded,
  'pet': Icons.pets_rounded,
  'travel': Icons.flight_rounded,
  'beauty': Icons.face_retouching_natural_rounded,
  'book': Icons.menu_book_rounded,
  'sport': Icons.fitness_center_rounded,
  'bill': Icons.receipt_long_rounded,
  'gift': Icons.card_giftcard_rounded,
};

IconData categoryIcon(String key) =>
    categoryIconChoices[key] ?? Icons.category_outlined;
