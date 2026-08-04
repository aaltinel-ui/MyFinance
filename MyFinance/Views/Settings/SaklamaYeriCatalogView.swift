import SwiftUI

struct SaklamaYeriCatalogView: View {
    private let defaultSaklama = SaklamaYeri.allCases.map(\.rawValue)
    @State private var saklamaCatalog: [String] = UserDefaults.standard.stringArray(forKey: "saklamaKey") ?? []
    @State private var newSaklama = ""
    @State private var saklamaToDelete: String?
    @State private var showDeleteAlert = false
    @State private var expandedSaklama = false

    var body: some View {
        Form {
            Section("Varsayılan Saklama Yerleri") {
                ForEach(defaultSaklama, id: \.self) { item in
                    HStack {
                        Image(systemName: "building.columns")
                            .foregroundStyle(.blue)
                        Text(item)
                    }
                }
            }

            Section {
                // Not: Mac Catalyst'te aynı HStack içinde esnek genişleyen bir
                // eleman (TextField) varsa, sağındaki Button'ın hit-test alanı
                // bozuluyor ve tıklamalar aksiyonu tetiklemiyor. Bu yüzden
                // TextField ile butonu ayrı satırlarda tutuyoruz.
                TextField("Saklama yeri adı...", text: $newSaklama)
                    .onSubmit { addSaklama() }

                Button("Ekle") {
                    addSaklama()
                }
                .disabled(newSaklama.trimmingCharacters(in: .whitespaces).isEmpty)
            } header: {
                Text("Yeni Saklama Yeri Ekle")
            }

            if !saklamaCatalog.isEmpty {
                Section("Eklenen Saklama Yerleri") {
                    ForEach(saklamaCatalog, id: \.self) { item in
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .foregroundStyle(.purple)
                            Text(item)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                saklamaToDelete = item
                                showDeleteAlert = true
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Saklama Yeri Kataloğu")
        .alert("Saklama Yerini Sil", isPresented: $showDeleteAlert, presenting: saklamaToDelete) { item in
            Button("Sil", role: .destructive) {
                saklamaCatalog.removeAll { $0 == item }
                save()
            }
            Button("İptal", role: .cancel) {}
        } message: { item in
            Text("\(item) saklama yerini katalogdan silmek istiyor musunuz?")
        }
    }

    private func addSaklama() {
        let name = newSaklama.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !defaultSaklama.contains(name), !saklamaCatalog.contains(name) else { return }
        saklamaCatalog.append(name)
        newSaklama = ""
        save()
    }

    private func save() {
        UserDefaults.standard.set(saklamaCatalog, forKey: "saklamaKey")
    }
}
