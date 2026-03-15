import SwiftUI
import SwiftData

struct ChildExpenseListView: View {
    @Query(sort: \ChildExpense.tarih, order: .reverse) private var expenses: [ChildExpense]
    @Environment(\.modelContext) private var context
    @State private var showingAddSheet = false
    @State private var showingDeleteAlert = false
    @State private var expenseToDelete: ChildExpense?
    @State private var editingExpense: ChildExpense?
    @State private var searchText = ""
    @State private var selectedChild: String?
    @State private var selectedYear: Int?

    private var children: [String] {
        Array(Set(expenses.map(\.cocukAdi))).sorted()
    }

    private var years: [Int] {
        Array(Set(expenses.map(\.yil))).sorted(by: >)
    }

    private var totalSpentTL: Double { filteredExpenses.reduce(0) { $0 + $1.tutar } }
    private var totalSpentEUR: Double { filteredExpenses.reduce(0) { $0 + $1.eurDegeri } }

    private var filteredExpenses: [ChildExpense] {
        expenses.filter { exp in
            let matchesSearch = searchText.isEmpty ||
                exp.cocukAdi.localizedCaseInsensitiveContains(searchText) ||
                exp.aciklama.localizedCaseInsensitiveContains(searchText) ||
                exp.kategori.localizedCaseInsensitiveContains(searchText)
            let matchesChild = selectedChild == nil || exp.cocukAdi == selectedChild
            let matchesYear = selectedYear == nil || exp.yil == selectedYear
            return matchesSearch && matchesChild && matchesYear
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Summary Card
            VStack(spacing: 8) {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Toplam TL")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(Formatters.formatCurrency(totalSpentTL))
                            .font(.title3).fontWeight(.bold)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Toplam EUR")
                            .font(.caption).foregroundStyle(.secondary)
                        Text("€\(Int(totalSpentEUR))")
                            .font(.title3).fontWeight(.bold).foregroundStyle(.blue)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(filteredExpenses.count)")
                            .font(.title3).fontWeight(.bold)
                        Text("kayıt")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal).padding(.top, 12)

                // Child + Year filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        filterChip("Tümü", isSelected: selectedChild == nil && selectedYear == nil) {
                            selectedChild = nil
                            selectedYear = nil
                        }
                        ForEach(children, id: \.self) { child in
                            filterChip(child, isSelected: selectedChild == child) {
                                selectedChild = selectedChild == child ? nil : child
                            }
                        }
                        Divider().frame(height: 20)
                        ForEach(years, id: \.self) { year in
                            filterChip(String(year), isSelected: selectedYear == year) {
                                selectedYear = selectedYear == year ? nil : year
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
            .background(Color(.systemGroupedBackground))

            // List
            List {
                ForEach(filteredExpenses) { exp in
                    NavigationLink(destination: ChildExpenseDetailView(expense: exp)) {
                        expenseRow(exp)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            expenseToDelete = exp
                            showingDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            editingExpense = exp
                        } label: {
                            Label("Düzenle", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                }
            }
            .listStyle(.plain)
        }
        .onAppear {
            DataSeeder.seedIfNeeded(context: context)
        }
        .searchable(text: $searchText, prompt: "Harcama ara...")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button { showingAddSheet = true } label: {
                    Label("Ekle", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ChildExpenseFormView()
        }
        .sheet(item: $editingExpense) { exp in
            ChildExpenseFormView(expense: exp)
        }
        .alert("Harcamayı Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { expenseToDelete = nil }
            Button("Sil", role: .destructive) {
                if let exp = expenseToDelete {
                    context.delete(exp)
                    expenseToDelete = nil
                }
            }
        } message: {
            Text("Bu harcama kaydı kalıcı olarak silinecek.")
        }
    }

    private func expenseRow(_ exp: ChildExpense) -> some View {
        HStack {
            if let kat = CocukHarcamaKategori(rawValue: exp.kategori) {
                Image(systemName: kat.icon)
                    .font(.title3)
                    .foregroundStyle(Color(kat.color))
                    .frame(width: 32)
            } else {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 32)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(exp.aciklama)
                    .font(.body).fontWeight(.medium)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(exp.cocukAdi)
                        .font(.caption)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.purple.opacity(0.15))
                        .clipShape(Capsule())
                    Text(String(exp.yil))
                        .font(.caption).foregroundStyle(.secondary)
                    Text(Formatters.formatDate(exp.tarih))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.formatCurrency(exp.tutar))
                    .font(.body).fontWeight(.medium)
                if exp.eurDegeri > 0 {
                    Text("€\(Int(exp.eurDegeri))")
                        .font(.caption).foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.secondary.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ChildExpenseDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let expense: ChildExpense
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Harcama Detayı").font(.headline)
                        detailRow("Çocuk", expense.cocukAdi)
                        detailRow("Yıl", String(expense.yil))
                        detailRow("Kategori", expense.kategori)
                        detailRow("Açıklama", expense.aciklama)
                        Divider()
                        detailRow("Tutar (TL)", Formatters.formatCurrency(expense.tutar))
                        if expense.eurDegeri > 0 {
                            detailRow("EUR Değeri", "€\(Int(expense.eurDegeri))")
                        }
                        if expense.kur > 0 {
                            detailRow("Kur", String(format: "%.2f", expense.kur))
                        }
                        Divider()
                        detailRow("Tarih", Formatters.formatDate(expense.tarih))
                        if let notlar = expense.notlar, !notlar.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notlar").font(.subheadline).foregroundStyle(.secondary)
                                Text(notlar).font(.body)
                            }
                        }
                    }
                }

                VStack(spacing: 12) {
                    Button { showingEditSheet = true } label: {
                        Label("Düzenle", systemImage: "pencil")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.accentColor).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Button(role: .destructive) { showingDeleteAlert = true } label: {
                        Label("Sil", systemImage: "trash")
                            .frame(maxWidth: .infinity).padding()
                            .background(Color.red.opacity(0.1)).foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Harcama Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditSheet) { ChildExpenseFormView(expense: expense) }
        .alert("Harcamayı Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) { context.delete(expense); dismiss() }
        } message: {
            Text("Bu harcama kaydı kalıcı olarak silinecek.")
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.body).fontWeight(.medium)
        }
    }
}
