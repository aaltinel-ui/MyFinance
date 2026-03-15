import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("collectAPIKey") private var apiKey = ""
    @Environment(\.modelContext) private var context
    @State private var showingImportAlert = false
    @State private var importStatus = ""
    @State private var isImporting = false

    var body: some View {
        NavigationStack {
            Form {
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
                            Text("Excel'den Veri Aktar")
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
        }
    }

    private func importData() {
        isImporting = true
        importStatus = "Aktarılıyor..."

        Task {
            do {
                let importer = ExcelImportService(context: context)
                let result = try await importer.importAll()
                await MainActor.run {
                    importStatus = result
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importStatus = "Hata: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
}
