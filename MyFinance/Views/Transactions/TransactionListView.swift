import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TransactionListView: View {
    @AppStorage("hideBalances") private var hideBalances = false
    @Query(sort: \Transaction.tarih, order: .reverse) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context
    private let catalog = CatalogManager.shared
    @State private var showingAddSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingBulkDeleteAlert = false
    @State private var showingBulkDeleteKasaAlert = false
    @State private var bulkDeleteTip: String?
    @State private var bulkDeleteKasa: String?
    @State private var transactionToDelete: Transaction?
    // YKY PDF Aktarma
    @State private var showingPDFPicker = false
    @State private var ykyRows: [YKYPDFImportService.ParsedRow] = []
    @State private var showingYKYImport = false
    @State private var pdfError: String?
    @State private var searchText = ""
    @State private var selectedKasa: String?
    @State private var selectedTip: String?

    private var availableTypes: [(tip: String, count: Int)] {
        Dictionary(grouping: transactions, by: \.tip)
            .map { (tip: $0.key, count: $0.value.count) }
            .sorted { $0.tip < $1.tip }
    }

    private var availableKasaTypes: [(kasa: String, count: Int)] {
        Dictionary(grouping: transactions, by: \.kasaTip)
            .map { (kasa: $0.key, count: $0.value.count) }
            .sorted { $0.kasa < $1.kasa }
    }

    private func transactionsForType(_ tip: String) -> [Transaction] {
        transactions.filter { $0.tip == tip }
    }

    private func transactionsForKasa(_ kasa: String) -> [Transaction] {
        transactions.filter { $0.kasaTip == kasa }
    }

    private var filteredTransactions: [Transaction] {
        transactions.filter { tx in
            let matchesSearch = searchText.isEmpty ||
                tx.islem.localizedCaseInsensitiveContains(searchText) ||
                tx.kasaTip.localizedCaseInsensitiveContains(searchText)
            let matchesKasa = selectedKasa == nil || tx.kasaTip == selectedKasa
            let matchesTip = selectedTip == nil || tx.tip == selectedTip
            return matchesSearch && matchesKasa && matchesTip
        }
    }

    var body: some View {
        NavigationStack {
            List {
                filterSection
                ForEach(filteredTransactions) { tx in
                    NavigationLink(destination: TransactionDetailView(transaction: tx)) {
                        transactionRow(tx)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            transactionToDelete = tx
                            showingDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
            .refreshable {}
            .searchable(text: $searchText, prompt: "Hareket ara...")
            .navigationTitle("Hareketler")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    HStack {
                        Menu {
                            Section("Tip Bazında") {
                                ForEach(availableTypes, id: \.tip) { item in
                                    Button(role: .destructive) {
                                        bulkDeleteTip = item.tip
                                        showingBulkDeleteAlert = true
                                    } label: {
                                        Label("\(item.tip) (\(item.count) hareket)", systemImage: "trash")
                                    }
                                }
                            }
                            Section("Kasa Bazında") {
                                ForEach(availableKasaTypes, id: \.kasa) { item in
                                    Button(role: .destructive) {
                                        bulkDeleteKasa = item.kasa
                                        showingBulkDeleteKasaAlert = true
                                    } label: {
                                        Label("\(item.kasa) (\(item.count) hareket)", systemImage: "trash")
                                    }
                                }
                            }
                        } label: {
                            Label("Toplu Sil", systemImage: "trash.circle")
                        }
                        .disabled(transactions.isEmpty)

                        Button {
                            showingPDFPicker = true
                        } label: {
                            Label("PDF'den Aktar", systemImage: "doc.badge.arrow.up")
                        }

                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Ekle", systemImage: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                TransactionFormView()
            }
            // YKY PDF dosya seçici
            .fileImporter(
                isPresented: $showingPDFPicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                handlePDFPick(result)
            }
            // YKY PDF önizleme / aktarma ekranı
            .sheet(isPresented: $showingYKYImport) {
                YKYPDFImportView(rows: ykyRows)
            }
            .alert("PDF Okunamadı", isPresented: .init(
                get: { pdfError != nil },
                set: { if !$0 { pdfError = nil } }
            )) {
                Button("Tamam", role: .cancel) { pdfError = nil }
            } message: {
                Text(pdfError ?? "")
            }
            .alert("Hareketi Sil", isPresented: $showingDeleteAlert) {
                Button("İptal", role: .cancel) {
                    transactionToDelete = nil
                }
                Button("Sil", role: .destructive) {
                    if let tx = transactionToDelete {
                        context.delete(tx)
                        transactionToDelete = nil
                    }
                }
            } message: {
                Text("Bu hareket kalıcı olarak silinecek. Bu işlem geri alınamaz.")
            }
            .alert("Toplu Silme (Tip)", isPresented: $showingBulkDeleteAlert) {
                Button("İptal", role: .cancel) {
                    bulkDeleteTip = nil
                }
                Button("Tümünü Sil", role: .destructive) {
                    if let tip = bulkDeleteTip {
                        let toDelete = transactionsForType(tip)
                        for tx in toDelete {
                            context.delete(tx)
                        }
                        bulkDeleteTip = nil
                    }
                }
            } message: {
                if let tip = bulkDeleteTip {
                    Text("\"\(tip)\" tipindeki \(transactionsForType(tip).count) hareketin tamamı silinecek. Bu işlem geri alınamaz.")
                }
            }
            .alert("Toplu Silme (Kasa)", isPresented: $showingBulkDeleteKasaAlert) {
                Button("İptal", role: .cancel) {
                    bulkDeleteKasa = nil
                }
                Button("Tümünü Sil", role: .destructive) {
                    if let kasa = bulkDeleteKasa {
                        let toDelete = transactionsForKasa(kasa)
                        for tx in toDelete {
                            context.delete(tx)
                        }
                        bulkDeleteKasa = nil
                    }
                }
            } message: {
                if let kasa = bulkDeleteKasa {
                    Text("\"\(kasa)\" kasasındaki \(transactionsForKasa(kasa).count) hareketin tamamı silinecek. Bu işlem geri alınamaz.")
                }
            }
        }
    }

    private var filterSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    filterChip("Tümü", isSelected: selectedKasa == nil) {
                        selectedKasa = nil
                    }
                    ForEach(catalog.activeKasaTips, id: \.self) { kasa in
                        filterChip(kasa, isSelected: selectedKasa == kasa) {
                            selectedKasa = selectedKasa == kasa ? nil : kasa
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    filterChip("Tüm Tipler", isSelected: selectedTip == nil) {
                        selectedTip = nil
                    }
                    ForEach(catalog.activeBirimTips, id: \.self) { tip in
                        filterChip(tip, isSelected: selectedTip == tip) {
                            selectedTip = selectedTip == tip ? nil : tip
                        }
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack {
            Image(systemName: tx.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundStyle(tx.isPositive ? .green : .red)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.islem)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 6) {
                    Text(tx.kasaTip)
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.forKasa(tx.kasaTip).opacity(0.15))
                        .clipShape(Capsule())
                    Text(tx.tip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(Formatters.formatDate(tx.tarih))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(tx.isPositive ? "+" : "-")\(Formatters.maskedCurrency(tx.tutarTL))")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(tx.isPositive ? .green : .red)
                Text("\(Formatters.formatDecimal(tx.adet)) x \(Formatters.formatCurrencyDetailed(tx.birimFiyat))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - YKY PDF Handler

    private func handlePDFPick(_ result: Result<[URL], Error>) {
        switch result {
        case .failure(let err):
            pdfError = err.localizedDescription
        case .success(let urls):
            guard let url = urls.first else { return }
            // Security-scoped resource erişimi
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            let parsed = YKYPDFImportService.parse(url: url)
            if parsed.isEmpty {
                pdfError = "Bu PDF'de Yapı Kredi hisse işlemi satırı bulunamadı.\n\nDosyanın 'HİSSE SENEDİ İŞLEMLERİ' raporu olduğundan emin olun."
            } else {
                ykyRows = parsed
                showingYKYImport = true
            }
        }
    }
}
