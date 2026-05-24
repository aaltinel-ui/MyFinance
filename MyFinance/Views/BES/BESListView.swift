import SwiftUI
import SwiftData

struct BESListView: View {
    @AppStorage("hideBalances") private var hideBalances = false
    @Query(sort: \BESHesap.baslangicTarihi, order: .reverse) private var hesaplar: [BESHesap]
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false
    @State private var editingHesap: BESHesap?
    @State private var hesapToDelete: BESHesap?
    @State private var showingDeleteAlert = false

    private var toplamBirikim: Double { hesaplar.reduce(0) { $0 + $1.birikimTutari } }
    private var toplamDevlet: Double { hesaplar.reduce(0) { $0 + $1.devletKatkisi } }
    private var toplamFon: Double { hesaplar.reduce(0) { $0 + $1.fonDegeri } }
    private var toplamDeger: Double { hesaplar.reduce(0) { $0 + $1.toplamDeger } }

    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        SummaryCardView(title: "Toplam Değer", value: Formatters.maskedCurrency(toplamDeger), icon: "building.columns.fill", color: .purple)
                        SummaryCardView(title: "Birikim", value: Formatters.maskedCurrency(toplamBirikim), icon: "banknote", color: .blue)
                    }
                    HStack(spacing: 12) {
                        SummaryCardView(title: "Devlet Katkısı", value: Formatters.maskedCurrency(toplamDevlet), icon: "star.circle", color: .orange)
                        SummaryCardView(title: "Fon Değeri", value: Formatters.maskedCurrency(toplamFon), icon: "chart.pie", color: .green)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("BES Hesapları (\(hesaplar.count))") {
                if hesaplar.isEmpty {
                    Text("Henüz BES hesabı eklenmemiş")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(hesaplar) { hesap in
                        NavigationLink(destination: BESDetailView(hesap: hesap)) {
                            hesapRow(hesap)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                hesapToDelete = hesap
                                showingDeleteAlert = true
                            } label: { Label("Sil", systemImage: "trash") }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingHesap = hesap
                            } label: { Label("Düzenle", systemImage: "pencil") }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingAddSheet = true } label: {
                    Label("Ekle", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) { BESFormView() }
        .sheet(item: $editingHesap) { hesap in BESFormView(hesap: hesap) }
        .alert("BES Hesabını Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { hesapToDelete = nil }
            Button("Sil", role: .destructive) {
                if let h = hesapToDelete { context.delete(h); hesapToDelete = nil }
            }
        } message: {
            Text("Bu BES hesabı kalıcı olarak silinecek.")
        }
    }

    private func hesapRow(_ hesap: BESHesap) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "building.columns.fill")
                    .foregroundStyle(.purple)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(hesap.sirketAdi)
                        .font(.body).fontWeight(.medium)
                    Text(hesap.planAdi)
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Formatters.maskedCurrency(hesap.toplamDeger))
                        .font(.body).fontWeight(.bold)
                    Text("Toplam Değer")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 12) {
                Label(Formatters.maskedCurrency(hesap.birikimTutari), systemImage: "banknote")
                    .font(.caption).foregroundStyle(.blue)
                Label(Formatters.maskedCurrency(hesap.devletKatkisi), systemImage: "star.circle")
                    .font(.caption).foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BESDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var hesap: BESHesap
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "building.columns.fill")
                            .font(.largeTitle).foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(hesap.sirketAdi).font(.title2).fontWeight(.bold)
                            Text(hesap.planAdi).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    Divider()
                    HStack {
                        Text("Toplam Değer").foregroundStyle(.secondary)
                        Spacer()
                        Text(Formatters.maskedCurrency(hesap.toplamDeger))
                            .font(.title3).fontWeight(.bold).foregroundStyle(.purple)
                    }
                }
                .listRowBackground(Color.clear)
            }

            Section("Hesap Bilgileri") {
                if !hesap.hesapNo.isEmpty { detailRow("Hesap No", hesap.hesapNo) }
                detailRow("Başlangıç Tarihi", Formatters.formatDate(hesap.baslangicTarihi))
                if let notlar = hesap.notlar, !notlar.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notlar").font(.subheadline).foregroundStyle(.secondary)
                        Text(notlar)
                    }
                }
            }

            Section("Değer Detayı") {
                detailRow("Birikim Tutarı", Formatters.maskedCurrency(hesap.birikimTutari))
                detailRow("Devlet Katkısı", Formatters.maskedCurrency(hesap.devletKatkisi))
                detailRow("Şirket Katkısı", Formatters.maskedCurrency(hesap.sirketKatkisi))
                detailRow("Fon Değeri", Formatters.maskedCurrency(hesap.fonDegeri))
                detailRow("Toplam Değer", Formatters.maskedCurrency(hesap.toplamDeger))
            }

            Section {
                Button { showingEditSheet = true } label: {
                    Label("Hesabı Düzenle", systemImage: "pencil").frame(maxWidth: .infinity, alignment: .center)
                }
                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Label("Hesabı Sil", systemImage: "trash").frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("BES Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) { BESFormView(hesap: hesap) }
        .alert("BES Hesabını Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) { context.delete(hesap); dismiss() }
        } message: { Text("Bu BES hesabı ve tüm verileri silinecek.") }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.body).fontWeight(.medium)
        }
    }
}

