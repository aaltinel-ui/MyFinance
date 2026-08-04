import SwiftUI

struct GoldCatalogView: View {
    private let defaultGold = ["Gram Altın", "Çeyrek Altın", "Yarım Altın", "Cumhuriyet Altın", "24 Ayar Gram Altın"]
    @State private var goldCatalog: [String] = UserDefaults.standard.stringArray(forKey: "goldKey") ?? []
    @State private var newGold = ""
    @State private var goldToDelete: String?
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            Section("Varsayılan Altın Türleri") {
                ForEach(defaultGold, id: \.self) { item in
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(item)
                    }
                }
            }

            Section {
                // Not: Mac Catalyst'te aynı HStack içinde esnek genişleyen bir
                // eleman (TextField) varsa, sağındaki Button'ın hit-test alanı
                // bozuluyor ve tıklamalar aksiyonu tetiklemiyor. Bu yüzden
                // TextField ile butonu ayrı satırlarda tutuyoruz.
                TextField("Özel altın türü ekle", text: $newGold)
                    .onSubmit { addGold() }

                Button("Ekle") {
                    addGold()
                }
                .disabled(newGold.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !goldCatalog.isEmpty {
                Section("Eklenen Altınlar") {
                    ForEach(goldCatalog, id: \.self) { item in
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                            Text(item)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                goldToDelete = item
                                showDeleteAlert = true
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Altın Kataloğu")
        .alert("Altın Türünü Sil", isPresented: $showDeleteAlert, presenting: goldToDelete) { item in
            Button("Sil", role: .destructive) {
                goldCatalog.removeAll { $0 == item }
                save()
            }
            Button("İptal", role: .cancel) {}
        } message: { item in
            Text("\(item) öğesini katalogdan silmek istiyor musunuz?")
        }
    }

    private func addGold() {
        let name = newGold.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !defaultGold.contains(name), !goldCatalog.contains(name) else { return }
        goldCatalog.append(name)
        newGold = ""
        save()
    }

    private func save() {
        UserDefaults.standard.set(goldCatalog, forKey: "goldKey")
    }
}
