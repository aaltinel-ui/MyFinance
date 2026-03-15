import SwiftUI

struct CatalogEditView: View {
    let catalog = CatalogManager.shared
    @State private var newKasaName = ""
    @State private var newTipName = ""
    @State private var showingAddKasa = false
    @State private var showingAddTip = false

    var body: some View {
        List {
            kasaSection
            tipSection
        }
        .navigationTitle("Katalog Yönetimi")
    }

    // MARK: - Kasa Section
    private var kasaSection: some View {
        Section {
            ForEach(catalog.allKasaTips, id: \.name) { item in
                HStack {
                    Image(systemName: item.isActive ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isActive ? .green : .secondary)
                        .font(.title3)
                    Text(item.name)
                        .font(.body)
                    Spacer()
                    if item.isDefault {
                        Text("Varsayılan")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    catalog.toggleKasaTip(item.name)
                }
                .swipeActions(edge: .trailing) {
                    if !item.isDefault {
                        Button(role: .destructive) {
                            catalog.removeCustomKasaTip(item.name)
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }

            if showingAddKasa {
                HStack {
                    TextField("Yeni kasa adı", text: $newKasaName)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        catalog.addKasaTip(newKasaName)
                        newKasaName = ""
                        showingAddKasa = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                    .disabled(newKasaName.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button {
                        newKasaName = ""
                        showingAddKasa = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            } else {
                Button {
                    showingAddKasa = true
                } label: {
                    Label("Yeni Kasa Tipi Ekle", systemImage: "plus.circle.fill")
                }
            }
        } header: {
            Text("Kasa Tipleri")
        } footer: {
            Text("Varsayılan tipleri gizleyebilirsiniz. Özel tipleri silebilirsiniz.")
        }
    }

    // MARK: - Tip Section
    private var tipSection: some View {
        Section {
            ForEach(catalog.allBirimTips, id: \.name) { item in
                HStack {
                    Image(systemName: item.isActive ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isActive ? .green : .secondary)
                        .font(.title3)
                    Text(item.name)
                        .font(.body)
                    Spacer()
                    if item.isDefault {
                        Text("Varsayılan")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    catalog.toggleBirimTip(item.name)
                }
                .swipeActions(edge: .trailing) {
                    if !item.isDefault {
                        Button(role: .destructive) {
                            catalog.removeCustomBirimTip(item.name)
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }

            if showingAddTip {
                HStack {
                    TextField("Yeni tip adı", text: $newTipName)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        catalog.addBirimTip(newTipName)
                        newTipName = ""
                        showingAddTip = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                    .disabled(newTipName.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button {
                        newTipName = ""
                        showingAddTip = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.title3)
                    }
                }
            } else {
                Button {
                    showingAddTip = true
                } label: {
                    Label("Yeni Birim Tipi Ekle", systemImage: "plus.circle.fill")
                }
            }
        } header: {
            Text("Birim Tipleri")
        } footer: {
            Text("Varsayılan tipleri gizleyebilirsiniz. Özel tipleri silebilirsiniz.")
        }
    }
}
