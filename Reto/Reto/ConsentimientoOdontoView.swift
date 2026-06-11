import SwiftUI
import WebKit

// MARK: - WebView

struct ConsentimientoWebView: UIViewRepresentable {
    let html: String
    var onWebViewCreated: ((WKWebView) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let wv = WKWebView()
        wv.scrollView.showsVerticalScrollIndicator = false
        onWebViewCreated?(wv)
        return wv
    }

    func updateUIView(_ wv: WKWebView, context: Context) {
        wv.loadHTMLString(html, baseURL: nil)
    }
}

// MARK: - Vista principal (2 pasos: formulario → documento)

struct ConsentimientoOdontoView: View {
    // Datos pre-llenados desde la consulta
    let nombrePaciente: String
    let fechaNacimiento: Date
    let medico: String
    let municipio: String
    var diagnosticoInicial: String = ""
    var motivoInicial: String = ""
    var esOperacionInicial: Bool? = nil
    var riesgosInicial: String = ""
    var pronosticoInicial: String = ""
    var tipoActoInicial: String = ""
    // Si true, salta el formulario y muestra el documento directamente
    var omitirFormulario: Bool = false

    // Callback para que el llamador guarde la ruta del PDF en la Consulta
    var onPDFGuardado: ((String) -> Void)?

    @Environment(\.dismiss) private var dismiss

    // Paso 0 = formulario, paso 1 = documento
    @State private var paso = 0

    // Campos del formulario
    @State private var diagnostico: String = ""
    @State private var esOperacion: Bool? = nil
    @State private var riesgos: String = ""
    @State private var pronostico: String = ""      // "Bueno" | "Malo" | "Reservado"
    @State private var tipoActo: String = ""        // "Urgente" | "De riesgo" | "No urgente"

    // Documento
    @State private var webView: WKWebView?
    @State private var mostrarShare = false
    @State private var pdfURL: URL?

