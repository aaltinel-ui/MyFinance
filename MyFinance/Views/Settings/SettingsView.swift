import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("collectAPIKey") private var apiKey = ""
    @AppStorage(AppSettingsKey.fontSize) private var fontSizeRaw = FontSizeOption.medium.rawValue
    @AppStorage(AppSettingsKey.theme) private var themeRaw = ThemeOption.system.rawValue
    @Environment(\.modelContext) private var context
    @State private var showingImportAlert = false
    @State private var showingChildImportAlert = false
    @State private var importStatus = ""
    @State private var isImporting = false

    // Firebase sync
    @AppStorage("lastSyncDate") private var lastSyncDateInterval: Double = 0
    @State private var isSyncing = false
    @State private var syncStatus = ""
    @State private var showingUploadAlert = false
    @State private var showingDownloadAlert = false

    // JSON export/import
    @State private var showingExportSheet = false
    @State private var showingImportPicker = false
    @State private var exportURL: URL?
    @State private var jsonStatus = ""

    private var lastSyncText: String {
        guard lastSyncDateInterval > 0 else { return "Hiç senkronize edilmedi" }
        let date = Date(timeIntervalSince1970: lastSyncDateInterval)
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        fmt.locale = Locale(identifier: "tr_TR")
        return "Son sync: \(fmt.string(from: date))"
    }

    private var selectedTheme: ThemeOption {
        ThemeOption(rawValue: themeRaw) ?? .system
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Görünüm") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yazı Boyutu")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("Yazı Boyutu", selection: $fontSizeRaw) {
                            ForEach(FontSizeOption.allCases) { option in
                                Text(option.rawValue).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tema")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("Tema", selection: $themeRaw) {
                            ForEach(ThemeOption.allCases) { option in
                                Text(option.rawValue).tag(option.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Preview card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Önizleme")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Portföy Değeri")
                                .font(.headline)
                            Text("₺125.430,50")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Günlük değişim: +₺1.250,00")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(selectedTheme.cardColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Section("Katalog Yönetimi") {
                    NavigationLink {
                        CatalogEditView()
                    } label: {
                        HStack {
                            Image(systemName: "folder.badge.gearshape")
                                .foregroundStyle(.blue)
                            Text("Kasa Tipleri & Birim Tipleri")
                        }
                    }
                    NavigationLink {
                        StockCatalogView()
                    } label: {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.blue)
                            Text("Hisse Senedi Kataloğu")
                        }
                    }
                    NavigationLink {
                        GoldCatalogView()
                    } label: {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text("Altın Kataloğu")
                        }
                    }
                    NavigationLink {
                        SilverCatalogView()
                    } label: {
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.gray)
                                .font(.caption)
                            Text("Gümüş Kataloğu")
                        }
                    }
                    NavigationLink {
                        CurrencyCatalogView()
                    } label: {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                                .foregroundStyle(.green)
                            Text("Döviz Kataloğu")
                        }
                    }
                    NavigationLink {
                        CoinCatalogView()
                    } label: {
                        HStack {
                            Image(systemName: "bitcoinsign.circle")
                                .foregroundStyle(.orange)
                            Text("Coin Kataloğu")
                        }
                    }
                    NavigationLink {
                        SaklamaYeriCatalogView()
                    } label: {
                        HStack {
                            Image(systemName: "building.columns")
                                .foregroundStyle(.purple)
                            Text("Saklama Yeri Kataloğu")
                        }
                    }
                    NavigationLink {
                        FonPriceEntryView()
                    } label: {
                        HStack {
                            Image(systemName: "chart.pie")
                                .foregroundStyle(.teal)
                            Text("Fon Birim Fiyatları")
                        }
                    }
                }

                Section("Gizlilik") {
                    NavigationLink {
                        PrivacySettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundStyle(.green)
                            Text("Gizlilik Ayarları")
                        }
                    }
                }

                Section("API Ayarları") {
                    SecureField("CollectAPI Key", text: $apiKey)
                    Text("Hisse ve döviz fiyatları için collectapi.com API anahtarınızı girin.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Bulut Senkronizasyon (Firebase)") {
                    Button {
                        showingUploadAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.up")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Buluta Yükle")
                                Text("Tüm verileri Firebase'e yükle")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(isSyncing)

                    Button {
                        showingDownloadAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "icloud.and.arrow.down")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Buluttan İndir")
                                Text("Firebase'den yeni kayıtları indir")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .disabled(isSyncing)

                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text(lastSyncText)
                            .font(.caption).foregroundStyle(.secondary)
                    }

                    if !syncStatus.isEmpty {
                        Text(syncStatus)
                            .font(.caption)
                            .foregroundStyle(syncStatus.contains("Hata") ? .red : .green)
                    }
                }

                Section("Veri Aktarımı (JSON Yedekleme)") {
                    Button {
                        exportJSON()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tüm Verileri Dışa Aktar")
                                Text("JSON dosyası olarak AirDrop veya iCloud ile paylaş")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    Button {
                        showingImportPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Verileri İçe Aktar")
                                Text("Başka cihazdan aktarılan JSON dosyasını yükle")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }

                    if !jsonStatus.isEmpty {
                        Text(jsonStatus)
                            .font(.caption)
                            .foregroundStyle(jsonStatus.contains("Hata") ? .red : .green)
                    }
                }

                Section("Veri Yönetimi") {
                    Button {
                        showingImportAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("MyFinans Excel'den Veri Aktar")
                        }
                    }
                    .disabled(isImporting)

                    Button {
                        showingChildImportAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "figure.2.and.child.holdinghands")
                            Text("Çocuk Harcamaları Excel'den Aktar")
                        }
                    }
                    .disabled(isImporting)

                    if !importStatus.isEmpty {
                        Text(importStatus)
                            .font(.caption)
                            .foregroundStyle(importStatus.contains("Hata") ? .red : .green)
                    }
                }

                Section("Hakkında") {
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text(BuildInfo.displayVersion)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Son Güncelleme")
                        Spacer()
                        Text(BuildInfo.buildDate)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Commit")
                        Spacer()
                        Text(BuildInfo.commitHash)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    HStack {
                        Text("Geliştirici")
                        Spacer()
                        Text("Alpay")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Ayarlar")
            .alert("Buluta Yükle", isPresented: $showingUploadAlert) {
                Button("İptal", role: .cancel) {}
                Button("Yükle") { uploadToFirebase() }
            } message: {
                Text("Tüm veriler Firebase'e yüklenecek. Mevcut bulut verileri güncellenecek.")
            }
            .alert("Buluttan İndir", isPresented: $showingDownloadAlert) {
                Button("İptal", role: .cancel) {}
                Button("İndir") { downloadFromFirebase() }
            } message: {
                Text("Firebase'den yeni kayıtlar indirilecek. Mevcut yerel veriler korunacak.")
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Excel'den Veri Aktar", isPresented: $showingImportAlert) {
                Button("İptal", role: .cancel) { }
                Button("Aktar") {
                    importData()
                }
            } message: {
                Text("MyFinans_2024.xlsx dosyasından tüm veriler aktarılacak. Mevcut veriler korunacak.")
            }
            .alert("Çocuk Harcamaları Aktar", isPresented: $showingChildImportAlert) {
                Button("İptal", role: .cancel) { }
                Button("Aktar") {
                    importChildData()
                }
            } message: {
                Text("Ataberk & Nazlı İrem harcama verileri Excel'den aktarılacak. Mevcut veriler korunacak.")
            }
        }
    }

    private func importData() {
        isImporting = true
        importStatus = "Aktarılıyor..."

        Task { @MainActor in
            do {
                let importer = ExcelImportService(context: context)
                let result = try await importer.importAll()
                importStatus = result
                isImporting = false
            } catch {
                importStatus = "Hata: \(error.localizedDescription)"
                isImporting = false
            }
        }
    }

    private func importChildData() {
        isImporting = true
        importStatus = "Çocuk harcamaları aktarılıyor..."

        Task { @MainActor in
            do {
                let importer = ExcelImportService(context: context)
                let count = try importer.importChildExpenses()
                try context.save()
                importStatus = "\(count) çocuk harcama kaydı aktarıldı"
                isImporting = false
            } catch {
                importStatus = "Hata: \(error.localizedDescription)"
                isImporting = false
            }
        }
    }

    private func uploadToFirebase() {
        isSyncing = true
        syncStatus = "Yükleniyor..."
        Task { @MainActor in
            FirestoreService.shared.uploadAll(context: context)
            lastSyncDateInterval = Date().timeIntervalSince1970
            syncStatus = "Yükleme tamamlandı"
            isSyncing = false
        }
    }

    private func downloadFromFirebase() {
        isSyncing = true
        syncStatus = "İndiriliyor..."
        Task { @MainActor in
            do {
                try await FirestoreService.shared.downloadAll(context: context)
                lastSyncDateInterval = Date().timeIntervalSince1970
                syncStatus = "İndirme tamamlandı"
            } catch {
                syncStatus = "Hata: \(error.localizedDescription)"
            }
            isSyncing = false
        }
    }

    private func exportJSON() {
        Task { @MainActor in
            do {
                let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
                let dividends = (try? context.fetch(FetchDescriptor<Dividend>())) ?? []
                let debts = (try? context.fetch(FetchDescriptor<Debt>())) ?? []
                let childExpenses = (try? context.fetch(FetchDescriptor<ChildExpense>())) ?? []

                var export: [String: Any] = [
                    "exportDate": ISO8601DateFormatter().string(from: Date()),
                    "transactionCount": transactions.count,
                    "dividendCount": dividends.count,
                    "debtCount": debts.count,
                    "childExpenseCount": childExpenses.count
                ]

                let txData = transactions.map { t -> [String: Any] in
                    ["id": t.id.uuidString, "tarih": ISO8601DateFormatter().string(from: t.tarih),
                     "kasaTip": t.kasaTip, "islem": t.islem, "tip": t.tip, "nerede": t.nerede,
                     "yon": t.yon, "birimFiyat": t.birimFiyat, "adet": t.adet, "tutarTL": t.tutarTL,
                     "notlar": t.notlar ?? ""]
                }
                export["transactions"] = txData

                let data = try JSONSerialization.data(withJSONObject: export, options: .prettyPrinted)
                let url = FileManager.default.temporaryDirectory.appendingPathComponent("MyFinance_yedek_\(Date().timeIntervalSince1970).json")
                try data.write(to: url)
                exportURL = url
                showingExportSheet = true
                jsonStatus = "Dışa aktarma hazır"
            } catch {
                jsonStatus = "Hata: \(error.localizedDescription)"
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
