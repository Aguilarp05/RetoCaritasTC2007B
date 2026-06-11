import SwiftUI
import UIKit
import PDFKit

// MARK: - Share sheet nativa

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Generador de PDF

@MainActor
func generarURLPDF<V: View>(_ vista: V, nombre: String) -> URL? {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(nombre).pdf")

    let renderer = ImageRenderer(content: vista.colorScheme(.light))
    renderer.proposedSize = ProposedViewSize(width: 595, height: nil)

    renderer.render { size, draw in
        var box = CGRect(origin: .zero, size: size)
        guard
            let consumer = CGDataConsumer(url: url as CFURL),
            let ctx = CGContext(consumer: consumer, mediaBox: &box, nil)
        else { return }
        ctx.beginPDFPage(nil)
        draw(ctx)
        ctx.endPDFPage()
        ctx.closePDF()
    }
    return url
}

// MARK: - Encabezado compartido para PDFs

struct PDFHeaderView: View {
    let titulo: String
    let subtitulo: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Image("LogoCaritas")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                Spacer()
                Text(Date().formatted(.dateTime.day().month(.wide).year()))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.caritasGris)
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.caritasPrimario)
                .frame(height: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(titulo)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.caritasAzul)
                Text(subtitulo)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.caritasGris)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.caritasSuave.opacity(0.4))

            Rectangle()
                .fill(Color(.systemGray4))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Sección con título para PDFs

struct PDFSectionView<Content: View>: View {
    let titulo: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titulo.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(Color.caritasGris)
                .kerning(1)
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 10)

            content()

            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Visor de PDF (usado en aviso de privacidad y consentimientos)

struct PDFKitView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = PDFDocument(url: url)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    func updateUIView(_ uiView: PDFView, context: Context) {}
}
