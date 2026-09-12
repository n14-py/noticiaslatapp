// Archivo: noticias_lat/lib/core/services/billing_manager.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:noticias_lat/core/services/premium_manager.dart';

class BillingManager {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // IMPORTANTE: Este es el ID exacto que le pondremos a tu suscripción en Google Play Console
  static const String productIdSuscripcion = 'premium_mensual_199';

  static Future<void> init() async {
    final bool available = await _iap.isAvailable();
    if (!available) {
      debugPrint("Google Play Billing no está disponible en este dispositivo.");
      return;
    }

    // El "oído" que escucha cuando el banco de Google aprueba el pago
    _subscription = _iap.purchaseStream.listen((purchaseDetailsList) {
      _procesarCompras(purchaseDetailsList);
    }, onDone: () {
      _subscription?.cancel();
    }, onError: (error) {
      debugPrint("Error en el stream de compras: $error");
    });
  }

  static void _procesarCompras(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint("Compra pendiente de aprobación...");
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint("Error en la transacción: ${purchaseDetails.error}");
        } else if (purchaseDetails.status == PurchaseStatus.purchased || 
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          // ¡MAGIA! El pago fue exitoso. Le damos el Premium al usuario.
          debugPrint("¡Transacción aprobada! Activando Premium...");
          await PremiumManager.activarPremiumSuscripcion();
          
        }
        // Le avisamos a Google que ya entregamos el producto para que no devuelva el dinero
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  // Este es el método que llamará el botón de tu perfil más adelante
  static Future<void> comprarPremiumMensual() async {
    final ProductDetailsResponse response = await _iap.queryProductDetails({productIdSuscripcion});
    
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      debugPrint("El producto no existe aún en Google Play.");
      return;
    }
    
    final ProductDetails productDetails = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    // Inicia la pasarela de pago nativa de Google
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static void dispose() {
    _subscription?.cancel();
  }
}