import SwiftUI
import SwiftData

struct TransactionFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var tarih = Date()
    @State private var kasaTip: KasaTip = .birikim
    @State private var islem = ""
    @State private var tip: BirimTip = .hisse
    @State private var nerede: SaklamaYeri = .banka
    @State private var guncellenecekMi = true
    @State private var yon: HareketYon = .arti
    @State private var birimFiyat = ""
    @State private var adet = ""
    @State private var notlar = ""

    private let commonInstruments = [
        "TUPRS", "KCHOL", "AKBNK", "THYAO", "ALFAS", "ARCLK",
        "ALTIN GRAM", "Cumhuriyet Altın", "Çeyrek Altın", "Yarım Altın",
        "BITCOIN/TRY", "ETH/TRY",
        "YFBL1", "YFBL7", "YFBA1", "YFAI1", "YFAE2",
        "Euro", "Usd"
    ]

    private var tutarTL: Double {
        (Double(birimFiyat.replacingOccurrences(of: ",", with: ".")) ?? 0) *
        (Double(adet.replacingOccurrences(of: ",", with: ".")) ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Hareket Bilgileri") {
                    DatePicker("Tarih", selection: $tarih, displayedComponents: .date)
                    Picker("Kasa", selection: $kasaTip) {
                        ForEach(KasaTip.allCases) { k in
                            Text(k.rawValue).tag(k)
                        }
                    }
                    Picker("Yön", selection: $yon) {
                        Text("Alış (+)").tag(HareketYon.arti)
                        Text("Satış (-)").tag(HareketYon.eksi)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Enstrüman") {
                    Picker("Tip", selection: $tip) {
                        ForEach(BirimTip.allCases) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    if islem.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(suggestedInstruments, id: \.self) { inst in
                                    Button(inst) { islem = inst }
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
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
            .navigationTitle("Yeni Hareket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(islem.isEmpty || tutarTL == 0)
                }
            }
        }
    }

    private var suggestedInstruments: [String] {
        switch tip {
        case .hisse: return ["TUPRS", "KCHOL", "AKBNK", "THYAO", "ALFAS", "ARCLK"]
        case .altin: return ["ALTIN GRAM", "Cumhuriyet Altın", "Çeyrek Altın", "Yarım Altın"]
        case .coin: return ["BITCOIN/TRY", "ETH/TRY"]
        case .fon: return ["YFBL1", "YFBL7", "YFBA1", "YFAI1", "YFAE2"]
        default: return []
        }
    }

    private func save() {
        let bf = Double(birimFiyat.replacingOccurrences(of: ",", with: ".")) ?? 0
        let ad = Double(adet.replacingOccurrences(of: ",", with: ".")) ?? 0

        let tx = Transaction(
            tarih: tarih,
            kasaTip: kasaTip,
            islem: islem,
            tip: tip,
            nerede: nerede,
            guncellenecekMi: guncellenecekMi,
            yon: yon,
            birimFiyat: bf,
            adet: ad,
            notlar: notlar.isEmpty ? nil : notlar
        )
        context.insert(tx)
        dismiss()
    }
}
