import SwiftUI

struct CurrencyCatalogView: View {
    private let defaultCurrencies = ["USD", "EUR"]
    @State private var currencyCatalog: [String] = UserDefaults.standard.stringArray(forKey: "currencyKey") ?? []
    @State private var newCurrency = ""
    @State private var currencyToDelete: String?
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            Section("Varsayılan Dövizler") {
                ForEach(defaultCurrencies, id: \.self) { item in
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundStyle(.green)
                        Text(item)
                        Spacer()
                        Text("USD ve EUR fiyatları CollectAPI'den otomatik gelir")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Section {
                // Not: Mac Catalyst'te aynı HStack içinde esnek genişleyen bir
                // eleman (TextField) varsa, sağındaki Button'ın hit-test alanı
                // bozuluyor ve tıklamalar aksiyonu tetiklemiyor. Bu yüzden
                // TextField ile butonu ayrı satırlarda tutuyoruz.
                TextField("Döviz kodu (ör: GBP)", text: $newCurrency)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                    .onSubmit { addCurrency() }

                Button("Ekle") {
                    addCurrency()
                }
                .disabled(newCurrency.trimmingCharacters(in: .whitespaces).isEmpty)
            } footer: {
                Text("CollectAPI'den desteklenen döviz kodlarını girebilirsiniz.")
                    .font(.caption)
            }

            if !currencyCatalog.isEmpty {
                Section("Eklenen Dövizler") {
                    ForEach(currencyCatalog, id: \.self) { item in
                        HStack {
                            Image(systemName: "dollarsign.circle")
                                .foregroundStyle(.green)
                            Text(item)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                currencyToDelete = item
                                showDeleteAlert = true
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Döviz Kataloğu")
        .alert("Dövizi Sil", isPresented: $showDeleteAlert, presenting: currencyToDelete) { item in
            Button("Sil", role: .destructive) {
                currencyCatalog.removeAll { $0 == item }
                save()
            }
            Button("İptal", role: .cancel) {}
        } message: { item in
            Text("\(item) öğesini katalogdan silmek istiyor musunuz?")
        }
    }

    private func addCurrency() {
        let code = newCurrency.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty, !defaultCurrencies.contains(code), !currencyCatalog.contains(code) else { return }
        currencyCatalog.append(code)
        newCurrency = ""
        save()
    }

    private func save() {
        UserDefaults.standard.set(currencyCatalog, forKey: "currencyKey")
    }
}
