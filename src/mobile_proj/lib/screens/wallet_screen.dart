import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../widgets/app_button.dart';
import '../widgets/app_feedback.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  Future<Map<String, dynamic>>? walletFuture;
  static const double pointsToNisRate = 0.2;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    walletFuture = loadWallet();
  }

  void refreshWallet() {
    setState(() {
      walletFuture = loadWallet();
    });
  }

  @override
  void didUpdateWidget(WalletScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    refreshWallet();
  }

  Future<Map<String, dynamic>> loadWallet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerId = prefs.getInt('user_id') ?? 0;

      if (customerId == 0) {
        return {'balance': 0.0, 'points': 0};
      }

      final response = await http.post(
        Uri.parse(ApiConfig.getWalletUrl),
        body: {'customer_id': customerId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
          final points = (data['points'] as num?)?.toInt() ?? 0;
          return {'balance': balance, 'points': points};
        }
      }
    } catch (_) {
      // The wallet UI falls back to zero values and keeps pull-to-refresh.
    }
    return {'balance': 0.0, 'points': 0};
  }

  Future<bool> convertPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getInt('user_id') ?? 0;

    if (customerId == 0) {
      return false;
    }

    final response = await http.post(
      Uri.parse(ApiConfig.convertPointsUrl),
      body: {'customer_id': customerId.toString()},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          walletFuture = loadWallet();
        });
        return true;
      }
    }
    return false;
  }

  Future<void> _handleConvertPoints() async {
    if (_isConverting) return;
    setState(() => _isConverting = true);

    try {
      final success = await convertPoints();
      if (!mounted) return;

      showAppSnackBar(
        context,
        message: success
            ? 'Points converted to wallet balance.'
            : 'Could not convert points. Please try again.',
        isError: !success,
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Could not convert points. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: RefreshIndicator(
        onRefresh: () {
          setState(() {
            walletFuture = loadWallet();
          });
          return walletFuture!;
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: walletFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final balance = (snapshot.data?['balance'] as num?) ?? 0.0;
            final points = (snapshot.data?['points'] as num?)?.toInt() ?? 0;
            final pointsValue = points * pointsToNisRate;

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _WalletSummaryCard(
                  title: 'Wallet balance',
                  value: '${balance.toDouble().toStringAsFixed(2)} ₪',
                  icon: Icons.account_balance_wallet_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                _WalletSummaryCard(
                  title: 'Reward points',
                  value: '$points',
                  subtitle: '${pointsValue.toStringAsFixed(2)} ₪ available',
                  icon: Icons.stars_outlined,
                  color: colorScheme.secondary,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: points > 0
                      ? 'Convert points to balance'
                      : 'No points to convert',
                  icon: Icons.swap_horiz,
                  isLoading: _isConverting,
                  onPressed: points > 0 ? _handleConvertPoints : null,
                  variant: AppButtonVariant.secondary,
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'How points work',
                              style: textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Each 15 NIS you pay earns 1 point. Every 5 points can be converted into 1 ₪ in wallet balance.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WalletSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _WalletSummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: textTheme.headlineSmall?.copyWith(color: color),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
