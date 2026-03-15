//
//  MyFinanceApp.swift
//  MyFinance
//
//  Created by ALPAY's MacBook on 15.03.2026.
//

import SwiftUI
import SwiftData

@main
struct MyFinanceApp: App {
    let container: ModelContainer

    init() {
        container = try! ModelContainer(for:
            Transaction.self,
            Dividend.self,
            Debt.self,
            DebtPayment.self,
            ExchangeRate.self,
            ChildExpense.self,
            FitreZekat.self
        )
        DataSeeder.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
