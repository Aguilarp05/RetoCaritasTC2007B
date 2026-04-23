import SwiftUI

struct NuevoPacienteView: View {
    
    @State private var primerNombre     = ""
    @State private var segundoNombre    = ""
    @State private var primerApellido   = ""
    @State private var segundoApellido  = ""
    @State private var curp             = ""
    @State private var notas            = ""
    @State private var lugarNacimiento  = ""
    @State private var fechaNacimiento  = Date()
    @State private var sexo             = Sexo.noDefinido
        
    
    var body: some View {
        Text("Formulario Nuevo Paciente")
    }
}
#Preview {}
