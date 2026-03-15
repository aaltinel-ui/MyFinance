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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Transaction.self,
            Dividend.self,
            Debt.self,
            ExchangeRate.self
        ])
    }
}