struct BESFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var hesap: BESHesap?

    @State private var sirketAdi = ""
    @State private var planAdi = "Bireysel Emeklilik Planı"
    @State private var hesapNo = ""
    @State private var baslangicTarihi = Date()
    @State private var birikimTutari = ""
    @State private var devletKatkisi = ""
    @State private var sirketKatkisi = ""
    @State private var fonDegeri = ""
    @State private var notlar = ""

    private let sirketler = ["Garanti Emeklilik", "Fiba Emeklilik", "Anadolu Hayat", "Allianz Yaşam", "Avivasa", "NN Hayat", "Zurich Sigorta", "Groupama Emeklilik"]
    private var isEditing: Bool { hesap != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Hesap Bilgileri") {
                    Picker("Şirket Adı", selection: $sirketAdi) {
                        Text("Seçiniz").tag("")
                        ForEach(sirketler, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Plan Adı", text: $planAdi)
                    TextField("Hesap No (opsiyonel)", text: $hesapNo)
                    DatePicker("Başlangıç Tarihi", selection: $baslangicTarihi, displayedComponents: .date)
                }

                Section("Değerler (TL)") {
                    TextField("Birikim Tutarı", text: $birikimTutari).keyboardType(.decimalPad)
                    TextField("Devlet Katkısı", text: $devletKatkisi).keyboardType(.decimalPad)
                    TextField("Şirket Katkısı", text: $sirketKatkisi).keyboardType(.decimalPad)
                    TextField("Fon Değeri", text: $fonDegeri).keyboardType(.decimalPad)
                    HStack {
                        Text("Toplam Değer")
                        Spacer()
                        Text(Formatters.maskedCurrency(hesaplananToplam)).fontWeight(.bold)
                    }
                }

                Section("Ek Bilgi") {
                    TextField("Notlar", text: $notlar, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Hesap Düzenle" : "Yeni BES Hesabı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }.disabled(sirketAdi.isEmpty)
                }
            }
            .onAppear { loadHesap() }
        }
    }

    private var hesaplananToplam: Double {
        (Double(birikimTutari.replacingOccurrences(of: ",", with: ".")) ?? 0) +
        (Double(devletKatkisi.replacingOccurrences(of: ",", with: ".")) ?? 0) +
        (Double(sirketKatkisi.replacingOccurrences(of: ",", with: ".")) ?? 0) +
        (Double(fonDegeri.replacingOccurrences(of: ",", with: ".")) ?? 0)
    }

    private func loadHesap() {
        guard let h = hesap else { return }
        sirketAdi = h.sirketAdi; planAdi = h.planAdi; hesapNo = h.hesapNo
        baslangicTarihi = h.baslangicTarihi
        birikimTutari = String(h.birikimTutari); devletKatkisi = String(h.devletKatkisi)
        sirketKatkisi = String(h.sirketKatkisi); fonDegeri = String(h.fonDegeri)
        notlar = h.notlar ?? ""
    }

    private func parse(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0 }

    private func save() {
        if let h = hesap {
            h.sirketAdi = sirketAdi; h.planAdi = planAdi; h.hesapNo = hesapNo
            h.baslangicTarihi = baslangicTarihi
            h.birikimTutari = parse(birikimTutari); h.devletKatkisi = parse(devletKatkisi)
            h.sirketKatkisi = parse(sirketKatkisi); h.fonDegeri = parse(fonDegeri)
            h.notlar = notlar.isEmpty ? nil : notlar
        } else {
            context.insert(BESHesap(
                sirketAdi: sirketAdi, planAdi: planAdi, hesapNo: hesapNo,
                baslangicTarihi: baslangicTarihi,
                birikimTutari: parse(birikimTutari), devletKatkisi: parse(devletKatkisi),
                sirketKatkisi: parse(sirketKatkisi), fonDegeri: parse(fonDegeri),
                notlar: notlar.isEmpty ? nil : notlar
            ))
        }
        dismiss()
    }
}
