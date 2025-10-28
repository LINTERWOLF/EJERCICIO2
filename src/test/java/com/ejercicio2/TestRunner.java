package com.ejercicio2;

import com.intuit.karate.junit5.Karate;

class TestRunner {

    @Karate.Test
    Karate testAll() {
        // Se ejecutan en orden para garantizar el flujo Token -> Afiliacion -> Desafiliacion.
        return Karate.run(
                "classpath:TokenGeneration.feature",
               // "classpath:Afiliacion.feature"
               // "classpath:Desafiliacion.feature",
               // "classpath:ConsultaCredencial.feature",
               // "classpath:ConsultaCuenta.feature",
                "classpath:Transferencia.feature"
        );

    }

}
