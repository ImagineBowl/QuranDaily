//
//  TipJarService.swift
//  QuranDaily
//
//  Created by Ahsan Minhas on 30/05/2026.
//

import StoreKit

protocol TipJarServiceProtocol: Sendable {
    func loadProducts() async throws -> [Product]
    func purchase(_ product: Product) async throws -> Bool
}

final class TipJarService: TipJarServiceProtocol, @unchecked Sendable {
    private let productIDs = [
        "com.Imaginebowl.QuranDaily.tip.small",
        "com.Imaginebowl.QuranDaily.tip.medium",
        "com.Imaginebowl.QuranDaily.tip.large"
    ]

    private let updatesTask: Task<Void, Never>

    init() {
        // Listen for transactions that complete outside of an active `purchase()`
        // call (Ask to Buy approvals, interrupted/deferred purchases, etc.) so no
        // successful tip is missed and left unfinished in the queue.
        updatesTask = Task {
            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else { continue }
                await transaction.finish()
            }
        }
    }

    deinit {
        updatesTask.cancel()
    }

    func loadProducts() async throws -> [Product] {
        try await Product.products(for: productIDs)
            .sorted { $0.price < $1.price }
    }

    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            // Consumable tip: finish the transaction immediately. No entitlement
            // is stored and no feature is unlocked.
            guard case .verified(let transaction) = verification else {
                return false
            }
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }
}
