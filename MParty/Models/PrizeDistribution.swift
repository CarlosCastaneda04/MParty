//
//  PrizeDistribution.swift
//  MParty
//
//  Created by Carlos Castaneda on 15/11/25.
//

import Foundation

struct PrizeDistribution {
    let entryFee: Double
    let maxPlayers: Int = 10 // Fijo para torneos de pago según tu regla
    
    var totalPot: Double {
        return entryFee * Double(maxPlayers)
    }
    
    // Porcentajes aproximados a tu lógica
    var appFee: Double { return totalPot * 0.17 }      // 17%
    var hostProfit: Double { return totalPot * 0.33 }  // 33%
    var firstPrize: Double { return totalPot * 0.24 }  // 24%
    var secondPrize: Double { return totalPot * 0.16 } // 16%
    var thirdPrize: Double { return totalPot * 0.10 }  // 10%
}
