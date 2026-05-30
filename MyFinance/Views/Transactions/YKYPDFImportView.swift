import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Yapı Kredi PDF Aktarma Ekranı
//
// PDF parse sonuçlarını listeler; kullanıcı kasa/saklama yeri seçer,
// istemediği satırları iptal edebilir ve "Aktar" butonuyla kaydeder.

struct YKYPDFImportView: View {
    let rows: [YKYPDFImportService.ParsedRow]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @State private var selectedKasa:   KasaTip    = .birikim
    @State private var selectedNerede: SaklamaYeri = .banka
    @State private var selectedIDs:    Set<UUID>
    @State private var importDone      = false
    @State private var addedCount      = 0

    init(rows: [YKYPDFImportService.ParsedRow]) {
        self.rows = rows
        _selectedIDs = State(initialValue: Set(rows.map { $0.id }))
    }

    private var selectedRows: [YKYPDFImportService.ParsedRow] {
        rows.filter { selectedIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Form {
                // ── Ayarlar ──────────────────────────────────────────────
                Section("Aktarma Ayarları") {
                    Picker("Kasa", selection: $selectedKasa) {
                        ForEach(KasaTip.allCases) { kasa in
                            Text(kasa.rawValue).tag(kasa)
                        }
                    }
                    Picker("Saklama Yeri", selection: $selectedNerede) {
                        ForEach(SaklamaYeri.allCases) { yer in
                            Text(yer.rawValue).tag(yer)
                        }
                    }
                }

                // ── İşlem Listesi ─────────────────────────────────────────
                Section {
                    if rows.isEmpty {
                        ContentUnavailableView(
                            "İşlem Bulunamadı",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text("PDF'de Yapı Kredi hisse işlemi satırı tespit edilemedi.")
                        )
                    } else {
                        ForEach(rows) { row in
                            rowCell(row)
                        }
                    }
                } header: {
                    HStack {
                        Text("\(rows.count) İşlem Bulundu")
                        Spacer()
                        if rows.count > 0 {
                            Button(selectedIDs.count == rows.count ? "Tümünü Kaldır" : "Tümünü Seç") {
                                if selectedIDs.count == rows.count {
                                    selectedIDs.removeAll()
                                } else {
                                    selectedIDs = Set(rows.map { $0.id })
                                }
                            }
                            .font(.caption)
                        }
                    }
                }

                // ── Tamamlandı Mesajı ─────────────────────────────────────
                if importDone {
                    Section {
                        Label("\(addedCount) yeni işlem eklendi", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("YKY PDF Aktarma")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        doImport()
                    } label: {
                        Text("Aktar (\(selectedIDs.count))")
                            .fontWeight(.semibold)
                    }
                    .disabled(selectedIDs.isEmpty || importDone)
                }
            }
        }
    }

    // MARK: - Row Cell

    @ViewBuilder
    private func rowCell(_ row: YKYPDFImportService.ParsedRow) -> some View {
        Button {
            if selectedIDs.contains(row.id) {
                selectedIDs.remove(row.id)
            } else {
                selectedIDs.insert(row.id)
            }
        } label: {
            HStack(spacing: 12) {
                // Seçim işareti
                Image(systemName: selectedIDs.contains(row.id)
                      ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedIDs.contains(row.id) ? .blue : .secondary)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(row.hisseKodu)
                            .font(.headline)
                        Spacer()
                        // Alış / Satış etiketi
                        Text(row.yonEtiketi)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(row.yon == .alindi
                                        ? Color.green.opacity(0.15)
                                        : Color.red.opacity(0.15))
                            .foregroundStyle(row.yon == .alindi ? .green : .red)
                            .clipShape(Capsule())
                    }

                    // Adet × Fiyat = Tutar
                    Group {
                        let adetStr  = formatAdet(row.adet)
                        let fiyatStr = String(format: "%.2f", row.birimFiyat)
                        let tutarStr = formatTutar(row.tutarTL)
                        Text("\(adetStr) adet × ₺\(fiyatStr) = ₺\(tutarStr)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    Text(row.tarih.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Import

    private func doImport() {
        let toImport = selectedRows
        addedCount = YKYPDFImportService.importRows(
            toImport,
            kasaTip: selectedKasa,
            nerede: selectedNerede,
            context: context
        )
        importDone = true
        // 1.2 saniye sonra otomatik kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }

    // MARK: - Formatters

    private func formatAdet(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", v)
            : String(format: "%.3f", v)
    }

    private func formatTutar(_ v: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = 2
        fmt.maximumFractionDigits = 2
        fmt.groupingSeparator = "."
        fmt.decimalSeparator = ","
        fmt.locale = Locale(identifier: "tr_TR")
        return fmt.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v)
    }
}
