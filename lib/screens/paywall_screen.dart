import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/pick.dart';
import '../services/iap_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

const _kPlanToProductId = {'premium': 'premium_monthly', 'pro': 'pro_monthly'};

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Map<String, ProductDetails> _products = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final list = await IapService.instance.loadProducts();
    if (mounted) setState(() => _products = {for (final p in list) p.id: p});
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Elige tu plan', style: AppText.style(19, weight: FontWeight.w600)),
              GestureDetector(
                onTap: () {
                  context.read<AppState>().clearQuotaMessage();
                  context.read<AppState>().go(AppScreen.home);
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 16, color: AppColors.navMuted),
                ),
              ),
            ],
          ),
        ),
        if (state.quotaMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.greenTint, borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(state.quotaMessage!, style: AppText.style(11.5, color: AppColors.green))),
                      GestureDetector(
                        onTap: () => context.read<AppState>().clearQuotaMessage(),
                        child: const Icon(Icons.close_rounded, size: 16, color: AppColors.green),
                      ),
                    ],
                  ),
                  if (Platform.isAndroid && state.pendingPickId != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => context.read<AppState>().watchAdForBonusPick(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_outline_rounded, size: 16, color: Color(0xFF0B0F0C)),
                            const SizedBox(width: 6),
                            Text('Ver anuncio y ganar 1 pick', style: AppText.style(12.5, weight: FontWeight.w700, color: const Color(0xFF0B0F0C))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (state.iapError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.redTint, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(child: Text(state.iapError!, style: AppText.style(11.5, color: AppColors.red))),
                  GestureDetector(
                    onTap: () => context.read<AppState>().clearIapError(),
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.red),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
            children: [
              ...kPlans.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _PlanCard(
                      plan: p,
                      currentPlan: state.plan,
                      product: _products[_kPlanToProductId[p.id]],
                    ),
                  )),
              const SizedBox(height: 4),
              Text(
                'Cancela cuando quieras desde la configuración de suscripciones de Google Play.',
                textAlign: TextAlign.center,
                style: AppText.style(10.5, color: AppColors.textFaint, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final String currentPlan;
  final ProductDetails? product;
  const _PlanCard({required this.plan, required this.currentPlan, required this.product});

  @override
  Widget build(BuildContext context) {
    final isCurrent = plan.id == currentPlan;
    final accent = plan.id == 'premium'
        ? AppColors.green
        : plan.id == 'pro'
            ? AppColors.blue
            : AppColors.navMuted;
    final borderColor = plan.recommended ? AppColors.green : AppColors.cardBorder;
    final priceLabel = product?.price ?? plan.price;

    void onTap() {
      if (plan.id == 'free') {
        context.read<AppState>().selectPlan('free');
      } else if (product != null) {
        IapService.instance.buy(product!);
      } else {
        // Sin producto real disponible (ej. iOS, sin billing todavía) —
        // puente de desarrollo para poder seguir probando el flujo.
        context.read<AppState>().selectPlan(plan.id);
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(plan.name, style: AppText.style(15, weight: FontWeight.w700)),
                  Text(priceLabel, style: AppText.style(20, weight: FontWeight.w300)),
                ],
              ),
              const SizedBox(height: 4),
              Text(plan.period, style: AppText.style(11.5, color: AppColors.textMuted)),
              const SizedBox(height: 14),
              ...plan.features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_rounded, size: 15, color: accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(f, style: AppText.style(12.5, color: AppColors.textBody)),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: isCurrent ? null : onTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: plan.id == 'premium' ? AppColors.green : (isCurrent ? AppColors.cardBorder : Colors.transparent),
                    border: plan.id == 'premium' || isCurrent
                        ? null
                        : Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isCurrent
                        ? 'Plan actual'
                        : (plan.id == 'free' ? 'Continuar gratis' : 'Suscribirme'),
                    textAlign: TextAlign.center,
                    style: AppText.style(
                      13.5,
                      weight: FontWeight.w700,
                      color: plan.id == 'premium'
                          ? const Color(0xFF0A0A0B)
                          : (isCurrent ? AppColors.textMuted : Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (plan.recommended)
          Positioned(
            top: -9,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(5)),
              child: Text('MÁS POPULAR',
                  style: AppText.style(9.5, weight: FontWeight.w700, color: const Color(0xFF0A0A0B))),
            ),
          ),
      ],
    );
  }
}
