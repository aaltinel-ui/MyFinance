import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var transaction: Transaction?
    private let catalog = CatalogManager.shared

    @State private var tarih = Date()
    @State private var kasaTipStr = KasaTip.birikim.rawValue
    @State private var islem = ""
    @State private var tipStr = BirimTip.hisse.rawValue
    @State private var nerede: SaklamaYeri = .banka
    @State private var guncellenecekMi = true
    @State private var yon: HareketYon = .arti
    @State private var birimFiyat = ""
    @State private var adet = ""
    @State private var notlar = ""

    private var isEditing: Bool { transaction != nil }

    private var tutarTL: Double {
        (Double(birimFiyat.replacingOccurrences(of: ",", with: ".")) ?? 0) *
        (Double(adet.replacingOccurrences(of: ",", with: ".")) ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Hareket Bilgileri") {
                    DatePicker("Tarih", selection: $tarih, displayedComponents: .date)
                    Picker("Kasa", selection: $kasaTipStr) {
                        ForEach(catalog.activeKasaTips, id: \.self) { kasa in
                            Text(kasa).tag(kasa)
                        }
                    }
                    Picker("Yön", selection: $yon) {
                        Text("Alış (+)").tag(HareketYon.arti)
                        Text("Satış (-)").tag(HareketYon.eksi)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Enstrüman") {
                    Picker("Tip", selection: $tipStr) {
                        ForEach(catalog.activeBirimTips, id: \.self) { tip in
                            Text(tip).tag(tip)
                        }
                    }
                    if islem.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(suggestedInstruments, id: \.self) { inst in
                                    Button(inst) { islem = inst }
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Color.accentColor.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    TextField("Enstrüman adı", text: $islem)
                        .textInputAutocapitalization(.characters)
                    Picker("Nerede?", selection: $nerede) {
                        ForEach(SaklamaYeri.allCases) { n in
                            Text(n.rawValue).tag(n)
                        }
                    }
                }

                Section("Tutar") {
                    TextField("Birim Fiyat", text: $birimFiyat)
                        .keyboardType(.decimalPad)
                    TextField("Adet", text: $adet)
                        .keyboardType(.decimalPad)
                    HStack {
                        Text("Toplam:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.formatCurrencyDetailed(tutarTL))
                            .fontWeight(.bold)
                    }
                }

                Section("Ek Bilgiler") {
                    Toggle("Güncellenecek mi?", isOn: $guncellenecekMi)
                    TextField("Notlar", text: $notlar, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle(isEditing ? "Hareketi Düzenle" : "Yeni Hareket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Güncelle" : "Kaydet") { save() }
                        .disabled(islem.isEmpty || tutarTL == 0)
                }
            }
            .onAppear {
                if let tx = transaction {
                    tarih = tx.tarih
                    kasaTipStr = tx.kasaTip
                    islem = tx.islem
                    tipStr = tx.tip
                    nerede = tx.neredeEnum ?? .banka
                    guncellenecekMi = tx.guncellenecekMi
                    yon = tx.yonEnum ?? .arti
                    birimFiyat = Formatters.formatDecimal(tx.birimFiyat)
                    adet = Formatters.formatDecimal(tx.adet)
                    notlar = tx.notlar ?? ""
                }
            }
        }
    }

    private var suggestedInstruments: [String] {
        switch BirimTip(rawValue: tipStr) {
        // Hisse Senedi Kataloğu'ndan (Ayarlar) dinamik olarak okunur, böylece
        // sonradan eklenen semboller (ör. DMLKT) de burada görünür.
        case .hisse: return UserDefaults.standard.stringArray(forKey: "stockKey")
            ?? ["TUPRS", "KCHOL", "AKBNK", "THYAO", "ALFAS", "ARCLK"]
        case .altin: return ["ALTIN GRAM", "Cumhuriyet Altın", "Çeyrek Altın", "Yarım Altın"]
        case .coin: return ["BITCOIN/TRY", "ETH/TRY"]
        case .fon: return ["YFBL1", "YFBL7", "YFBA1", "YFAI1", "YFAE2"]
        default: return []
        }
    }

    private func save() {
        let bf = Double(birimFiyat.replacingOccurrences(of: ",", with: ".")) ?? 0
        let ad = Double(adet.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let tx = transaction {
            tx.tarih = tarih
            tx.kasaTip = kasaTipStr
            tx.islem = islem
            tx.tip = tipStr
            tx.nerede = nerede.rawValue
            tx.guncellenecekMi = guncellenecekMi
            tx.yon = yon.rawValue
            tx.birimFiyat = bf
            tx.adet = ad
            tx.tutarTL = bf * ad
            tx.notlar = notlar.isEmpty ? nil : notlar
        } else {
            let kasaEnum = KasaTip(rawValue: kasaTipStr) ?? .birikim
            let tipEnum = BirimTip(rawValue: tipStr) ?? .hisse
            let tx = Transaction(
                tarih: tarih,
                kasaTip: kasaEnum,
                islem: islem,
                tip: tipEnum,
                nerede: nerede,
                guncellenecekMi: guncellenecekMi,
                yon: yon,
                birimFiyat: bf,
                adet: ad,
                notlar: notlar.isEmpty ? nil : notlar
            )
            // Override with string values for custom types
            tx.kasaTip = kasaTipStr
            tx.tip = tipStr
            context.insert(tx)
        }
        dismiss()
    }
}
