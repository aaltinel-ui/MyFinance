import SwiftUI

private let defaultFonlar = ["AGF2T", "YAS", "TI2", "IPB", "MAC"]

struct FonPriceRow: View {
    let fonKodu: String
    @Binding var fiyat: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fonKodu)
                    .font(.headline)
                Text("Fon Birim Fiyatı")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            TextField("0,0000", text: $fiyat)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
        }
    }
}

struct FonPriceEntryView: View {
    @State private var fonFiyatlari: [String: String] = {
        (UserDefaults.standard.dictionary(forKey: "defaultFonlar") as? [String: String]) ?? [:]
    }()
    @State private var expandedFon = false
    @State private var newFonKodu = ""

    private var fonList: [String] {
        let custom = (UserDefaults.standard.stringArray(forKey: "customFonlar") ?? [])
        return defaultFonlar + custom
    }

    var body: some View {
        Form {
            Section {
                Text("Fon birim fiyatlarını TEFAS'tan alarak manuel girebilirsiniz.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Fon Birim Fiyatları") {
                ForEach(fonList, id: \.self) { kod in
                    FonPriceRow(
                        fonKodu: kod,
                        fiyat: Binding(
                            get: { fonFiyatlari[kod] ?? "" },
                            set: { fonFiyatlari[kod] = $0 }
                        )
                    )
                }
            }

            Section("Fon Ekle") {
                HStack {
                    TextField("Fon kodu (ör: TI2)", text: $newFonKodu)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    Button("Ekle") {
                        addFon()
                    }
                    .disabled(newFonKodu.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section {
                Button("Kaydet") {
                    save()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .listRowBackground(Color.accentColor)
            }
        }
        .navigationTitle("Fon Birim Fiyatları")
    }

    private func addFon() {
        let kod = newFonKodu.trimmingCharacters(in: .whitespaces).uppercased()
        guard !kod.isEmpty, !fonList.contains(kod) else { return }
        var custom = UserDefaults.standard.stringArray(forKey: "customFonlar") ?? []
        custom.append(kod)
        UserDefaults.standard.set(custom, forKey: "customFonlar")
        newFonKodu = ""
    }

    private func save() {
        UserDefaults.standard.set(fonFiyatlari, forKey: "defaultFonlar")
    }
}
