//
//  AccountView.swift
//  RoadmapSwift
//
//  Created by MMJ on 09/10/26.
//

import SwiftUI


// 🟢 Tu primera pantalla en SwiftUI, vive dentro de UIKit gracias a UIHostingController (paso4)
struct AccountView: View {
    // Datos que recibe de afuera (como los parametros de un init)
    let email: String
    let appInfo: AppInfo
    // La vista NO sabe cerrar sesión: solo avisa (igual que onLikeTapped) de la celda)
    let onLogout: () -> Void

    // 🟢 AppStorage: lee y escribe UserDefaults y REDIBUJA la vist cuando cambia
    // = true es el valor por defecto mientras el usuario no lo haya cambiado
    @AppStorage(AppSettingsKey.autoplayVideos) private var autoplayVideos = true

    // @State: estado privado de la vista. Se está mostrando la confirmación
    @State private var isConfirmingLogout = false
    
    var body: some View {
        // 🟢 NavigationStack (iOS 16+) 🟤 Antes: NavigationView(deprecado)
        NavigationStack {
            Form{
                Section("Sesión"){
                    LabeledContent("Correo", value: email)
                }
                
                Section("Preferencias"){
                    // $autoplayVideos es un Binding: la fila puede LEER y ESCRIBIR el valor del padre
                    SettingToggleRow(
                        title: "Reproducir videos automáticamente",
                        systemImage: "play.circle",
                        isOn: $autoplayVideos
                    )
                }
                
                Section("Acerca de"){
                    LabeledContent("Versión", value: appInfo.versionText)
                    // if let en lugar de !: aunque sabemos que la URL es valida, no forzamos
                    if let website = URL(string: "https://nexo.app"){
                        Link("Sitio web de Nexo", destination: website)
                    }
                        
                }
                
                Section{
                    Button("Cerrar sesión", role: .destructive){
                        isConfirmingLogout = true
                    }
                }
                    
            }
            .navigationTitle("Cuenta")
            // El dialogo se muestra mientras isConfirmingLogout sea true; SwiftUI lo regresa a false al cerrarlo
            .confirmationDialog("¿Cerrar sesión?", isPresented: $isConfirmingLogout, titleVisibility: .visible) {
                Button("Cerrar sesión", role: .destructive, action: onLogout)
            }
        }
        
    }
}

// Una fila reutilizable @Binding NO es dueña del valor, lo es quien se lo pasa
private struct SettingToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: systemImage)
        }
    }
}

#Preview {
    AccountView(email: "ana@nexo.app", appInfo: AppInfo(version: "1.0", build: "1"), onLogout: {})
}
