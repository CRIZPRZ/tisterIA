import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'retry.dart';

class IapVerifyResult {
  final String plan;
  final bool isActive;
  const IapVerifyResult({required this.plan, required this.isActive});

  factory IapVerifyResult.fromJson(Map<String, dynamic> json) => IapVerifyResult(
        plan: json['plan'] as String,
        isActive: json['isActive'] as bool,
      );
}

/// product id en Play Console -> id de plan interno de la app
const Map<String, String> kProductToPlan = {
  'premium_monthly': 'premium',
  'pro_monthly': 'pro',
};

class IapService {
  IapService._internal();
  static final IapService instance = IapService._internal();

  static const Set<String> _productIds = {'premium_monthly', 'pro_monthly'};

  final InAppPurchase _iap = InAppPurchase.instance;
  final Dio _dio = apiClient;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  /// Callbacks que AppState conecta para reaccionar a compras/errores.
  void Function(String plan)? onPlanUpdated;
  void Function(String message)? onError;

  Future<List<ProductDetails>> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return [];
    final response = await _iap.queryProductDetails(_productIds);
    return response.productDetails;
  }

  void startListening() {
    _sub?.cancel();
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdate, onError: (_) {});
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> buy(ProductDetails product) async {
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }

  Future<void> restorePurchases() => _iap.restorePurchases();

  /// Re-verifica la última compra conocida contra Google Play (detecta
  /// cancelaciones/vencimientos sin necesitar webhooks). Se llama al abrir la app.
  Future<IapVerifyResult> fetchStatus() async {
    final res = await withRetry(
      () async => _dio.get('/iap/status', options: Options(headers: await AuthService.instance.authHeader())),
    );
    return IapVerifyResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) continue;

      if (purchase.status == PurchaseStatus.error) {
        onError?.call(purchase.error?.message ?? 'Error de compra');
        if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        if (Platform.isAndroid) {
          try {
            final res = await _dio.post(
              '/iap/verify-android',
              data: {
                'productId': purchase.productID,
                'purchaseToken': purchase.verificationData.serverVerificationData,
              },
              options: Options(headers: await AuthService.instance.authHeader()),
            );
            final result = IapVerifyResult.fromJson(res.data as Map<String, dynamic>);
            onPlanUpdated?.call(result.plan);
          } catch (_) {
            onError?.call('No pudimos verificar tu compra. Si ya se te cobró, contáctanos.');
          }
        } else {
          // iOS: todavía sin verificación real de StoreKit (pendiente cuenta de Apple Developer).
          onError?.call('Las compras en iOS no están disponibles todavía.');
        }
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }
}
