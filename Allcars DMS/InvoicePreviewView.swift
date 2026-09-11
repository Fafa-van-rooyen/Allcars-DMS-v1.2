import SwiftUI
import PDFKit

struct InvoicePreviewView: View {

    @Environment(\.dismiss)
    private var dismiss

    let invoiceURL: URL
    let documentTitle: String

    init(
        invoiceURL: URL,
        documentTitle: String = "Tax Invoice"
    ) {
        self.invoiceURL = invoiceURL
        self.documentTitle = documentTitle
    }

    @State private var showingShareSheet = false

    var body: some View {

        NavigationStack {

            PDFDocumentView(
                url: invoiceURL
            )
            .ignoresSafeArea(
                edges: .bottom
            )
            .navigationTitle(documentTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(
                    placement: .cancellationAction
                ) {

                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(
                    placement: .primaryAction
                ) {

                    Button {

                        showingShareSheet = true

                    } label: {

                        Label(
                            "Share",
                            systemImage:
                                "square.and.arrow.up"
                        )
                    }
                }
            }
            .sheet(
                isPresented: $showingShareSheet
            ) {

                ActivityView(
                    activityItems: [
                        invoiceURL
                    ]
                )
            }
        }
    }
}

// MARK: - PDF Viewer

private struct PDFDocumentView:
    UIViewRepresentable {

    let url: URL

    func makeUIView(
        context: Context
    ) -> PDFView {

        let pdfView = PDFView()

        pdfView.autoScales = true

        pdfView.displayMode =
            .singlePageContinuous

        pdfView.displayDirection =
            .vertical

        pdfView.backgroundColor =
            UIColor.systemGroupedBackground

        if let document =
            PDFDocument(url: url) {

            pdfView.document =
                document
        }

        return pdfView
    }

    func updateUIView(
        _ pdfView: PDFView,
        context: Context
    ) {

        if pdfView.document?.documentURL
            != url {

            pdfView.document =
                PDFDocument(url: url)
        }
    }
}

// MARK: - Share Sheet

private struct ActivityView:
    UIViewControllerRepresentable {

    let activityItems: [Any]

    func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {

        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController:
            UIActivityViewController,
        context: Context
    ) {}
}//
//  InvoicePreviewView.swift
//  Allcars DMS
//
//  Created by Fafa Van Rooyen on 2026/08/25.
//
