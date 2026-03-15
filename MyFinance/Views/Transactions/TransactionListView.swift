import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Query(sort: \Transaction.tarih, order: .reverse) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedKasa: String?
    @State private var selectedTip: String?

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
                    transactionRow(tx)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                context.delete(tx)
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                }
            }
            .searchable(text: $searchText, prompt: "Hareket ara...")
            .navigationTitle("Hareketler")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Ekle", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                TransactionFormView()
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
                    ForEach(KasaTip.allCases) { kasa in
                        filterChip(kasa.rawValue, isSelected: selectedKasa == kasa.rawValue) {
                            selectedKasa = selectedKasa == kasa.rawValue ? nil : kasa.rawValue
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    filterChip("Tüm Tipler", isSelected: selectedTip == nil) {
                        selectedTip = nil
                    }
                    ForEach(BirimTip.allCases) { tip in
                        filterChip(tip.rawValue, isSelected: selectedTip == tip.rawValue) {
                            selectedTip = selectedTip == tip.rawValue ? nil : tip.rawValue
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
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
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
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.islem)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(tx.kasaTip)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.forKasa(tx.kasaTip).opacity(0.15))
                        .clipShape(Capsule())
                    Text(tx.tip)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(Formatters.formatDate(tx.tarih))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(tx.isPositive ? "+" : "-")\(Formatters.formatCurrency(tx.tutarTL))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(tx.isPositive ? .green : .red)
                Text("\(Formatters.formatDecimal(tx.adet)) x \(Formatters.formatCurrencyDetailed(tx.birimFiyat))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
