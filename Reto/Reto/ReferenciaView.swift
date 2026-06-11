import SwiftUI
import WebKit

// MARK: - Vista carta de referencia

struct ReferenciaView: View {
    let nombrePaciente: String
    let fechaNacimiento: Date
    let medico: String
    let motivoInicial: String

    // Pre-rellenado desde el wizard; si omitirFormulario=true salta al documento
    var institucionInicial: String = ""
    var omitirFormulario: Bool = false

    var onPDFGuardado: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var paso = 0          // 0 = form, 1 = doc
    @State private var institucion = ""
    @State private var webView: WKWebView?
    @State private var mostrarShare = false
    @State private var pdfURL: URL?

    private var puedeGenerar: Bool { !institucion.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if paso == 0 { formularioView } else { documentoView }
            }
            .navigationTitle(paso == 0 ? "Carta de referencia" : "Referencia – \(nombrePaciente)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if paso == 0 {
                        Button("Cancelar") { dismiss() }
                    } else {
                        Button("← Atrás") { paso = 0 }
                    }
                }
                if paso == 1 {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button { exportarPDF(guardar: true) } label: {
                                Label("Guardar en expediente", systemImage: "square.and.arrow.down")
                            }
                            Button { exportarPDF(guardar: false) } label: {
                                Label("Compartir PDF", systemImage: "square.and.arrow.up")
                            }
                            Button { imprimirDocumento() } label: {
                                Label("Imprimir", systemImage: "printer")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
        .onAppear {
            institucion = institucionInicial
            if omitirFormulario { paso = 1 }
        }
        .sheet(isPresented: $mostrarShare) {
            if let url = pdfURL { ShareSheet(items: [url]) }
        }
    }

    // MARK: - Formulario

    private var formularioView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Institución / Especialidad a referir *")
                        .font(.caption).foregroundStyle(Color.caritasGris)
                    TextField("Ej: Hospital General, Cardiología...", text: $institucion)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.subheadline)
                }

                if !motivoInicial.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Motivo de referencia")
                            .font(.caption).foregroundStyle(Color.caritasGris)
                        Text(motivoInicial)
                            .font(.subheadline)
                            .foregroundStyle(Color.caritasAzul)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Button {
                    paso = 1
                } label: {
                    Text("Ver carta →")
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(puedeGenerar ? Color.caritasPrimario : Color.caritasGris)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!puedeGenerar)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .colorScheme(.light)
    }

    // MARK: - Documento

    private var documentoView: some View {
        ConsentimientoWebView(html: htmlRelleno) { wv in
            webView = wv
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - HTML

    private var htmlRelleno: String {
        guard let url = Bundle.main.url(forResource: "referencia_paciente", withExtension: "html"),
              let base = try? String(contentsOf: url, encoding: .utf8)
        else { return "<p>Error al cargar el documento.</p>" }

        let cal = Calendar.current
        let mesesES = ["enero","febrero","marzo","abril","mayo","junio",
                       "julio","agosto","septiembre","octubre","noviembre","diciembre"]
        let hoy = Date()
        let dia  = String(cal.component(.day,   from: hoy))
        let mes  = mesesES[cal.component(.month, from: hoy) - 1]
        let ano  = String(cal.component(.year,  from: hoy))

        let edadAnos = cal.dateComponents([.year], from: fechaNacimiento, to: hoy).year ?? 0

        let js = """
        <script>
        window.onload = function() {
          document.querySelectorAll('.fl, .grow, .small-line').forEach(function(el) {
            el.style.height = 'auto';
            el.style.minHeight = '12px';
          });
          function fill(id, val) {
            var el = document.getElementById(id);
            if (!el || !val) return;
            el.textContent = val;
            el.style.color = '#236e80';
            el.style.fontWeight = 'bold';
          }
          fill('r-dia',        '\(esc(dia))');
          fill('r-mes',        '\(esc(mes))');
          fill('r-ano',        '\(esc(ano))');
          fill('r-nombre',     '\(esc(nombrePaciente))');
          fill('r-edad',       '\(edadAnos) años');
          fill('r-motivo',     '\(esc(motivoInicial))');
          fill('r-institucion','\(esc(institucion))');
          fill('r-medico',     '\(esc(medico))');
        };
        </script>
        """

        return base.replacingOccurrences(of: "</head>", with: "\(js)</head>")
    }

    // MARK: - PDF

    private func exportarPDF(guardar: Bool) {
        guard let wv = webView else { return }
        wv.createPDF(configuration: WKPDFConfiguration()) { result in
            guard case .success(let data) = result else { return }
            let nombre = "Referencia_\(nombrePaciente)_\(Int(Date().timeIntervalSince1970)).pdf"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(nombre)
            try? data.write(to: url)
            pdfURL = url
            if guardar {
                onPDFGuardado?(nombre)
            } else {
                mostrarShare = true
            }
        }
    }

    private func imprimirDocumento() {
        guard let wv = webView else { return }
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = "Referencia – \(nombrePaciente)"
        let printer = UIPrintInteractionController.shared
        printer.printInfo = info
        printer.printFormatter = wv.viewPrintFormatter()
        printer.present(animated: true)
    }

    private func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "'", with: "\\'")
         .replacingOccurrences(of: "\n", with: " ")
    }
}
