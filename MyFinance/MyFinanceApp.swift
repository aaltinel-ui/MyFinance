//
//  MyFinanceApp.swift
//  MyFinance
//
//  Created by ALPAY's MacBook on 15.03.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct MyFinanceApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Transaction.self,
            Dividend.self,
            Debt.self,
            DebtPayment.self,
            ExchangeRate.self,
            ChildExpense.self,
            FitreZekat.self,
            BESHesap.self
        ])
    }
}
