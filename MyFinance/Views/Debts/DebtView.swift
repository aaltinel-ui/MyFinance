import SwiftUI
import SwiftData

struct DebtView: View {
    @Query(sort: \Debt.verilenTarih, order: .reverse) private var debts: [Debt]
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var debtToDelete: Debt?
    @State private var editingDebt: Debt?
    @State private var searchText = ""
    @State private var filterDurum: String = "Tümü"

    private var totalVerilen: Double { debts.reduce(0) { $0 + $1.toplamTutar } }
    private var totalOdenen: Double { debts.reduce(0) { $0 + $1.genelOdemeTutari } }
    private var totalKalan: Double { debts.reduce(0) { $0 + $1.kalanBorc } }

    private var filteredDebts: [Debt] {
        debts.filter { debt in
            let matchesSearch = searchText.isEmpty ||
                debt.kpiAdi.localizedCaseInsensitiveContains(searchText) ||
                debt.tip.localizedCaseInsensitiveContains(searchText)
            let matchesDurum: Bool
            switch filterDurum {
            case "Açık": matchesDurum = debt.durum == BorcDurum.acik.rawValue
            case "Kısmi": matchesDurum = debt.durum == BorcDurum.kismi.rawValue
            case "Tamamlandı": matchesDurum = debt.durum == BorcDurum.tamamlandi.rawValue
            default: matchesDurum = true
            }
            return matchesSearch && matchesDurum
        }
    }

