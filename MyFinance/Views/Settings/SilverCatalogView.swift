import SwiftUI

struct SilverCatalogView: View {
    private let defaultSilver = ["Gram Gümüş"]
    @State private var silverCatalog: [String] = UserDefaults.standard.stringArray(forKey: "silverKey") ?? []
    @State private var newSilver = ""
    @State private var silverToDelete: String?
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            Section("Varsayılan Gümüş Türleri") {
                ForEach(defaultSilver, id: \.self) { item in
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.gray)
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
                TextField("Özel gümüş türü ekle", text: $newSilver)
                    .onSubmit { addSilver() }

                Button("Ekle") {
                    addSilver()
                }
                .disabled(newSilver.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if !silverCatalog.isEmpty {
                Section("Eklenen Gümüşler") {
                    ForEach(silverCatalog, id: \.self) { item in
                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.gray)
                                .font(.caption)
                            Text(item)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                silverToDelete = item
                                showDeleteAlert = true
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Gümüş Kataloğu")
        .alert("Gümüş Türünü Sil", isPresented: $showDeleteAlert, presenting: silverToDelete) { item in
            Button("Sil", role: .destructive) {
                silverCatalog.removeAll { $0 == item }
                save()
            }
            Button("İptal", role: .cancel) {}
        } message: { item in
            Text("\(item) öğesini katalogdan silmek istiyor musunuz?")
        }
    }

    private func addSilver() {
        let name = newSilver.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !defaultSilver.contains(name), !silverCatalog.contains(name) else { return }
        silverCatalog.append(name)
        newSilver = ""
        save()
    }

    private func save() {
        UserDefaults.standard.set(silverCatalog, forKey: "silverKey")
    }
}
