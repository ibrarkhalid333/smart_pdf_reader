import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_pdf_reader/core/utils/size_utils.dart';
import 'package:smart_pdf_reader/presentation/base/controller/base_controller.dart';
import 'package:smart_pdf_reader/presentation/home/screens/home_screen.dart';
import 'package:smart_pdf_reader/presentation/profile/screens/profile_screen.dart';
import 'package:smart_pdf_reader/presentation/store/screens/store_screen.dart';
import 'package:smart_pdf_reader/presentation/tool/screens/tool_screen.dart';
import 'package:smart_pdf_reader/presentation/wallet/screens/wallet_screen.dart';
import 'package:smart_pdf_reader/theme/theme_helper.dart';

class BaseScreen extends GetWidget<BaseController> {
  const BaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabScreens = [
      HomeScreen(),
      ToolScreen(),
      StoreScreen(),
      WalletScreen(),
      ProfileScreen(),
    ];
    return Scaffold(
      body: Obx(() => tabScreens[controller.curruntIndex.value]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: controller.curruntIndex.value,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: appTheme.primaryColor,
        unselectedItemColor: appTheme.textSecondaryColor,
        onTap: controller.changeIndex,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 24.fSize),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined, size: 24.fSize),
            label: 'Tools',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined, size: 24.fSize),
            label: 'Store',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined, size: 24.fSize),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 24.fSize),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
