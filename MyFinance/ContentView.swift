//
//  ContentView.swift
//  MyFinance
//
//  Created by ALPAY's MacBook on 15.03.2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("selectedAppMode") private var selectedMode: String = AppMode.myFinans.rawValue
    @AppStorage("hideBalances") private var hideBalances = false
    @Environment(\.modelContext) private var context

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
            switch currentMode {
            case .myFinans:    myFinansTabView
            case .borcTakibi:  borcTakibiTabView
            case .cocuklarim:  cocuklarimTabView
            case .fitreZekat:  fitreZekatTabView
            case .bes:         besTabView
            }
        }
        .applyAppFont()
        .applyTheme()
        .task { seedBESHesaplari() }
    }

    private var modePicker: some View {
        HStack(spacing: 8) {
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

            Button {
                withAnimation { hideBalances.toggle() }
            } label: {
                Image(systemName: hideBalances ? "eye.slash.fill" : "eye.fill")
                    .font(.title3)
                    .foregroundStyle(hideBalances ? .red : .secondary)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
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

    // MARK: - BES Tabs

    private var besTabView: some View {
        TabView {
            NavigationStack {
                BESListView()
                    .navigationTitle("BES Hesaplarım")
            }
            .tabItem {
                Label("Hesaplarım", systemImage: "building.columns.fill")
            }

            NavigationStack {
                BESReportView()
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

// MARK: - BES Seed

extension ContentView {
    private func seedBESHesaplari() {
        guard !UserDefaults.standard.bool(forKey: "besSeedDone") else { return }
        let existing = (try? context.fetch(FetchDescriptor<BESHesap>())) ?? []
        guard existing.isEmpty else {
            UserDefaults.standard.set(true, forKey: "besSeedDone")
            return
        }

        let hesaplar: [(hesapNo: String, planAdi: String, katilimci: String, birikim: Double, notlar: String)] = [
            ("55613762", "Gruba Bağlı Bireysel Emeklilik Planı", "Alpay Altinel", 53444, "Kendim"),
            ("55167065", "Bireysel Emeklilik Planı",              "Alpay Altinel", 83485, "Kendim"),
            ("55167069", "Bireysel Emeklilik Planı",              "Alpay Altinel", 65828, "Kendim"),
            ("54335449", "İşveren Grup Emeklilik Planı",          "Alpay Altinel", 91720, "İşim"),
            ("54105548", "Bireysel Emeklilik Planı",              "Alpay Altinel", 438002, "Kendim"),
            ("47043422", "İşveren Grup Emeklilik Planı",          "Alpay Altinel", 1197241, "İşim"),
            ("55403319", "Bireysel Emeklilik Planı",              "Nazlı İrem Altinel", 111081, "Ailem - Nazlı İrem"),
            ("55310718", "Bireysel Emeklilik Planı",              "Nazlı İrem Altinel", 113239, "Ailem - Nazlı İrem"),
        ]

        for h in hesaplar {
            context.insert(BESHesap(
                sirketAdi: "Allianz Yaşam",
                planAdi: h.planAdi,
                hesapNo: h.hesapNo,
                baslangicTarihi: Date(),
                birikimTutari: h.birikim,
                devletKatkisi: 0,
                sirketKatkisi: 0,
                fonDegeri: 0,
                notlar: "\(h.katilimci) — \(h.notlar)"
            ))
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: "besSeedDone")
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
                    DividendListView()
                } label: {
                    Label("Temettü Listesi", systemImage: "list.bullet.rectangle")
                        .foregroundStyle(.green)
                }

                NavigationLink {
                    DividendReportView()
                } label: {
                    Label("Temettü Raporu", systemImage: "chart.bar.fill")
                        .foregroundStyle(.green)
                }

                NavigationLink {
                    PortfolioChartView()
                } label: {
                    Label("Portföy Grafikleri", systemImage: "chart.xyaxis.line")
                        .foregroundStyle(.blue)
                }

                NavigationLink {
                    SaklamaYeriReportView()
                } label: {
                    Label("Saklama Yeri Raporu", systemImage: "building.columns")
                        .foregroundStyle(.purple)
                }

                NavigationLink {
                    NavigationStack { BESListView().navigationTitle("BES Hesapları") }
                } label: {
                    Label("BES Hesapları", systemImage: "building.columns.fill")
                        .foregroundStyle(.indigo)
                }

                NavigationLink {
                    BESReportView()
                } label: {
                    Label("BES Raporu", systemImage: "chart.pie.fill")
                        .foregroundStyle(.indigo)
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
