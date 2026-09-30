// lib/core/const/app_constants.dart
import 'package:flutter/material.dart';
import 'package:smart_pdf_reader/core/models/tool_model.dart';

// --- Data Models ---
class PdfDocument {
  final String title;
  final int pages; // 0 = unknown (not yet read from file)
  final String date;
  final Color color;
  final int currentPage;
  final int pagesRead;
  final String? filePath; // absolute path on device; null for mock data
  final int? fileSizeBytes; // null = unknown
  final bool isFavourite;

  PdfDocument({
    required this.title,
    required this.pages,
    required this.currentPage,
    this.pagesRead = 0,
    required this.date,
    required this.color,
    this.filePath,
    this.fileSizeBytes,
    this.isFavourite = false,
  });

  /// Human-readable file size string (e.g. "2.4 MB").
  String get fileSizeLabel {
    if (fileSizeBytes == null) return '';
    final kb = fileSizeBytes! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  PdfDocument copyWith({
    String? title,
    int? pages,
    int? currentPage,
    int? pagesRead,
    bool? isFavourite,
    String? date,
  }) {
    return PdfDocument(
      title: title ?? this.title,
      pages: pages ?? this.pages,
      currentPage: currentPage ?? this.currentPage,
      pagesRead: pagesRead ?? this.pagesRead,
      date: date ?? this.date,
      color: color,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      isFavourite: isFavourite ?? this.isFavourite,
    );
  }

  /// Subtitle shown under the title in the card.
  String get subtitle {
    final sizePart = fileSizeLabel.isNotEmpty ? fileSizeLabel : '';
    if (pages > 0) {
      return '$pages pages${sizePart.isNotEmpty ? ' · $sizePart' : ''} · $date';
    } else if (sizePart.isNotEmpty) {
      return '$sizePart · $date';
    }
    return date;
  }
}

class EarnTask {
  final IconData icon;
  final String title;
  final String subtitle;
  final int reward;
  EarnTask({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.reward,
  });
}

class Achievement {
  final String title;
  final int reward;
  final bool isUnlocked;
  Achievement({
    required this.title,
    required this.reward,
    this.isUnlocked = false,
  });
}

class ShopItem {
  final String id;
  final String name;
  final int cost;
  final String tier;
  final bool isPermanent;
  ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.tier,
    this.isPermanent = true,
  });
}

class AppConstants {
  // --- Home Mock Data ---
  // Empty: no files opened yet — populated as the user opens PDFs.
  static List<PdfDocument> recentPdfs = [];

  // --- Favourite Mock Data ---
  // Empty: no favourites yet — populated as the user stars files.
  static List<PdfDocument> favouritePdfs = [];

  // --- All Files Mock Data ---
  static List<PdfDocument> allPdfs = [
    PdfDocument(
      title: 'Atomic Habits.pdf',
      pages: 124,
      currentPage: 47,
      date: 'Today 9:10 AM',
      color: Colors.blue.shade100,
    ),
    PdfDocument(
      title: 'Design Systems Handbook.pdf',
      pages: 88,
      currentPage: 12,
      date: 'Yesterday',
      color: Colors.purple.shade100,
    ),
    PdfDocument(
      title: 'Python Crash Course.pdf',
      pages: 562,
      currentPage: 357,

      date: '2 days ago',
      color: Colors.green.shade100,
    ),
    PdfDocument(
      title: 'The Lean Startup.pdf',
      pages: 299,
      currentPage: 140,
      date: '4 days ago',
      color: Colors.orange.shade100,
    ),
    PdfDocument(
      title: 'Flutter in Action.pdf',
      pages: 350,
      currentPage: 235,
      date: '1 week ago',
      color: Colors.red.shade100,
    ),
  ];

