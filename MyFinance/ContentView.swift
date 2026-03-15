//
//  ContentView.swift
//  MyFinance
//
//  Created by ALPAY's MacBook on 15.03.2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.pie")
                }

            TransactionListView()
                .tabItem {
                    Label("Hareketler", systemImage: "list.bullet.rectangle")
                }

            ProfitLossView()
                .tabItem {
                    Label("K/Z", systemImage: "chart.line.uptrend.xyaxis")
                }

            ReportsTabView()
                .tabItem {
                    Label("Raporlar", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
        }
    }
}

struct ReportsTabView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    GoldDetailView()
                } label: {
                    Label("Altın Varlıklarım", systemImage: "circle.fill")
                        .foregroundStyle(.yellow)
                }

                NavigationLink {
                    DividendReportView()
                } label: {
                    Label("Temettü Gelirleri", systemImage: "chart.bar.fill")
                        .foregroundStyle(.green)
                }

                NavigationLink {
                    DebtView()
                } label: {
                    Label("Borç Takibi", systemImage: "arrow.left.arrow.right")
                        .foregroundStyle(.red)
                }

                NavigationLink {
                    PortfolioChartView()
                } label: {
                    Label("Portföy Grafikleri", systemImage: "chart.xyaxis.line")
                        .foregroundStyle(.blue)
                }
            }
            .navigationTitle("Raporlar")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Transaction.self,
            Dividend.self,
            Debt.self,
            ExchangeRate.self
        ], inMemory: true)
}