    var body: some View {
        List {
            // Summary
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        SummaryCardView(title: "Toplam Borç", value: Formatters.formatCurrency(totalVerilen), icon: "arrow.up.circle", color: .red)
                        SummaryCardView(title: "Ödenen", value: Formatters.formatCurrency(totalOdenen), icon: "arrow.down.circle", color: .green)
                    }
                    HStack(spacing: 12) {
                        SummaryCardView(title: "Kalan", value: Formatters.formatCurrency(totalKalan), icon: "clock", color: .orange)
                        SummaryCardView(title: "Borç Sayısı", value: "\(debts.count)", icon: "number.circle", color: .blue)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Filter
            Section {
                Picker("Durum", selection: $filterDurum) {
                    Text("Tümü").tag("Tümü")
                    ForEach(BorcDurum.allCases) { d in
                        Text(d.rawValue).tag(d.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Debts list
            Section("Borçlar (\(filteredDebts.count))") {
                if filteredDebts.isEmpty {
                    Text("Borç kaydı bulunamadı")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(filteredDebts) { debt in
                        NavigationLink(destination: DebtDetailView(debt: debt)) {
                            debtRow(debt)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                debtToDelete = debt
                                showingDeleteAlert = true
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                editingDebt = debt
                                showingEditSheet = true
                            } label: {
                                Label("Düzenle", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Borç ara...")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingAddSheet = true } label: {
                    Label("Ekle", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) { DebtFormView() }
        .sheet(isPresented: $showingEditSheet) {
            if let debt = editingDebt { DebtFormView(debt: debt) }
        }
        .alert("Borcu Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { debtToDelete = nil }
            Button("Sil", role: .destructive) {
                if let debt = debtToDelete { context.delete(debt); debtToDelete = nil }
            }
        } message: {
            Text("Bu borç ve tüm ödeme kayıtları kalıcı olarak silinecek. Bu işlem geri alınamaz.")
        }
    }

    private func debtRow(_ debt: Debt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let durum = BorcDurum(rawValue: debt.durum) {
                    Image(systemName: durum.icon)
                        .foregroundStyle(Color(durum.color))
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(debt.kpiAdi)
                        .font(.body).fontWeight(.medium)
                    HStack(spacing: 6) {
                        Text(debt.tip)
                            .font(.subheadline)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.15))
                            .clipShape(Capsule())
                        Text("\(Formatters.formatDecimal(debt.miktar)) adet")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(Formatters.formatCurrency(debt.toplamTutar))
                        .font(.body).fontWeight(.medium)
                    Text(debt.durum)
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(durumColor(debt.durum).opacity(0.15))
                        .foregroundStyle(durumColor(debt.durum))
                        .clipShape(Capsule())
                }
            }
            // Progress bar
            if debt.toplamTutar > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(durumColor(debt.durum))
                                .frame(width: geo.size.width * min(debt.odemeYuzdesi / 100, 1), height: 6)
                        }
                    }
                    .frame(height: 6)
                    HStack {
                        Text(Formatters.formatDate(debt.verilenTarih))
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("%\(Int(debt.odemeYuzdesi)) ödendi")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func durumColor(_ durum: String) -> Color {
        switch durum {
        case BorcDurum.acik.rawValue: return .orange
        case BorcDurum.kismi.rawValue: return .blue
        case BorcDurum.tamamlandi.rawValue: return .green
        default: return .secondary
        }
    }
}

// MARK: - Debt Detail View

struct DebtDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var debt: Debt
    @State private var showingEditSheet = false
    @State private var showingPaymentSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingPaymentDeleteAlert = false
    @State private var paymentToDelete: DebtPayment?

    var body: some View {
        List {
            // Status header
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if let durum = BorcDurum(rawValue: debt.durum) {
                            Image(systemName: durum.icon)
                                .font(.largeTitle)
                                .foregroundStyle(Color(durum.color))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(debt.kpiAdi)
                                .font(.title2).fontWeight(.bold)
                            Text(debt.durum)
                                .font(.subheadline)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(durumColor(debt.durum).opacity(0.15))
                                .foregroundStyle(durumColor(debt.durum))
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }

                    // Progress
                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(height: 10)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(durumColor(debt.durum))
                                    .frame(width: geo.size.width * min(debt.odemeYuzdesi / 100, 1), height: 10)
                            }
                        }
                        .frame(height: 10)
                        HStack {
                            Text("Ödenen: \(Formatters.formatCurrency(debt.genelOdemeTutari))")
                                .font(.subheadline)
                            Spacer()
                            Text("Kalan: \(Formatters.formatCurrency(debt.kalanBorc))")
                                .font(.subheadline).fontWeight(.medium)
                        }
                    }
                }
                .listRowBackground(Color.clear)
            }

            // Borç Detayları
            Section("Borç Bilgileri") {
                detailRow("Kime", debt.kpiAdi)
                detailRow("Tip", debt.tip)
                detailRow("Miktar", Formatters.formatDecimal(debt.miktar))
                detailRow("Birim Tutar", Formatters.formatCurrency(debt.birimTutar))
                detailRow("Toplam Tutar", Formatters.formatCurrency(debt.toplamTutar))
                detailRow("Para Birimi", debt.paraBirimi)
                detailRow("Verildiği Tarih", Formatters.formatDate(debt.verilenTarih))
                if let notlar = debt.notlar, !notlar.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notlar").font(.subheadline).foregroundStyle(.secondary)
                        Text(notlar).font(.body)
                    }
                }
            }

            // Ödeme Özeti
            Section("Ödeme Özeti") {
                detailRow("Genel Ödeme Tutarı", Formatters.formatCurrency(debt.genelOdemeTutari))
                detailRow("Kalan Borç", Formatters.formatCurrency(debt.kalanBorc))
                detailRow("Ödeme Yüzdesi", "%\(Int(debt.odemeYuzdesi))")
                detailRow("Ödeme Sayısı", "\(debt.odemeler.count)")
            }

            // Ödeme Kayıtları
            Section {
                if debt.odemeler.isEmpty {
                    Text("Henüz ödeme kaydı yok")
                        .font(.subheadline).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                } else {
                    ForEach(debt.odemeler.sorted(by: { $0.tarih > $1.tarih })) { payment in
                        paymentRow(payment)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    paymentToDelete = payment
                                    showingPaymentDeleteAlert = true
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Ödeme Kayıtları")
                    Spacer()
                    Button {
                        showingPaymentSheet = true
                    } label: {
                        Label("Ödeme Ekle", systemImage: "plus.circle.fill")
                            .font(.subheadline)
                    }
                }
            }

            // Actions
            Section {
                Button { showingEditSheet = true } label: {
                    Label("Borcu Düzenle", systemImage: "pencil")
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                Button(role: .destructive) { showingDeleteAlert = true } label: {
                    Label("Borcu Sil", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle("Borç Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingPaymentSheet = true } label: {
                    Label("Ödeme Ekle", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) { DebtFormView(debt: debt) }
        .sheet(isPresented: $showingPaymentSheet) { DebtPaymentFormView(debt: debt) }
        .alert("Borcu Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) { context.delete(debt); dismiss() }
        } message: {
            Text("Bu borç ve tüm ödeme kayıtları silinecek.")
        }
        .alert("Ödemeyi Sil", isPresented: $showingPaymentDeleteAlert) {
            Button("İptal", role: .cancel) { paymentToDelete = nil }
            Button("Sil", role: .destructive) {
                if let payment = paymentToDelete {
                    context.delete(payment)
                    debt.durumGuncelle()
                    paymentToDelete = nil
                }
            }
        } message: {
            Text("Bu ödeme kaydı silinecek.")
        }
    }

    private func paymentRow(_ payment: DebtPayment) -> some View {
        HStack {
            Image(systemName: "creditcard.fill")
                .foregroundStyle(.green)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(Formatters.formatDecimal(payment.miktar)) x \(Formatters.formatCurrency(payment.birimTutar))")
                    .font(.body).fontWeight(.medium)
                Text(Formatters.formatDate(payment.tarih))
                    .font(.subheadline).foregroundStyle(.secondary)
                if let not = payment.notlar, !not.isEmpty {
                    Text(not).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(Formatters.formatCurrency(payment.toplamTutar))
                .font(.body).fontWeight(.bold).foregroundStyle(.green)
        }
        .padding(.vertical, 2)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.body).fontWeight(.medium)
        }
    }

    private func durumColor(_ durum: String) -> Color {
        switch durum {
        case BorcDurum.acik.rawValue: return .orange
        case BorcDurum.kismi.rawValue: return .blue
        case BorcDurum.tamamlandi.rawValue: return .green
        default: return .secondary
        }
    }
}

// MARK: - Debt Form View

struct DebtFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    var debt: Debt?

    @State private var kpiAdi = ""
    @State private var tip = BorcTipi.gramAltin.rawValue
    @State private var miktar = ""
    @State private var birimTutar = ""
    @State private var paraBirimi = ParaBirimi.tl.rawValue
    @State private var verilenTarih = Date()
    @State private var notlar = ""

    private var isEditing: Bool { debt != nil }

    private var hesaplananToplam: Double {
        let m = Double(miktar.replacingOccurrences(of: ",", with: ".")) ?? 0
        let b = Double(birimTutar.replacingOccurrences(of: ",", with: ".")) ?? 0
        return m * b
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Borç Bilgileri") {
                    TextField("Kime verildi?", text: $kpiAdi)
                    Picker("Tip", selection: $tip) {
                        ForEach(BorcTipi.allCases) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t.rawValue)
                        }
                    }
                    Picker("Para Birimi", selection: $paraBirimi) {
                        ForEach(ParaBirimi.allCases) { p in
                            Text("\(p.rawValue) (\(p.symbol))").tag(p.rawValue)
                        }
                    }
                    DatePicker("Verildiği Tarih", selection: $verilenTarih, displayedComponents: .date)
                }

                Section("Tutar Bilgileri") {
                    TextField("Miktar", text: $miktar)
                        .keyboardType(.decimalPad)
                    TextField("Birim Tutar", text: $birimTutar)
                        .keyboardType(.decimalPad)
                    HStack {
                        Text("Toplam Tutar")
                        Spacer()
                        Text(Formatters.formatCurrency(hesaplananToplam))
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                    }
                }

                Section("Ek Bilgi") {
                    TextField("Notlar", text: $notlar, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Borç Düzenle" : "Yeni Borç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(kpiAdi.isEmpty || miktar.isEmpty || birimTutar.isEmpty)
                }
            }
            .onAppear {
                if let debt {
                    kpiAdi = debt.kpiAdi
                    tip = debt.tip
                    miktar = String(debt.miktar)
                    birimTutar = String(debt.birimTutar)
                    paraBirimi = debt.paraBirimi
                    verilenTarih = debt.verilenTarih
                    notlar = debt.notlar ?? ""
                }
            }
        }
    }

    private func save() {
        let m = Double(miktar.replacingOccurrences(of: ",", with: ".")) ?? 0
        let b = Double(birimTutar.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let debt {
            debt.kpiAdi = kpiAdi
            debt.tip = tip
            debt.miktar = m
            debt.birimTutar = b
            debt.toplamTutar = m * b
            debt.paraBirimi = paraBirimi
            debt.verilenTarih = verilenTarih
            debt.notlar = notlar.isEmpty ? nil : notlar
            // Eski alanlar güncelle
            debt.adet = m
            debt.birimFiyat = b
            debt.verilenTutar = m * b
            debt.durumGuncelle()
        } else {
            let newDebt = Debt(
                kpiAdi: kpiAdi,
                tip: tip,
                miktar: m,
                birimTutar: b,
                paraBirimi: paraBirimi,
                verilenTarih: verilenTarih,
                notlar: notlar.isEmpty ? nil : notlar
            )
            context.insert(newDebt)
        }
        dismiss()
    }
}

// MARK: - Payment Form View

struct DebtPaymentFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let debt: Debt

    @State private var tarih = Date()
    @State private var miktar = ""
    @State private var birimTutar = ""
    @State private var notlar = ""

    private var hesaplananToplam: Double {
        let m = Double(miktar.replacingOccurrences(of: ",", with: ".")) ?? 0
        let b = Double(birimTutar.replacingOccurrences(of: ",", with: ".")) ?? 0
        return m * b
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ödeme Bilgileri") {
                    DatePicker("Ödeme Tarihi", selection: $tarih, displayedComponents: .date)
                    TextField("Ödeme Miktarı", text: $miktar).keyboardType(.decimalPad)
                    TextField("Ödeme Birim Tutarı", text: $birimTutar).keyboardType(.decimalPad)
                    HStack {
                        Text("Ödeme Toplam Tutarı")
                        Spacer()
                        Text(Formatters.formatCurrency(hesaplananToplam))
                            .fontWeight(.bold).foregroundStyle(.green)
                    }
                }

                Section("Borç Bilgisi") {
                    HStack {
                        Text("Borç Tutarı"); Spacer()
                        Text(Formatters.formatCurrency(debt.toplamTutar)).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Önceki Ödemeler"); Spacer()
                        Text(Formatters.formatCurrency(debt.genelOdemeTutari)).foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Kalan Borç"); Spacer()
                        Text(Formatters.formatCurrency(debt.kalanBorc)).fontWeight(.medium).foregroundStyle(.orange)
                    }
                    HStack {
                        Text("Bu ödeme sonrası kalan"); Spacer()
                        let yeniKalan = debt.kalanBorc - hesaplananToplam
                        Text(Formatters.formatCurrency(max(yeniKalan, 0)))
                            .fontWeight(.medium)
                            .foregroundStyle(yeniKalan <= 0 ? .green : .orange)
                    }
                }

                Section("Ek Bilgi") {
                    TextField("Notlar", text: $notlar, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle("Ödeme Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("İptal") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .disabled(miktar.isEmpty || birimTutar.isEmpty)
                }
            }
        }
    }

    private func save() {
        let m = Double(miktar.replacingOccurrences(of: ",", with: ".")) ?? 0
        let b = Double(birimTutar.replacingOccurrences(of: ",", with: ".")) ?? 0

        let payment = DebtPayment(
            tarih: tarih,
            miktar: m,
            birimTutar: b,
            notlar: notlar.isEmpty ? nil : notlar
        )
        payment.debt = debt
        debt.odemeler.append(payment)
        debt.durumGuncelle()
        context.insert(payment)
        dismiss()
    }
}
