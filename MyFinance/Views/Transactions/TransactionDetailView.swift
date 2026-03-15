import SwiftUI
import SwiftData

struct TransactionDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let transaction: Transaction

    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false

    var body: some View {
        List {
            Section("Hareket Bilgileri") {
                detailRow("Tarih", value: Formatters.formatDate(transaction.tarih))
                detailRow("Kasa", value: transaction.kasaTip)
                detailRow("Yön", value: transaction.isPositive ? "Alış (+)" : "Satış (-)")
                detailRow("Enstrüman", value: transaction.islem)
                detailRow("Tip", value: transaction.tip)
                detailRow("Saklama Yeri", value: transaction.nerede)
            }

            Section("Tutar Bilgileri") {
                detailRow("Birim Fiyat", value: Formatters.formatCurrencyDetailed(transaction.birimFiyat))
                detailRow("Adet", value: Formatters.formatDecimal(transaction.adet))
                HStack {
                    Text("Toplam Tutar")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Formatters.formatCurrencyDetailed(transaction.tutarTL))
                        .fontWeight(.bold)
                        .foregroundStyle(transaction.isPositive ? .green : .red)
                }
            }

            Section("Ek Bilgiler") {
                detailRow("Güncellenecek mi?", value: transaction.guncellenecekMi ? "Evet" : "Hayır")
                if let notlar = transaction.notlar, !notlar.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notlar")
                            .foregroundStyle(.secondary)
                        Text(notlar)
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Hareketi Sil", systemImage: "trash")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle(transaction.islem)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Düzenle") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TransactionFormView(transaction: transaction)
        }
        .alert("Hareketi Sil", isPresented: $showingDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                context.delete(transaction)
                dismiss()
            }
        } message: {
            Text("Bu hareket kalıcı olarak silinecek. Bu işlem geri alınamaz.")
        }
    }

    private func detailRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
