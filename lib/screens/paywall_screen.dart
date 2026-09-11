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
    // el % real de acierto es el argumento de venta — mejor que cualquier
    // texto de marketing, porque nadie más lo mide así (ver Historial).
    if (context.read<AppState>().accuracy == null) {
      context.read<AppState>().loadAccuracy();
    }
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
              if (state.accuracy != null && state.accuracy!.overallTotal > 0) ...[
                _AccuracyProof(pct: state.accuracy!.overallPct, total: state.accuracy!.overallTotal),
                const SizedBox(height: 18),
              ],
              const _ComparisonTable(),
              const SizedBox(height: 20),
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

/// El % de acierto real (el mismo que ves en Historial, nunca inflado) —
/// mejor argumento de venta que cualquier texto de marketing, porque es
/// verificable dentro de la misma app.
class _AccuracyProof extends StatelessWidget {
  final int pct;
  final int total;
  const _AccuracyProof({required this.pct, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Text('$pct%', style: AppText.style(34, weight: FontWeight.w800, color: AppColors.green)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acierto real medido', style: AppText.style(13, weight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 3),
                Text(
                  'Sobre $total picks calificados — no un número de marketing, es el mismo que ves en tu Historial.',
                  style: AppText.style(11, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Free vs Premium lado a lado — reduce fricción de decisión mejor que la
/// lista de checks repetida en cada card.
class _ComparisonTable extends StatelessWidget {
  const _ComparisonTable();

  static const _rows = [
    ('Partidos por día', '2', 'Ilimitados'),
    ('Mercados por partido', 'Solo 1X2', 'Todos'),
    ('Marcador probable + %', '—', '✓'),
    ('Chat IA', '5 mensajes/día', 'Ilimitado'),
    ('Notificaciones de gol/alineación', '—', '✓'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget headerCell(String text, {Color? color}) => Expanded(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.style(11.5, weight: FontWeight.w700, color: color ?? AppColors.textMuted),
          ),
        );

    Widget cell(String text, {bool isCheck = false}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: isCheck
                ? Icon(
                    text == '✓' ? Icons.check_rounded : Icons.remove_rounded,
                    size: 16,
                    color: text == '✓' ? AppColors.green : AppColors.textFaint,
                  )
                : Text(
                    text,
                    textAlign: TextAlign.center,
                    style: AppText.style(11.5, weight: FontWeight.w600, color: text == '—' ? AppColors.textFaint : Colors.white),
                  ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Expanded(flex: 2, child: SizedBox.shrink()),
                headerCell('FREE'),
                headerCell('PREMIUM', color: AppColors.green),
              ],
            ),
          ),
          for (var i = 0; i < _rows.length; i++) ...[
            if (i > 0) const Divider(color: AppColors.cardBorder, height: 1),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(_rows[i].$1, style: AppText.style(11.5, color: AppColors.textBody)),
                ),
                cell(_rows[i].$2, isCheck: _rows[i].$2 == '—'),
                cell(_rows[i].$3, isCheck: _rows[i].$3 == '✓'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
