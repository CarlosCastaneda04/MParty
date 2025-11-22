//
//  SelectWinnersView.swift
//  MParty
//
//  Created by Carlos Castaneda on 14/11/25.
//

import SwiftUI

struct SelectWinnersView: View {
    let participants: [Participant]
    var onFinish: (Participant, Participant?, Participant?) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var firstPlace: Participant?
    @State private var secondPlace: Participant?
    @State private var thirdPlace: Participant?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Selecciona a los ganadores")) {
                    // 1er Lugar
                    Picker("🥇 1er Lugar (+100 XP)", selection: $firstPlace) {
                        Text("Seleccionar...").tag(nil as Participant?)
                        ForEach(participants) { p in
                            Text(p.displayName).tag(p as Participant?)
                        }
                    }
                    
                    // 2do Lugar
                    Picker("🥈 2do Lugar (+75 XP)", selection: $secondPlace) {
                        Text("Seleccionar...").tag(nil as Participant?)
                        ForEach(participants) { p in
                            Text(p.displayName).tag(p as Participant?)
                        }
                    }
                    
                    // 3er Lugar
                    Picker("🥉 3er Lugar (+50 XP)", selection: $thirdPlace) {
                        Text("Seleccionar...").tag(nil as Participant?)
                        ForEach(participants) { p in
                            Text(p.displayName).tag(p as Participant?)
                        }
                    }
                }
                
                Section {
                    Button("Confirmar y Finalizar Torneo") {
                        if let winner = firstPlace {
                            onFinish(winner, secondPlace, thirdPlace)
                            dismiss()
                        }
                    }
                    .disabled(firstPlace == nil) // El 1ero es obligatorio
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(firstPlace == nil ? .gray : .red)
                }
            }
            .navigationTitle("Finalizar Torneo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
