import NGPremium
import SubscriptionAnalytics

@available(iOS 13.0, *)
extension SubscriptionAnalytics.SubscriptionService: NGPremium.SubscriptionService {
    public func getSubscription(productId: String) async -> NGPremium.Subscription? {
        if let subscription = self.subscription(for: productId) {
            return NGPremium.Subscription(
                productId: subscription.identifier,
                displayPrice: subscription.price
            )
        } else {
            return nil
        }
    }
    
    public func purchaseProduct(productId: String) async -> NGPremium.PurchaseResult {
        return await withCheckedContinuation { continuation in
            purchaseProduct(productID: productId) { success, errorDesc in
                let result: NGPremium.PurchaseResult
                if success {
                    result = .success
                } else {
                    result = .error(errorDesc ?? "")
                }
                continuation.resume(with: .success(result))
            }
        }
    }
    
    public func restorePurchase() async -> NGPremium.PurchaseResult {
        return await withCheckedContinuation { continuation in
            restorePurchase { success, errorDesc in
                let result: NGPremium.PurchaseResult
                if success {
                    result = .success
                } else {
                    result = .error(errorDesc ?? "")
                }
                continuation.resume(with: .success(result))
            }
        }
    }
}
