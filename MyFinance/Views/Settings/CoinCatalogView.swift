import SwiftUI

struct CoinCatalogView: View {
    let defaultCoins: [String] = ["BTC", "ETH"]
    @State private var coinCatalog: [String] = []
    @State private var newCoin: String = ""
    @State private var coinToDelete: String? = nil
    @State private var showDeleteAlert: Bool = false

    var body: some View {
        Form {
            SwiftUI.Section(header: Text("Varsayılan Coinler")) {
                ForEach(defaultCoins, id: \.self) { item in
                    HStack {
                        Image(systemName: "bitcoinsign.circle")
                            .foregroundStyle(.orange)
                        Text(item)
                    }
                }
            }
            SwiftUI.Section(footer: Text("Bitcoin ve Ethereum fiyatları CoinGecko API'den otomatik güncellenir.")) {
                // Not: Mac Catalyst'te aynı HStack içinde esnek genişleyen bir
                // eleman (TextField) varsa, sağındaki Button'ın hit-test alanı
                // bozuluyor ve tıklamalar aksiyonu tetiklemiyor. Bu yüzden
                // TextField ile butonu ayrı satırlarda tutuyoruz.
                TextField("Coin adı (ör: SOL)", text: $newCoin)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                    .onSubmit { addCoin() }

                Button("Ekle") {
                    addCoin()
                }
                .disabled(newCoin.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if !coinCatalog.isEmpty {
                SwiftUI.Section(header: Text("Eklenen Coinler")) {
                    ForEach(coinCatalog, id: \.self) { item in
                        HStack {
                            Image(systemName: "bitcoinsign.circle")
                                .foregroundStyle(.orange)
                            Text(item)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                coinToDelete = item
                                showDeleteAlert = true
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Coin Kataloğu")
        .onAppear {
            coinCatalog = UserDefaults.standard.stringArray(forKey: "coinKey") ?? []
        }
        .alert("Coini Sil", isPresented: $showDeleteAlert, presenting: coinToDelete) { item in
            Button("Sil", role: .destructive) {
                coinCatalog.removeAll { $0 == item }
                save()
            }
            Button("İptal", role: .cancel) {}
        } message: { item in
            Text("\(item) coin'i katalogdan silmek istiyor musunuz?")
        }
    }

    private func addCoin() {
        let code = newCoin.trimmingCharacters(in: .whitespaces).uppercased()
        guard !code.isEmpty, !defaultCoins.contains(code), !coinCatalog.contains(code) else { return }
        coinCatalog.append(code)
        newCoin = ""
        save()
    }

    private func save() {
        UserDefaults.standard.set(coinCatalog, forKey: "coinKey")
    }
}
