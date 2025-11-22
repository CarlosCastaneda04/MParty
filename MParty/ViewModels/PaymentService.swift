//
//  PaymentService.swift
//  MParty
//
//  Created by Carlos Castaneda on 15/11/25.
//

import Foundation
import Combine

class PaymentService: ObservableObject {
    @Published var isProcessing = false
    @Published var paymentStatus: String?
    
    // Simula un cobro con tarjeta
    func processPayment(amount: Double, cardLast4: String) async -> Bool {
        
        // 1. Actualizamos la UI en el Hilo Principal
        await MainActor.run {
            isProcessing = true
        }
        
        // 2. Simulamos espera de red (esto corre en segundo plano)
        try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        
        // 3. Volvemos al Hilo Principal para terminar
        await MainActor.run {
            isProcessing = false
        }
        
        // Aquí podrías poner lógica de fallo, por ahora siempre es exitoso
        return true
    }
}
