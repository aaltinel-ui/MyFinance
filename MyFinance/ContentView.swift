//
//  ContentView.swift
//  MyFinance
//
//  Created by ALPAY's MacBook on 15.03.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedAppMode") private var selectedMode: String = AppMode.myFinans.rawValue

    private var currentMode: AppMode {
        AppMode(rawValue: selectedMode) ?? .myFinans
    }

    var body: some View {
        VStack(spacing: 0) {
            // Mode Picker
            modePicker
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

            // Mode Content
            Group {
                switch currentMode {
                case .myFinans:
                    myFinansTabView
                case .borcTakibi:
                    borcTakibiTabView
                case .cocuklarim:
                    cocuklarimTabView
                case .fitreZekat:
                    fitreZekatTabView
                }
            }
        }
        .applyAppFont()
        .applyTheme()
        .task {
            DataSeeder.seedIfNeeded(context: modelContext)
        }
    }

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AppMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMode = mode.rawValue
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.subheadline)
                            Text(mode.rawValue)
                                .font(.subheadline)
                                .fontWeight(currentMode == mode ? .semibold : .regular)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(currentMode == mode ? mode.color : Color.secondary.opacity(0.12))
                        .foregroundStyle(currentMode == mode ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - MyFinans Tabs

    private var myFinansTabView: some View {
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

    // MARK: - Borç Takibi Tabs

    private var borcTakibiTabView: some View {
        TabView {
            NavigationStack {
                DebtView()
                    .navigationTitle("Borç Takibi")
            }
            .tabItem {
                Label("Borçlar", systemImage: "arrow.left.arrow.right.circle")
            }

            NavigationStack {
                DebtReportView()
            }
            .tabItem {
                Label("Raporlar", systemImage: "chart.pie")
            }

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
        }
    }

    // MARK: - Çocuklarım Tabs

    private var cocuklarimTabView: some View {
        TabView {
            NavigationStack {
                ChildExpenseListView()
                    .navigationTitle("Çocuk Harcamaları")
            }
            .tabItem {
                Label("Harcamalar", systemImage: "figure.2.and.child.holdinghands")
            }

            NavigationStack {
                ChildExpenseReportView()
            }
            .tabItem {
                Label("Raporlar", systemImage: "chart.pie")
            }

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
        }
    }

    // MARK: - Fitre/Zekât Tabs

    private var fitreZekatTabView: some View {
        TabView {
            NavigationStack {
                FitreZekatListView()
                    .navigationTitle("Fitre/Zekât")
            }
            .tabItem {
                Label("Kayıtlar", systemImage: "heart.circle")
            }

            NavigationStack {
                FitreZekatReportView()
            }
            .tabItem {
                Label("Raporlar", systemImage: "chart.pie")
            }

            SettingsView()
                .tabItem {
                    Label("Ayarlar", systemImage: "gear")
                }
        }
    }
}

// MARK: - MyFinans Reports Sub-View

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
            DebtPayment.self,
            ExchangeRate.self,
            ChildExpense.self,
            FitreZekat.self
        ], inMemory: true)
}