  // --- Wallet Mock Data ---
  static List<EarnTask> earnTasks = [
    EarnTask(
      icon: Icons.login,
      title: 'Open Application',
      subtitle: 'Once per Day',
      reward: 5,
    ),
    EarnTask(
      icon: Icons.menu_book,
      title: 'Read Each Page',
      subtitle: 'Every Page Turn',
      reward: 1,
    ),
    EarnTask(
      icon: Icons.timer,
      title: 'Read 20 minute straight',
      subtitle: 'Once per session',
      reward: 30,
    ),
    EarnTask(
      icon: Icons.task_alt,
      title: 'Complete a Document',
      subtitle: 'Per document',
      reward: 50,
    ),
    EarnTask(
      icon: Icons.bookmark_add_outlined,
      title: 'Add a bookmark',
      subtitle: 'Max 5/day',
      reward: 3,
    ),
    EarnTask(
      icon: Icons.play_circle_outline,
      title: 'Advertisement',
      subtitle: 'Per ad view',
      reward: 5,
    ),
  ];

  // --- Profile Mock Data ---
  static List<Achievement> achievements = [
    Achievement(title: 'First PDF opened', reward: 20, isUnlocked: true),
    Achievement(title: 'First bookmark', reward: 10, isUnlocked: true),
    Achievement(title: 'Read 5 PDFs', reward: 50, isUnlocked: false),
    Achievement(title: 'Read 10 PDFs', reward: 100, isUnlocked: false),
    Achievement(title: '100 pages read', reward: 50, isUnlocked: false),
    Achievement(title: '500 pages read', reward: 150, isUnlocked: false),
  ];

  // --- Store Data ---
  static List<ShopItem> shopItems = [
    ShopItem(
      id: 'area_screenshot_5',
      name: 'Area Screenshots (5 uses)',
      cost: 15,
      tier: 'Tier 1',
      isPermanent: false,
    ),
    ShopItem(
      id: 'custom_highlight',
      name: 'Custom highlight colors',
      cost: 20,
      tier: 'Tier 1',
    ),
    ShopItem(
      id: 'sticky_notes',
      name: 'Sticky notes',
      cost: 25,
      tier: 'Tier 1',
    ),
    ShopItem(
      id: 'dark_theme',
      name: 'Dark / Sepia themes',
      cost: 30,
      tier: 'Tier 1',
    ),
    ShopItem(
      id: 'area_screenshot_month',
      name: 'Area Screenshot (Monthly)',
      cost: 50,
      tier: 'Tier 2',
      isPermanent: false,
    ),
    ShopItem(
      id: 'freehand_drawing',
      name: 'Freehand drawing',
      cost: 70,
      tier: 'Tier 2',
    ),
    ShopItem(
      id: 'page_reordering',
      name: 'Page reordering',
      cost: 75,
      tier: 'Tier 2',
    ),
    ShopItem(
      id: 'export_annotations',
      name: 'Export Annotations',
      cost: 80,
      tier: 'Tier 2',
    ),
    ShopItem(
      id: 'fill_sign_forms',
      name: 'Fill and Sign Forms',
      cost: 150,
      tier: 'Tier 3',
    ),
    ShopItem(
      id: 'digital_signature',
      name: 'Digital Signature pad',
      cost: 150,
      tier: 'Tier 3',
    ),
    ShopItem(id: 'split_pdf', name: 'Split Pdf', cost: 120, tier: 'Tier 3'),
    ShopItem(id: 'merge_pdf', name: 'Merge pdfs', cost: 120, tier: 'Tier 3'),
    ShopItem(
      id: 'read_aloud_tts',
      name: 'Read Aloud / TTS',
      cost: 140,
      tier: 'Tier 3',
    ),
    ShopItem(
      id: 'pdf_compression',
      name: 'Pdf Compression',
      cost: 200,
      tier: 'Tier 4',
    ),
    ShopItem(
      id: 'reflow_ebook',
      name: 'Reflow / Ebook mode',
      cost: 220,
      tier: 'Tier 4',
    ),
    ShopItem(
      id: 'password_protect',
      name: 'Password protect pdf',
      cost: 200,
      tier: 'Tier 4',
    ),
    ShopItem(
      id: 'multi_tab_viewer',
      name: 'Multi Tab viewer',
      cost: 300,
      tier: 'Tier 4',
    ),
    ShopItem(
      id: 'full_annotation_suite',
      name: 'Full Annotation Suite',
      cost: 350,
      tier: 'Tier 4',
    ),
  ];

