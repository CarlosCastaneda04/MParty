//
//  SecurePasswordView.swift
//  MParty
//
//  Created by user285805 on 7/11/25.
//

import SwiftUI

struct SecurePasswordView: View {
    // 1. Un 'Binding' para conectar el texto con la Vista que lo usa
    @Binding var passwordText: String
    
    // 2. Un 'State' INTERNO para controlar la visibilidad
    @State private var isPasswordVisible: Bool = false
    
    let title: String // El texto "Contraseña" o "Confirmar"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                // 3. Cambia entre SecureField y TextField
                if isPasswordVisible {
                    TextField(title, text: $passwordText)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                } else {
                    SecureField(title, text: $passwordText)
                }
                
                // 4. El botón del "ojito"
                Button {
                    isPasswordVisible.toggle() // Cambia el estado
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}
