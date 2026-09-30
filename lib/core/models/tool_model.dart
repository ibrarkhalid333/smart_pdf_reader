import 'package:flutter/material.dart';

class ToolModel {
  final String id;
  final String name;
  final IconData icon;
  final String? shopItemId;
  final bool isFree;

  const ToolModel({
    required this.id,
    required this.name,
    required this.icon,
    this.shopItemId,
    this.isFree = false,
  });
}
