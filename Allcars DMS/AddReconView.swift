import SwiftUI
import CoreData
import UIKit

struct AddReconView: View {

    @Environment(\.managedObjectContext)
    private var viewContext

    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject var vehicle: Vehicle

    @State private var category = "Mechanical"
    @State private var details = ""
    @State private var supplier = ""
    @State private var amount = ""
    @State private var invoiceNumber = ""

    @State private var paid = false

    @State private var invoiceImage: UIImage?
    @State private var showingCamera = false

    @State private var showingError = false
    @State private var errorMessage = ""

    private let categories = [
        "Mechanical",
        "Service",
        "Tyres",
        "Bodywork",
        "Paint",
        "Windscreen",
        "Interior",
        "Valet",
        "Roadworthy",
        "Licensing",
        "Transport",
        "Other"
    ]

    var body: some View {

        NavigationStack {

            Form {

                Section("Recon Details") {

                    Picker(
                        "Category",
                        selection: $category
                    ) {

                        ForEach(
                            categories,
                            id: \.self
                        ) { item in

                            Text(item)
                                .tag(item)
                        }
                    }

                    TextField(
                        "Description",
                        text: $details
                    )

                    TextField(
                        "Supplier",
                        text: $supplier
                    )

                    TextField(
                        "Amount",
                        text: $amount
                    )
                    .keyboardType(.decimalPad)

                    TextField(
                        "Invoice Number",
                        text: $invoiceNumber
                    )
                }

                Section("Invoice") {

                    Button {

                        showingCamera = true

                    } label: {

                        Label(
                            invoiceImage == nil
                                ? "Take Photo of Invoice"
                                : "Retake Invoice Photo",
                            systemImage: "camera.fill"
                        )
                    }

                    if let invoiceImage {

                        Image(uiImage: invoiceImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 12
                                )
                            )

                        Button(
                            "Remove Invoice Photo",
                            role: .destructive
                        ) {

                            self.invoiceImage = nil
                        }
                    }
                }

                Section("Payment") {

                    Toggle(
                        "Paid",
                        isOn: $paid
                    )

                    if paid {

                        Label(
                            "Invoice marked as paid",
                            systemImage:
                                "checkmark.circle.fill"
                        )
                        .foregroundStyle(.green)

                    } else {

                        Label(
                            "Payment outstanding",
                            systemImage:
                                "clock.fill"
                        )
                        .foregroundStyle(.orange)
                    }
                }

                Section {

                    HStack {

                        Text("Recon Amount")

                        Spacer()

                        Text(
                            Money.rand(
                                Money.cents(
                                    from: amount
                                )
                            )
                        )
                        .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Add Recon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .confirmationAction
                ) {

                    Button("Save") {
                        saveRecon()
                    }
                    .disabled(
                        Money.cents(
                            from: amount
                        ) <= 0
                    )
                }
            }
            .sheet(
                isPresented: $showingCamera
            ) {

                InvoiceCameraPicker { image in
                    invoiceImage = image
                }
            }
            .alert(
                "Could Not Save Recon",
                isPresented: $showingError
            ) {

                Button(
                    "OK",
                    role: .cancel
                ) {
                }

            } message: {

                Text(errorMessage)
            }
        }
    }

    private func saveRecon() {

        let recon =
            ReconItem(
                context: viewContext
            )

        recon.id = UUID()
        recon.createdAt = Date()

        recon.category =
            category

        recon.details =
            details.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        recon.supplier =
            supplier.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        recon.amountCents =
            Money.cents(
                from: amount
            )

        recon.invoiceNumber =
            invoiceNumber.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        recon.paid = paid

        if let invoiceImage {

            recon.invoiceImageData =
                invoiceImage.jpegData(
                    compressionQuality: 0.75
                )
        }

        recon.vehicle = vehicle

        do {

            try viewContext.save()

            dismiss()

        } catch {

            viewContext.rollback()

            errorMessage =
                error.localizedDescription

            showingError = true

            print(
                "Recon save error:",
                error
            )
        }
    }
}
