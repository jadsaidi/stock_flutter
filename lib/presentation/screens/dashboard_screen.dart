import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/quantum_background.dart';
import 'products_tab.dart';
import 'movements_tab.dart';
import 'stats_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const StatsTab(),
    const ProductsTab(),
    const MovementsTab(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.inventory_2_rounded, label: 'Produits'),
    _NavItem(icon: Icons.swap_horiz_rounded, label: 'Mouvements'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.quantumGradient.createShader(bounds),
          child: const Text(
            'VIP CODING STOCK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.neonPink.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neonPink.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: AppColors.neonPink, size: 20),
              onPressed: () => ref.read(authServiceProvider).signOut(),
            ),
          )
        ],
      ),
      body: QuantumBackground(
        child: SafeArea(
          child: _tabs[_currentIndex],
        ),
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPurple.withOpacity(0.15),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _currentIndex == index;

          return GestureDetector(
            onTap: () => setState(() => _currentIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 20 : 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: isSelected ? AppColors.quantumGradient : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.neonPurple.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    size: 22,
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
