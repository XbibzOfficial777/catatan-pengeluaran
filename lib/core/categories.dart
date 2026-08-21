import 'package:flutter/material.dart';

import '../models/finance_models.dart';

IconData categoryIcon(ExpenseCategory category) {
  const icons = {
    ExpenseCategory.food: Icons.restaurant_rounded,
    ExpenseCategory.transport: Icons.directions_car_filled_rounded,
    ExpenseCategory.shopping: Icons.shopping_bag_rounded,
    ExpenseCategory.bills: Icons.receipt_rounded,
    ExpenseCategory.health: Icons.medical_services_rounded,
    ExpenseCategory.entertainment: Icons.movie_rounded,
    ExpenseCategory.other: Icons.more_horiz_rounded,
  };
  return icons[category]!;
}

Color categoryColor(ExpenseCategory category, ColorScheme colors) {
  const palette = {
    ExpenseCategory.food: Color(0xFFF97316),
    ExpenseCategory.transport: Color(0xFF3B82F6),
    ExpenseCategory.shopping: Color(0xFF8B5CF6),
    ExpenseCategory.bills: Color(0xFF0EA5E9),
    ExpenseCategory.health: Color(0xFFEF4444),
    ExpenseCategory.entertainment: Color(0xFFEC4899),
    ExpenseCategory.other: Color(0xFF64748B),
  };
  return palette[category]!;
}


