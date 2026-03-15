import SwiftUI
import SwiftData

struct ChildExpenseFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ChildExpense.tarih, order: .reverse) private var existingExpenses: [ChildExpense]
    var expense: ChildExpense?

    @State private var yil = Calendar.current.component(.year, from: Date())
    @State private var tarih = Date()
    @State private var cocukAdi = ""
    @State private var kategori = CocukHarcamaKategori.egitim.rawValue
    @State private var aciklama = ""
    @State private var tutar = ""
    @State private var eurDegeri = ""
    @State private var kur = ""
    @State private var notlar = ""

    private var isEditing: Bool { expense != nil }

    private var existingChildren: [String] {
        Array(Set(existingExpenses.map(\.cocukAdi))).sorted()
    }

    private var hesaplananKur: Double? {
        let t = Double(tutar.replacingOccurrences(of: ",", with: ".")) ?? 0
        let e = Double(eurDegeri.replacingOccurrences(of: ",", with: ".")) ?? 0
        guard e > 0, t > 0 else { return nil }
        return t / e
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tarih") {
                    Picker("Yıl", selection: $yil) {
                        ForEach((2018...Calendar.current.component(.year, from: Date())), id: \.self) { y in
                            Text(String(y)).tag(y)
                        }
                    }
                    DatePicker("Tarih", selection: $tarih, displayedComponents: .date)
                }

                Section("Çocuk") {
                    TextField("Çocuk Adı", text: $cocukAdi)
                        .textInputAutocapitalization(.characters)
                    if !existingChildren.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(existingChildren, id: \.self) { name in
                                    Button(name) { cocukAdi = name }
                                        .font(.subheadline)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(cocukAdi == name ? Color.purple : Color.secondary.opacity(0.15))
                                        .foregroundStyle(cocukAdi == name ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }

                Section("Detaylar") {
                    Picker("Kategori", selection: $kategori) {
                        ForEach(CocukHarcamaKategori.allCases) { kat in
                            Label(kat.rawValue, systemImage: kat.icon).tag(kat.rawValue)
                        }
                    }
                    TextField("Açıklama", text: $aciklama)
                }

                Section("Tutar Bilgileri") {
                    TextField("Tutar (TL)", text: $tutar)
                        .keyboardType(.decimalPad)
                    TextField("EUR Değeri", text: $eurDegeri)
                        .keyboardType(.decimalPad)

                    if let hesaplanan = hesaplananKur {
                        HStack {
                            Text("Hesaplanan Kur")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.2f", hesaplanan))
                                .font(.body).fontWeight(.medium).foregroundStyle(.blue)
                        }
                    }
                }

                Section("Ek Bilgi") {
                    TextField("Notlar", text: $notlar, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Harcama Düzenle" : "Yeni Harcama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(cocukAdi.isEmpty || aciklama.isEmpty || tutar.isEmpty)
                }
            }
            .onAppear {
                if let expense {
                    yil = expense.yil
                    tarih = expense.tarih
                    cocukAdi = expense.cocukAdi
                    kategori = expense.kategori
                    aciklama = expense.aciklama
                    tutar = String(expense.tutar)
                    eurDegeri = expense.eurDegeri > 0 ? String(expense.eurDegeri) : ""
                    kur = expense.kur > 0 ? String(expense.kur) : ""
                    notlar = expense.notlar ?? ""
                }
            }
        }
    }

    private func save() {
        let t = Double(tutar.replacingOccurrences(of: ",", with: ".")) ?? 0
        let e = Double(eurDegeri.replacingOccurrences(of: ",", with: ".")) ?? 0
        let k = Double(kur.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let expense {
            expense.yil = yil
            expense.tarih = tarih
            expense.cocukAdi = cocukAdi
            expense.kategori = kategori
            expense.aciklama = aciklama
            expense.tutar = t
            expense.eurDegeri = e
            expense.kur = k > 0 ? k : (e > 0 ? t / e : 0)
            expense.notlar = notlar.isEmpty ? nil : notlar
        } else {
            let newExpense = ChildExpense(
                yil: yil,
                tarih: tarih,
                cocukAdi: cocukAdi,
                kategori: kategori,
                aciklama: aciklama,
                tutar: t,
                eurDegeri: e,
                kur: k,
                notlar: notlar.isEmpty ? nil : notlar
            )
            context.insert(newExpense)
        }
        dismiss()
    }
}
