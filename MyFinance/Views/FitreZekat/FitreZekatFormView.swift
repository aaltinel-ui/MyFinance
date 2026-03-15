import SwiftUI
import SwiftData

struct FitreZekatFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var record: FitreZekat?

    @State private var tarih = Date()
    @State private var tur = FitreZekatTur.fitre.rawValue
    @State private var kisiAdi = ""
    @State private var tutar = ""
    @State private var aciklama = ""
    @State private var notlar = ""

    private var isEditing: Bool { record != nil }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Tarih", selection: $tarih, displayedComponents: .date)

                Section("Bilgiler") {
                    Picker("Tür", selection: $tur) {
                        ForEach(FitreZekatTur.allCases) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t.rawValue)
                        }
                    }
                    TextField("Kişi Adı", text: $kisiAdi)
                    TextField("Tutar (TL)", text: $tutar).keyboardType(.decimalPad)
                    TextField("Açıklama", text: $aciklama)
                }

                Section("Ek Bilgi") {
                    TextField("Notlar", text: $notlar, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Kayıt Düzenle" : "Yeni Kayıt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(kisiAdi.isEmpty || tutar.isEmpty)
                }
            }
            .onAppear {
                if let record {
                    tarih = record.tarih
                    tur = record.tur
                    kisiAdi = record.kisiAdi
                    tutar = String(record.tutar)
                    aciklama = record.aciklama
                    notlar = record.notlar ?? ""
                }
            }
        }
    }

    private func save() {
        let t = Double(tutar.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let record {
            record.tarih = tarih
            record.tur = tur
            record.kisiAdi = kisiAdi
            record.tutar = t
            record.aciklama = aciklama
            record.notlar = notlar.isEmpty ? nil : notlar
        } else {
            let newRecord = FitreZekat(
                tarih: tarih,
                tur: tur,
                kisiAdi: kisiAdi,
                tutar: t,
                aciklama: aciklama,
                notlar: notlar.isEmpty ? nil : notlar
            )
            context.insert(newRecord)
        }
        dismiss()
    }
}