    private var puedeGenerar: Bool { !diagnostico.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if paso == 0 {
                    formularioView
                } else {
                    documentoView
                }
            }
            .navigationTitle(paso == 0 ? "Datos del consentimiento" : "Consentimiento – Dental")
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
            diagnostico  = diagnosticoInicial
            esOperacion  = esOperacionInicial
            riesgos      = riesgosInicial
            pronostico   = pronosticoInicial
            tipoActo     = tipoActoInicial
            if omitirFormulario { paso = 1 }
        }
        .sheet(isPresented: $mostrarShare) {
            if let url = pdfURL { ShareSheet(items: [url]) }
        }
    }

    // MARK: - Formulario previo

    private var formularioView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                campoTextoForm("Diagnóstico *", texto: $diagnostico, multilinea: true)

                // ¿Operación bucal?
                VStack(alignment: .leading, spacing: 8) {
                    Text("¿Es una operación bucal / procedimiento invasivo?")
                        .font(.caption).foregroundStyle(Color.caritasGris)
                    HStack(spacing: 10) {
                        botonOpcion("Sí", seleccionado: esOperacion == true)  { esOperacion = true }
                        botonOpcion("No", seleccionado: esOperacion == false) { esOperacion = false }
                    }
                }

                if esOperacion == true {
                    campoTextoForm("Riesgos del procedimiento (opcional)", texto: $riesgos, multilinea: true)
                }

                // Pronóstico
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pronóstico")
                        .font(.caption).foregroundStyle(Color.caritasGris)
                    HStack(spacing: 10) {
                        botonOpcion("Bueno",     seleccionado: pronostico == "Bueno")     { pronostico = "Bueno" }
                        botonOpcion("Malo",      seleccionado: pronostico == "Malo")      { pronostico = "Malo" }
                        botonOpcion("Reservado", seleccionado: pronostico == "Reservado") { pronostico = "Reservado" }
                    }
                }

                // Tipo de acto
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tipo de acto odontológico")
                        .font(.caption).foregroundStyle(Color.caritasGris)
                    HStack(spacing: 10) {
                        botonOpcion("Urgente",    seleccionado: tipoActo == "Urgente")    { tipoActo = "Urgente" }
                        botonOpcion("De riesgo",  seleccionado: tipoActo == "De riesgo")  { tipoActo = "De riesgo" }
                        botonOpcion("No urgente", seleccionado: tipoActo == "No urgente") { tipoActo = "No urgente" }
                    }
                }

                Button {
                    paso = 1
                } label: {
                    Text("Ver consentimiento →")
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

    // MARK: - Documento HTML

    private var documentoView: some View {
        ConsentimientoWebView(html: htmlRelleno) { wv in
            webView = wv
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Generación de HTML

    private var htmlRelleno: String {
        guard let url = Bundle.main.url(forResource: "consentimiento_odonto", withExtension: "html"),
              let base = try? String(contentsOf: url, encoding: .utf8)
        else { return "<p>Error al cargar el documento.</p>" }

        let cal = Calendar.current
        let mesesES = ["enero","febrero","marzo","abril","mayo","junio",
                       "julio","agosto","septiembre","octubre","noviembre","diciembre"]

        let hoy      = Date()
        let nacDia   = String(cal.component(.day,   from: fechaNacimiento))
        let nacMes   = mesesES[cal.component(.month, from: fechaNacimiento) - 1]
        let nacAno   = String(cal.component(.year,  from: fechaNacimiento))
        let firmaDia = String(cal.component(.day,   from: hoy))
        let firmaMes = mesesES[cal.component(.month, from: hoy) - 1]
        let firmaAno = String(format: "%02d", cal.component(.year, from: hoy) % 100)

        let dotSelected = "background:#236e80; transform:scale(1.4);"
        let dotUnselected = ""

        let dBueno     = pronostico == "Bueno"     ? dotSelected : dotUnselected
        let dMalo      = pronostico == "Malo"      ? dotSelected : dotUnselected
        let dReservado = pronostico == "Reservado" ? dotSelected : dotUnselected
        let dUrgente   = tipoActo  == "Urgente"    ? dotSelected : dotUnselected
        let dRiesgo    = tipoActo  == "De riesgo"  ? dotSelected : dotUnselected
        let dNoUrgente = tipoActo  == "No urgente" ? dotSelected : dotUnselected

        let procedimientoFill = motivoInicial.isEmpty
            ? (esOperacion == true ? "Operación bucal / procedimiento invasivo" : "Consulta dental")
            : esc(motivoInicial)

        let js = """
        <script>
        window.onload = function() {
          // Arreglar overflow: quitar height fijo en spans rellenos
          document.querySelectorAll('.fl').forEach(function(el) {
            el.style.height = 'auto';
            el.style.minHeight = '14px';
          });

          function fill(id, val) {
            var el = document.getElementById(id);
            if (!el) return;
            el.textContent = val;
            el.style.color = '#236e80';
            el.style.fontWeight = 'bold';
            el.style.height = 'auto';
          }
          function dot(id, style) {
            var el = document.getElementById(id);
            if (el && style) el.setAttribute('style', el.getAttribute('style') || '' + ';' + style);
          }

          fill('f-nombre',        '\(esc(nombrePaciente))');
          fill('f-nac-dia',       '\(esc(nacDia))');
          fill('f-nac-mes',       '\(esc(nacMes))');
          fill('f-nac-ano',       '\(esc(nacAno))');
          fill('f-medico',        '\(esc(medico))');
          fill('f-medico2',       '\(esc(medico))');
          fill('f-procedimiento', '\(procedimientoFill)');
          fill('f-diagnostico',   '\(esc(diagnostico))');
          fill('f-municipio',     '\(esc(municipio))');
          fill('f-firma-dia',     '\(esc(firmaDia))');
          fill('f-firma-mes',     '\(esc(firmaMes))');
          fill('f-firma-ano',     '\(esc(firmaAno))');

          dot('d-bueno',     '\(dBueno)');
          dot('d-malo',      '\(dMalo)');
          dot('d-reservado', '\(dReservado)');
          dot('d-urgente',   '\(dUrgente)');
          dot('d-riesgo',    '\(dRiesgo)');
          dot('d-no-urgente','\(dNoUrgente)');

          \(riesgos.isEmpty ? "" : "fill('f-riesgos', '\(esc(riesgos))');")
        };
        </script>
        """

        return base.replacingOccurrences(of: "</head>", with: "\(js)</head>")
    }

    // MARK: - PDF

    private func exportarPDF(guardar: Bool) {
        guard let wv = webView else { return }
        let config = WKPDFConfiguration()
        wv.createPDF(configuration: config) { result in
            guard case .success(let data) = result else { return }
            let nombre = "ConsentimientoOdonto_\(nombrePaciente)_\(Int(Date().timeIntervalSince1970)).pdf"
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
        info.jobName = "Consentimiento Dental – \(nombrePaciente)"
        let printer = UIPrintInteractionController.shared
        printer.printInfo = info
        printer.printFormatter = wv.viewPrintFormatter()
        printer.present(animated: true)
    }

    // MARK: - Helpers de UI

    private func campoTextoForm(_ titulo: String, texto: Binding<String>, multilinea: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo).font(.caption).foregroundStyle(Color.caritasGris)
            if multilinea {
                TextField(titulo, text: texto, axis: .vertical)
                    .lineLimit(2...5)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                TextField(titulo, text: texto)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func botonOpcion(_ label: String, seleccionado: Bool, accion: @escaping () -> Void) -> some View {
        Button(action: accion) {
            Text(label)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(seleccionado ? Color.caritasSuave : Color(.systemGray6))
                .foregroundStyle(seleccionado ? Color.caritasPrimario : Color.caritasAzul)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(seleccionado ? Color.caritasPrimario : Color.clear, lineWidth: 1))
        }
    }

    private func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "'", with: "\\'")
         .replacingOccurrences(of: "\n", with: " ")
    }
}
