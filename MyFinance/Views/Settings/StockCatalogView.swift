import SwiftUI

struct StockCatalogView: View {
    @AppStorage("collectAPIKey") private var apiKey = ""
    @State private var stockCatalog: [String] = UserDefaults.standard.stringArray(forKey: "stockKey") ?? ["KCHOL", "TUPRS", "THYAO", "ALFAS", "ARCLK", "AKBNK"]
    @State private var newStock = ""
    @State private var stockToDelete: String?
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            if apiKey.trimmingCharacters(in: .whitespaces).isEmpty {
                Section {
                    Label("Canlı fiyat güncellemesi için Ayarlar'dan CollectAPI anahtarınızı girmeniz gerekiyor. Anahtar girilmeden hisseler eski fiyatlarında kalır.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section {
                // Not: Mac Catalyst'te aynı HStack içinde esnek genişleyen bir
                // eleman (TextField) varsa, sağındaki Button'ın hit-test alanı
                // bozuluyor ve tıklamalar aksiyonu tetiklemiyor. Bu yüzden
                // TextField ile butonu ayrı satırlarda tutuyoruz.
                TextField("Hisse kodu (ör: FROTO)", text: $newStock)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .onSubmit { addStock() }

                Button("Ekle") {
                    addStock()
                }
                .disabled(newStock.trimmingCharacters(in: .whitespaces).isEmpty)
            } footer: {
                Text("BIST hisse kodunu girin. Buraya eklenen hisseler Dashboard'daki \"Güncelle\" ile canlı fiyat alır ve hareket eklerken hızlı seçim listesinde görünür.")
                    .font(.caption)
            }

            Section("Eklenen Hisseler") {
                ForEach(stockCatalog, id: \.self) { stock in
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.blue)
                        Text(stock)
                        Spacer()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            stockToDelete = stock
                            showDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Hisse Senedi Kataloğu")
        .alert("Hisseyi Sil", isPresented: $showDeleteAlert, presenting: stockToDelete) { stock in
            Button("Sil", role: .destructive) {
                stockCatalog.removeAll { $0 == stock }
                save()
            }
            Button("İptal", role: .cancel) {}
        } message: { stock in
            Text("\(stock) hissesini katalogdan silmek istiyor musunuz?")
        }
    }

    private func addStock() {
        let code = newStock.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty, !stockCatalog.contains(code) else { return }
        stockCatalog.append(code)
        newStock = ""
        save()
    }

    private func save() {
        UserDefaults.standard.set(stockCatalog, forKey: "stockKey")
    }
}
