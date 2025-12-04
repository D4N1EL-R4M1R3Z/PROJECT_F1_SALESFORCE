global class driverstadingBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // 1. Obtener datos desde la API
            List<Map<String, Object>> standings = driverstanding.obtenerClasificacion();
            System.debug('Cantidad de driver standings obtenidos: ' + standings.size());

            if (standings.isEmpty()) {
                System.debug('No hay driver standings para procesar.');
                return;
            }

            // 2. Preparar listas
            List<driverstanding__c> standingsToInsert = new List<driverstanding__c>();
            List<Driver__c> driversToUpdate = new List<Driver__c>();
            Set<String> constructorIds = new Set<String>();

            // 3. Extraer constructorIds para buscar los Ids reales
            for (Map<String, Object> ds : standings) {
                // La API de driverstandings trae Constructors como lista
                List<Object> constructors = (List<Object>) ds.get('Constructors');
                if (constructors != null && !constructors.isEmpty()) {
                    Map<String, Object> firstConstructor = (Map<String, Object>) constructors[0];
                    String constructorId = (String) firstConstructor.get('constructorId');
                    if (String.isNotBlank(constructorId)) {
                        constructorIds.add(constructorId.trim().toLowerCase());
                    }
                }
            }

            // 4. Consultar Constructor__c para obtener Ids reales (para el Lookup)
            Map<String, Id> constructorMap = new Map<String, Id>();
            if (!constructorIds.isEmpty()) {
                for (Constructor__c c : [SELECT Id, constructorId__c FROM Constructor__c WHERE constructorId__c IN :constructorIds]) {
                    constructorMap.put(c.constructorId__c.trim().toLowerCase(), c.Id);
                }
            }
            System.debug('constructorMap: ' + constructorMap);

            // 5. Procesar cada registro
            for (Map<String, Object> ds : standings) {
                String driverId = (String) ds.get('driverId');
                
                // ========== CREAR REGISTRO EN driverstanding__c ==========
                driverstanding__c standing = new driverstanding__c();
                standing.Name = (String) ds.get('givenName') + ' ' + (String) ds.get('familyName');
                standing.driverId__c = driverId;
                standing.givenName__c = (String) ds.get('givenName');
                standing.familyName__c = (String) ds.get('familyName');
                standing.dateOfBirth__c = ds.get('dateOfBirth') != null ? Date.valueOf((String) ds.get('dateOfBirth')) : null;
                standing.nationality__c = (String) ds.get('nationality');
                standing.url__c = (String) ds.get('url');
                standing.code__c = (String) ds.get('code');
                standing.permanentNumber__c = toInteger(ds.get('permanentNumber'));
                standing.position__c = toInteger(ds.get('position'));
                standing.points__c = toInteger(ds.get('points'));
                standing.wins__c = toInteger(ds.get('wins'));
                
                standingsToInsert.add(standing);

                // ========== ACTUALIZAR Driver__c CON WINS, POINTS Y CONSTRUCTOR ==========
                Driver__c driver = new Driver__c();
                driver.driverId__c = driverId; // External ID para upsert
                
                // Campos nuevos
                driver.Wins__c = toInteger(ds.get('wins'));
                driver.Total_Points__c = toInteger(ds.get('points'));
                
                // Constructor Lookup - buscar el Id real
                List<Object> constructors = (List<Object>) ds.get('Constructors');
                if (constructors != null && !constructors.isEmpty()) {
                    Map<String, Object> firstConstructor = (Map<String, Object>) constructors[0];
                    String constructorId = (String) firstConstructor.get('constructorId');
                    if (String.isNotBlank(constructorId)) {
                        Id constructorSfId = constructorMap.get(constructorId.trim().toLowerCase());
                        if (constructorSfId != null) {
                            driver.Constructor__c = constructorSfId;
                        }
                    }
                }
                
                driversToUpdate.add(driver);
            }

            // 6. Upsert driverstanding__c
            if (!standingsToInsert.isEmpty()) {
                Database.UpsertResult[] standingResults = Database.upsert(standingsToInsert, driverstanding__c.Fields.driverId__c, false);
                
                Integer ok = 0, fail = 0;
                for (Database.UpsertResult r : standingResults) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert driverstanding: ' + r.getErrors()[0].getMessage());
                    }
                }
                System.debug('Driver standings procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            }

            // 7. Upsert Driver__c (actualizar Wins, Points, Constructor)
            if (!driversToUpdate.isEmpty()) {
                Database.UpsertResult[] driverResults = Database.upsert(driversToUpdate, Driver__c.Fields.driverId__c, false);
                
                Integer ok = 0, fail = 0;
                for (Database.UpsertResult r : driverResults) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al actualizar Driver: ' + r.getErrors()[0].getMessage());
                    }
                }
                System.debug('Drivers actualizados con Wins/Points/Constructor. Éxitos: ' + ok + ', Fallos: ' + fail);
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Driver Standings finalizado.');
    }

    // Helper para conversión segura
    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try {
            return Integer.valueOf(String.valueOf(val));
        } catch (Exception e) {
            return null;
        }
    }
}

// global class driverstadingBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

//     global Iterable<SObject> start(Database.BatchableContext bc) {
//         // Dummy record para que el batch siempre se ejecute
//         return new List<SObject>{ new Account() };
//     }

//     global void execute(Database.BatchableContext bc, List<SObject> scope) {
//         try {
//             // Obtener datos desde la API
//             List<Map<String, Object>> standings = driverstanding.obtenerClasificacion();
//             System.debug('Cantidad de driver standings obtenidos: ' + standings.size());

//             List<driverstanding__c> driversToInsert = new List<driverstanding__c>();
//                     for (Map<String,Object> ds : standings) {
//                         driverstanding__c d = new driverstanding__c();
//                         d.Name = (String) ds.get('givenName') + ' ' + (String) ds.get('familyName');
//                        // d.driverId__c = (String) ds.get('driverId');
//                         d.givenName__c = (String) ds.get('givenName');
//                         d.familyName__c = (String) ds.get('familyName');
//                         d.dateOfBirth__c = ds.get('dateOfBirth') != null ? Date.valueOf((String) ds.get('dateOfBirth')) : null;
//                         d.nationality__c = (String) ds.get('nationality');
//                         d.url__c = (String) ds.get('url');
//                         d.code__c = (String) ds.get('code');
//                         d.permanentNumber__c = ds.get('permanentNumber') != null ? Integer.valueOf(String.valueOf(ds.get('permanentNumber'))) : null;
//                         driversToInsert.add(d);
//                     }
         
//             if (!driversToInsert.isEmpty()) {
//                 // Upsert usando External Id driverId__c
//                 Database.UpsertResult[] results = Database.upsert(driversToInsert, driverstanding__c.Fields.driverId__c, false);

//                 Integer ok = 0; Integer fail = 0;
//                for (Database.UpsertResult d : results) {
//                 if (!d.isSuccess()) {
//                     System.debug('Error al upsert: ' + d.getErrors()[0].getMessage());
//                 }
//             }

//                 System.debug('Driver standings procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
//             } else {
//                 System.debug('No hay driver standings para procesar.');
//             }

//         } catch (Exception e) {
//             System.debug('Error en batch: ' + e.getMessage());
//         }
//     }

//     global void finish(Database.BatchableContext bc) {
//         System.debug('Batch de Driver Standings finalizado.');
//     }
// }