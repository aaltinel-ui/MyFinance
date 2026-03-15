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
                }

                Section("API Ayarları") {
                    SecureField("CollectAPI Key", text: $apiKey)
                    Text("Hisse ve döviz fiyatları için collectapi.com API anahtarınızı girin.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
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
}