  // --- Tools Mock Data ---
  static const List<ToolModel> allTools = [
    // Top 6 primary / free / starter tools matching design
    ToolModel(
      id: 'highlight',
      name: 'Highlight',
      icon: Icons.edit_outlined,
      isFree: true,
    ),
    ToolModel(
      id: 'note',
      name: 'Note',
      icon: Icons.chat_bubble_outline_rounded,
      isFree: true,
    ),
    ToolModel(
      id: 'area_screenshot',
      name: 'Area screenshot',
      icon: Icons.crop_rounded,
      shopItemId: 'area_screenshot_5',
    ),
    ToolModel(
      id: 'scan_pdf',
      name: 'Scan to PDF',
      icon: Icons.document_scanner_outlined,
      shopItemId: 'scan_pdf',
    ),
    ToolModel(
      id: 'bookmark',
      name: 'Bookmark',
      icon: Icons.bookmark_border_rounded,
      isFree: true,
    ),
    ToolModel(
      id: 'dark_theme',
      name: 'Dark / sepia theme',
      icon: Icons.contrast_rounded,
      shopItemId: 'dark_theme',
    ),

    // Additional tools available in store
    ToolModel(
      id: 'merge_pdf',
      name: 'Merge PDFs',
      icon: Icons.merge_type_rounded,
      shopItemId: 'merge_pdf',
    ),
    ToolModel(
      id: 'split_pdf',
      name: 'Split PDF',
      icon: Icons.call_split_rounded,
      shopItemId: 'split_pdf',
    ),
    ToolModel(
      id: 'fill_sign_forms',
      name: 'Fill and Sign Forms',
      icon: Icons.edit_note_rounded,
      shopItemId: 'fill_sign_forms',
    ),
    ToolModel(
      id: 'digital_signature',
      name: 'Digital Signature pad',
      icon: Icons.draw_rounded,
      shopItemId: 'digital_signature',
    ),
    ToolModel(
      id: 'read_aloud_tts',
      name: 'Read Aloud / TTS',
      icon: Icons.volume_up_rounded,
      shopItemId: 'read_aloud_tts',
    ),
    ToolModel(
      id: 'pdf_compression',
      name: 'PDF Compression',
      icon: Icons.compress_rounded,
      shopItemId: 'pdf_compression',
    ),
    ToolModel(
      id: 'custom_highlight',
      name: 'Custom highlight colors',
      icon: Icons.color_lens_outlined,
      shopItemId: 'custom_highlight',
    ),
    ToolModel(
      id: 'sticky_notes',
      name: 'Sticky notes',
      icon: Icons.sticky_note_2_outlined,
      shopItemId: 'sticky_notes',
    ),
    ToolModel(
      id: 'auto_scroll',
      name: 'Auto scroll',
      icon: Icons.play_arrow_outlined,
      isFree: true,
    ),
    ToolModel(
      id: 'freehand_drawing',
      name: 'Freehand drawing',
      icon: Icons.brush_outlined,
      shopItemId: 'freehand_drawing',
    ),
    ToolModel(
      id: 'page_reordering',
      name: 'Page reordering',
      icon: Icons.reorder_rounded,
      shopItemId: 'page_reordering',
    ),
    ToolModel(
      id: 'export_annotations',
      name: 'Export Annotations',
      icon: Icons.upload_outlined,
      shopItemId: 'export_annotations',
    ),
    ToolModel(
      id: 'reflow_ebook',
      name: 'Reflow / Ebook mode',
      icon: Icons.menu_book_rounded,
      shopItemId: 'reflow_ebook',
    ),
    ToolModel(
      id: 'password_protect',
      name: 'Password protect pdf',
      icon: Icons.lock_outline,
      shopItemId: 'password_protect',
    ),
    ToolModel(
      id: 'multi_tab_viewer',
      name: 'Multi Tab viewer',
      icon: Icons.tab_outlined,
      shopItemId: 'multi_tab_viewer',
    ),
    ToolModel(
      id: 'full_annotation_suite',
      name: 'Full Annotation Suite',
      icon: Icons.workspace_premium_rounded,
      shopItemId: 'full_annotation_suite',
    ),
  ];
}
