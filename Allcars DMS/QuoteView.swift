import SwiftUI

struct QuoteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vehicle: Vehicle

    @State private var customerName = ""
    @State private var customerPhone = ""
    @State private var quotePrice = ""
    @State private var validUntil = Calendar.current.date(
        byAdding: .day,
        value: 7,
        to: Date()
    ) ?? Date()
    @State private var notes = ""
    @State private var generatedQuote: GeneratedQuote?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Vehicle") {
                    LabeledContent("Vehicle", value: vehicle.displayName)
                    LabeledContent(
                        "Registration",
                        value: vehicle.registrationNumber ?? "-"
                    )
                    LabeledContent(
                        "Advertised Price",
                        value: Money.rand(vehicle.askingPriceCents)
                    )
                }

                Section("Customer") {
                    TextField("Customer Name", text: $customerName)
                    TextField("Cellphone (Optional)", text: $customerPhone)
                        .keyboardType(.phonePad)
                }

                Section("Quote") {
                    TextField("Quoted Price", text: $quotePrice)
                        .keyboardType(.decimalPad)
                    DatePicker(
                        "Valid Until",
                        selection: $validUntil,
                        displayedComponents: .date
                    )
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }

                Section {
                    Button {
                        generateQuote()
                    } label: {
                        Label("Generate Quote PDF", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(Money.cents(from: quotePrice) <= 0)
                }
            }
            .navigationTitle("Vehicle Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if quotePrice.isEmpty {
                    quotePrice = String(
                        format: "%.2f",
                        Double(vehicle.askingPriceCents) / 100
                    )
                }
            }
            .sheet(item: $generatedQuote) { quote in
                InvoicePreviewView(
                    invoiceURL: quote.url,
                    documentTitle: "Vehicle Quote"
                )
            }
            .alert(
                "Could Not Generate Quote",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private func generateQuote() {
        do {
            let url = try QuoteGenerator.generate(
                for: vehicle,
                customerName: customerName,
                customerPhone: customerPhone,
                priceCents: Money.cents(from: quotePrice),
                validUntil: validUntil,
                notes: notes
            )
            generatedQuote = GeneratedQuote(url: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct GeneratedQuote: Identifiable {
    let id = UUID()
    let url: URL
}
