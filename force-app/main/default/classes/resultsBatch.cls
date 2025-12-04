// Version con upsert
global class resultsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // 1. Obtener datos desde la API
            List<Map<String, Object>> resultsData = result.giveResults();
            System.debug('Cantidad de resultados obtenidos: ' + resultsData.size());
            
            if (resultsData.isEmpty()) {
                System.debug('No hay resultados para procesar.');
                return;
            }

            // 2. Preparar listas y sets
            List<result__c> resultsToUpsert = new List<result__c>();
            List<Constructor__c> constructorsToUpsert = new List<Constructor__c>();
            List<Driver__c> driversToUpsert = new List<Driver__c>();
            List<Circuit__c> circuitsToUpsert = new List<Circuit__c>();

            Set<String> driverIds = new Set<String>();
            Set<String> constructorIds = new Set<String>();
            Set<String> circuitIds = new Set<String>();

            // 3. Primera pasada: recolectar IDs únicos
            for (Map<String, Object> ds : resultsData) {
                String driverId = normalize((String) ds.get('driverId'));
                String constructorId = normalize((String) ds.get('constructorId'));
                String circuitId = normalize((String) ds.get('circuitId'));

                if (!String.isBlank(driverId)) driverIds.add(driverId);
                if (!String.isBlank(constructorId)) constructorIds.add(constructorId);
                if (!String.isBlank(circuitId)) circuitIds.add(circuitId);
            }

            // 4. Preparar Drivers, Constructors, Circuits para upsert
            Set<String> processedDrivers = new Set<String>();
            Set<String> processedConstructors = new Set<String>();
            Set<String> processedCircuits = new Set<String>();

            for (Map<String, Object> ds : resultsData) {
                String driverId = normalize((String) ds.get('driverId'));
                String constructorId = normalize((String) ds.get('constructorId'));
                String circuitId = normalize((String) ds.get('circuitId'));

                // Driver (solo uno por driverId)
                if (!String.isBlank(driverId) && !processedDrivers.contains(driverId)) {
                    Driver__c d = new Driver__c();
                    d.driverId__c = driverId;
                    d.Name = buildDriverName(ds);
                    d.nationality__c = (String) ds.get('nationality');
                    d.url__c = (String) ds.get('driverUrl');
                    driversToUpsert.add(d);
                    processedDrivers.add(driverId);
                }

                // Constructor (solo uno por constructorId)
                if (!String.isBlank(constructorId) && !processedConstructors.contains(constructorId)) {
                    Constructor__c c = new Constructor__c();
                    c.constructorId__c = constructorId;
                    c.Name = (String) ds.get('constructorName');
                    c.url__c = (String) ds.get('constructorUrl');
                    c.nationality__c = (String) ds.get('constructorNat');
                    constructorsToUpsert.add(c);
                    processedConstructors.add(constructorId);
                }

                // Circuit (solo uno por circuitId)
                if (!String.isBlank(circuitId) && !processedCircuits.contains(circuitId)) {
                    Circuit__c ci = new Circuit__c();
                    ci.circuitId__c = circuitId;
                    ci.Name = (String) ds.get('circuitName');
                    ci.url__c = (String) ds.get('circuitUrl');
                    circuitsToUpsert.add(ci);
                    processedCircuits.add(circuitId);
                }
            }

            // 5. Upsert Drivers, Constructors y Circuits
            if (!driversToUpsert.isEmpty()) {
                Database.upsert(driversToUpsert, Driver__c.Fields.driverId__c, false);
            }
            if (!constructorsToUpsert.isEmpty()) {
                Database.upsert(constructorsToUpsert, Constructor__c.Fields.constructorId__c, false);
            }
            if (!circuitsToUpsert.isEmpty()) {
                Database.upsert(circuitsToUpsert, Circuit__c.Fields.circuitId__c, false);
            }

            // 6. Consultar Ids reales
            Map<String, Id> driverMap = new Map<String, Id>();
            for (Driver__c d : [SELECT Id, driverId__c FROM Driver__c WHERE driverId__c IN :driverIds]) {
                driverMap.put(normalize(d.driverId__c), d.Id);
            }

            Map<String, Id> constructorMap = new Map<String, Id>();
            for (Constructor__c c : [SELECT Id, constructorId__c FROM Constructor__c WHERE constructorId__c IN :constructorIds]) {
                constructorMap.put(normalize(c.constructorId__c), c.Id);
            }

            Map<String, Id> circuitMap = new Map<String, Id>();
            for (Circuit__c ci : [SELECT Id, circuitId__c FROM Circuit__c WHERE circuitId__c IN :circuitIds]) {
                circuitMap.put(normalize(ci.circuitId__c), ci.Id);
            }

            System.debug('driverMap: ' + driverMap);
            System.debug('constructorMap: ' + constructorMap);
            System.debug('circuitMap: ' + circuitMap);

            // 7. Preparar Results con External ID
            for (Map<String, Object> ds : resultsData) {
                String driverId = normalize((String) ds.get('driverId'));
                String constructorId = normalize((String) ds.get('constructorId'));
                String circuitId = normalize((String) ds.get('circuitId'));
                String season = String.valueOf(ds.get('season'));
                String round = String.valueOf(ds.get('round'));

                result__c r = new result__c();
                
                // ========== EXTERNAL ID ÚNICO (NUEVO) ==========
                // Formato: "2024_1_verstappen" (season_round_driverId)
                r.ResultKey__c = season + '_' + round + '_' + driverId;
                
                r.Name = (String) ds.get('raceName');
                r.number__c = toInteger(ds.get('number'));
                r.position__c = toInteger(ds.get('position'));
                r.positionText__c = (String) ds.get('positionText');
                r.points__c = toInteger(ds.get('points'));
                r.grid__c = toInteger(ds.get('grid'));
                r.laps__c = toInteger(ds.get('laps'));
                r.status__c = (String) ds.get('status');
                
                // ========== FASTEST LAP ==========
                Object fastestLapRank = ds.get('fastestLapRank');
                if (fastestLapRank != null && String.valueOf(fastestLapRank) == '1') {
                    r.Fastest_Lap__c = true;
                } else {
                    r.Fastest_Lap__c = false;
                }
                
                // ========== LOOKUPS ==========
                r.Driver__c = driverMap.get(driverId);
                r.Constructor__c = constructorMap.get(constructorId);
                r.Circuit__c = circuitMap.get(circuitId);
                
                resultsToUpsert.add(r);
            }

            // 8. UPSERT Results usando External ID
            if (!resultsToUpsert.isEmpty()) {
                Database.UpsertResult[] results = Database.upsert(resultsToUpsert, result__c.Fields.ResultKey__c, false);
                
                Integer ok = 0, fail = 0;
                for (Database.UpsertResult ur : results) {
                    if (ur.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        for (Database.Error e : ur.getErrors()) {
                            System.debug('Error upsert Result: ' + e.getStatusCode() + ' - ' + e.getMessage());
                        }
                    }
                }
                System.debug('Resultados procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            }

        } catch (Exception e) {
            System.debug('Error en execute: ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Results finalizado.');
    }

    // Helpers
    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try { 
            return Integer.valueOf(String.valueOf(val)); 
        } catch (Exception e) { 
            return null; 
        }
    }

    private static String buildDriverName(Map<String, Object> ds) {
        String given = (String) ds.get('givenName');
        String family = (String) ds.get('familyName');
        String full = ((given != null ? given : '') + ' ' + (family != null ? family : '')).trim();
        return String.isBlank(full) ? (String) ds.get('driverId') : full;
    }

    private static String normalize(String val) {
        return val != null ? val.trim().toLowerCase() : null;
    }
}

// Version sin upsert
// global class resultsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

//     global Iterable<SObject> start(Database.BatchableContext bc) {
//         return new List<SObject>{ new Account() };
//     }

//     global void execute(Database.BatchableContext bc, List<SObject> scope) {
//         try {
//             // 1. Obtener datos desde la API
//             List<Map<String, Object>> resultsData = result.giveResults();
//             System.debug('Cantidad de resultados obtenidos: ' + resultsData.size());
            
//             if (resultsData.isEmpty()) {
//                 System.debug('No hay resultados para procesar.');
//                 return;
//             }

//             // 2. Preparar listas y sets
//             List<result__c> resultsToInsert = new List<result__c>();
//             List<Constructor__c> constructorsToUpsert = new List<Constructor__c>();
//             List<Driver__c> driversToUpsert = new List<Driver__c>();
//             List<Circuit__c> circuitsToUpsert = new List<Circuit__c>();

//             Set<String> driverIds = new Set<String>();
//             Set<String> constructorIds = new Set<String>();
//             Set<String> circuitIds = new Set<String>();

//             // 3. Recorrer datos y preparar objetos
//             for (Map<String, Object> ds : resultsData) {
//                 String driverId = normalize((String) ds.get('driverId'));
//                 String constructorId = normalize((String) ds.get('constructorId'));
//                 String circuitId = normalize((String) ds.get('circuitId'));

//                 if (!String.isBlank(driverId)) driverIds.add(driverId);
//                 if (!String.isBlank(constructorId)) constructorIds.add(constructorId);
//                 if (!String.isBlank(circuitId)) circuitIds.add(circuitId);

//                 // Driver
//                 if (!String.isBlank(driverId)) {
//                     Driver__c d = new Driver__c();
//                     d.driverId__c = driverId;
//                     d.Name = buildDriverName(ds);
//                     d.nationality__c = (String) ds.get('nationality');
//                     d.url__c = (String) ds.get('driverUrl');
//                     driversToUpsert.add(d);
//                 }

//                 // Constructor
//                 if (!String.isBlank(constructorId)) {
//                     Constructor__c c = new Constructor__c();
//                     c.constructorId__c = constructorId;
//                     c.Name = (String) ds.get('constructorName');
//                     c.url__c = (String) ds.get('constructorUrl');
//                     c.nationality__c = (String) ds.get('constructorNat');
//                     constructorsToUpsert.add(c);
//                 }

//                 // Circuit
//                 if (!String.isBlank(circuitId)) {
//                     Circuit__c ci = new Circuit__c();
//                     ci.circuitId__c = circuitId;
//                     ci.Name = (String) ds.get('circuitName');
//                     ci.url__c = (String) ds.get('circuitUrl');
//                     circuitsToUpsert.add(ci);
//                 }

//                 // Result (sin Lookups aún)
//                 result__c r = new result__c();
//                 r.Name = (String) ds.get('raceName');
//                 r.number__c = toInteger(ds.get('number'));
//                 r.position__c = toInteger(ds.get('position'));
//                 r.positionText__c = (String) ds.get('positionText');
//                 r.points__c = toInteger(ds.get('points'));
//                 r.grid__c = toInteger(ds.get('grid'));
//                 r.laps__c = toInteger(ds.get('laps'));
//                 r.status__c = (String) ds.get('status');
                
//                 // ========== FASTEST LAP (NUEVO) ==========
//                 // Si fastestLapRank == "1", significa que este piloto tuvo la vuelta más rápida
//                 Object fastestLapRank = ds.get('fastestLapRank');
//                 if (fastestLapRank != null && String.valueOf(fastestLapRank) == '1') {
//                     r.Fastest_Lap__c = true;
//                 } else {
//                     r.Fastest_Lap__c = false;
//                 }
                
//                 resultsToInsert.add(r);
//             }

//             // 4. Upsert Drivers, Constructors y Circuits
//             if (!driversToUpsert.isEmpty()) {
//                 Database.upsert(driversToUpsert, Driver__c.Fields.driverId__c, false);
//             }
//             if (!constructorsToUpsert.isEmpty()) {
//                 Database.upsert(constructorsToUpsert, Constructor__c.Fields.constructorId__c, false);
//             }
//             if (!circuitsToUpsert.isEmpty()) {
//                 Database.upsert(circuitsToUpsert, Circuit__c.Fields.circuitId__c, false);
//             }

//             // 5. Consultar Ids reales
//             Map<String, Id> driverMap = new Map<String, Id>();
//             for (Driver__c d : [SELECT Id, driverId__c FROM Driver__c WHERE driverId__c IN :driverIds]) {
//                 driverMap.put(normalize(d.driverId__c), d.Id);
//             }

//             Map<String, Id> constructorMap = new Map<String, Id>();
//             for (Constructor__c c : [SELECT Id, constructorId__c FROM Constructor__c WHERE constructorId__c IN :constructorIds]) {
//                 constructorMap.put(normalize(c.constructorId__c), c.Id);
//             }

//             Map<String, Id> circuitMap = new Map<String, Id>();
//             for (Circuit__c ci : [SELECT Id, circuitId__c FROM Circuit__c WHERE circuitId__c IN :circuitIds]) {
//                 circuitMap.put(normalize(ci.circuitId__c), ci.Id);
//             }

//             System.debug('driverMap: ' + driverMap);
//             System.debug('constructorMap: ' + constructorMap);
//             System.debug('circuitMap: ' + circuitMap);

//             // 6. Asignar Lookups
//             Integer index = 0;
//             for (Map<String, Object> ds : resultsData) {
//                 String dId = normalize((String) ds.get('driverId'));
//                 String cId = normalize((String) ds.get('constructorId'));
//                 String ciId = normalize((String) ds.get('circuitId'));

//                 resultsToInsert[index].Driver__c = driverMap.get(dId);
//                 resultsToInsert[index].Constructor__c = constructorMap.get(cId);
//                 resultsToInsert[index].Circuit__c = circuitMap.get(ciId);
//                 index++;
//             }

//             // 7. Insert Results
//             if (!resultsToInsert.isEmpty()) {
//                 Database.SaveResult[] sr = Database.insert(resultsToInsert, false);
//                 Integer ok = 0, fail = 0;
//                 for (Database.SaveResult s : sr) {
//                     if (s.isSuccess()) {
//                         ok++;
//                     } else {
//                         fail++;
//                         for (Database.Error e : s.getErrors()) {
//                             System.debug('Error insert Result: ' + e.getStatusCode() + ' - ' + e.getMessage());
//                         }
//                     }
//                 }
//                 System.debug('Resultados procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
//             }

//         } catch (Exception e) {
//             System.debug('Error en execute: ' + e.getMessage() + ' - ' + e.getStackTraceString());
//         }
//     }

//     global void finish(Database.BatchableContext bc) {
//         System.debug('Batch de Results finalizado.');
//     }

//     // Helpers
//     private static Integer toInteger(Object val) {
//         if (val == null) return null;
//         try { 
//             return Integer.valueOf(String.valueOf(val)); 
//         } catch (Exception e) { 
//             return null; 
//         }
//     }

//     private static String buildDriverName(Map<String, Object> ds) {
//         String given = (String) ds.get('givenName');
//         String family = (String) ds.get('familyName');
//         String full = ((given != null ? given : '') + ' ' + (family != null ? family : '')).trim();
//         return String.isBlank(full) ? (String) ds.get('driverId') : full;
//     }

//     private static String normalize(String val) {
//         return val != null ? val.trim().toLowerCase() : null;
//     }
// }

// CLASE ANTIGUA
// global class resultsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

//     global Iterable<SObject> start(Database.BatchableContext bc) {
//         // Dummy record para que el batch siempre se ejecute
//         return new List<SObject>{ new Account() };
//     }

//     global void execute(Database.BatchableContext bc, List<SObject> scope) {
//         try {
//             // 1. Obtener datos desde la API
//             List<Map<String, Object>> resultsData = result.giveResults();
//             System.debug('Cantidad de resultados obtenidos: ' + resultsData.size());
//             if (resultsData.isEmpty()) {
//                 System.debug('No hay resultados para procesar.');
//                 return;
//             }

//             // 2. Preparar listas y sets
//             List<result__c> resultsToInsert = new List<result__c>();
//             List<Constructor__c> constructorsToUpsert = new List<Constructor__c>();
//             List<Driver__c> driversToUpsert = new List<Driver__c>();
//             List<Circuit__c> circuitsToUpsert = new List<Circuit__c>();

//             Set<String> driverIds = new Set<String>();
//             Set<String> constructorIds = new Set<String>();
//             Set<String> circuitIds = new Set<String>();

//             // 3. Recorrer datos y preparar objetos
//             for (Map<String, Object> ds : resultsData) {
//                 String driverId = normalize((String) ds.get('driverId'));
//                 String constructorId = normalize((String) ds.get('constructorId'));
//                 String circuitId = normalize((String) ds.get('circuitId'));

//                 if (!String.isBlank(driverId)) driverIds.add(driverId);
//                 if (!String.isBlank(constructorId)) constructorIds.add(constructorId);
//                 if (!String.isBlank(circuitId)) circuitIds.add(circuitId);

//                 // Driver
//                 if (!String.isBlank(driverId)) {
//                     Driver__c d = new Driver__c();
//                     d.driverId__c = driverId;
//                     d.Name = buildDriverName(ds);
//                     d.nationality__c = (String) ds.get('nationality');
//                     d.url__c = (String) ds.get('driverUrl');
//                     driversToUpsert.add(d);
//                 }

//                 // Constructor
//                 if (!String.isBlank(constructorId)) {
//                     Constructor__c c = new Constructor__c();
//                     c.constructorId__c = constructorId;
//                     c.Name = (String) ds.get('constructorName');
//                     c.url__c = (String) ds.get('constructorUrl');
//                     c.nationality__c = (String) ds.get('constructorNat');
//                     constructorsToUpsert.add(c);
//                 }

//                 // Circuit
//                 if (!String.isBlank(circuitId)) {
//                     Circuit__c ci = new Circuit__c();
//                     ci.circuitId__c = circuitId;
//                     ci.Name = (String) ds.get('circuitName');
//                     ci.url__c = (String) ds.get('circuitUrl');
//                     circuitsToUpsert.add(ci);
//                 }

//                 // Result (sin Lookups aún)
//                 result__c r = new result__c();
//                 r.Name = (String) ds.get('raceName');
//                 r.number__c = toInteger(ds.get('number'));
//                 r.position__c = toInteger(ds.get('position'));
//                 r.positionText__c = (String) ds.get('positionText');
//                 r.points__c = toInteger(ds.get('points'));
//                 r.grid__c = toInteger(ds.get('grid'));
//                 r.laps__c = toInteger(ds.get('laps'));
//                 r.status__c = (String) ds.get('status');
//                 resultsToInsert.add(r);
//             }

//             // 4. Upsert Drivers, Constructors y Circuits
//             if (!driversToUpsert.isEmpty()) Database.upsert(driversToUpsert, Driver__c.Fields.driverId__c, false);
//             if (!constructorsToUpsert.isEmpty()) Database.upsert(constructorsToUpsert, Constructor__c.Fields.constructorId__c, false);
//             if (!circuitsToUpsert.isEmpty()) Database.upsert(circuitsToUpsert, Circuit__c.Fields.circuitId__c, false);

//             // 5. Consultar Ids reales
//             Map<String, Id> driverMap = new Map<String, Id>();
//             for (Driver__c d : [SELECT Id, driverId__c FROM Driver__c WHERE driverId__c IN :driverIds]) {
//                 driverMap.put(normalize(d.driverId__c), d.Id);
//             }

//             Map<String, Id> constructorMap = new Map<String, Id>();
//             for (Constructor__c c : [SELECT Id, constructorId__c FROM Constructor__c WHERE constructorId__c IN :constructorIds]) {
//                 constructorMap.put(normalize(c.constructorId__c), c.Id);
//             }

//             Map<String, Id> circuitMap = new Map<String, Id>();
//             for (Circuit__c ci : [SELECT Id, circuitId__c FROM Circuit__c WHERE circuitId__c IN :circuitIds]) {
//                 circuitMap.put(normalize(ci.circuitId__c), ci.Id);
//             }

//             System.debug('driverMap: ' + driverMap);
//             System.debug('constructorMap: ' + constructorMap);
//             System.debug('circuitMap: ' + circuitMap);

//             // 6. Asignar Lookups
//             Integer index = 0;
//             for (Map<String, Object> ds : resultsData) {
//                 String dId = normalize((String) ds.get('driverId'));
//                 String cId = normalize((String) ds.get('constructorId'));
//                 String ciId = normalize((String) ds.get('circuitId'));

//                 resultsToInsert[index].Driver__c = driverMap.get(dId);
//                 resultsToInsert[index].Constructor__c = constructorMap.get(cId);
//                 resultsToInsert[index].Circuit__c = circuitMap.get(ciId);
//                 index++;
//             }

//             // 7. Insert Results
//             if (!resultsToInsert.isEmpty()) {
//                 Database.SaveResult[] sr = Database.insert(resultsToInsert, false);
//                 Integer ok = 0, fail = 0;
//                 for (Database.SaveResult s : sr) {
//                     if (s.isSuccess()) ok++;
//                     else {
//                         fail++;
//                         for (Database.Error e : s.getErrors()) {
//                             System.debug('Error insert Result: ' + e.getStatusCode() + ' - ' + e.getMessage());
//                         }
//                     }
//                 }
//                 System.debug('Resultados procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
//             }

//         } catch (Exception e) {
//             System.debug('Error en execute: ' + e.getMessage());
//         }
//     }

//     global void finish(Database.BatchableContext bc) {
//         System.debug('Batch de Results finalizado.');
//     }

//     // Helpers
//     private static Integer toInteger(Object val) {
//         if (val == null) return null;
//         try { return Integer.valueOf(String.valueOf(val)); } catch (Exception e) { return null; }
//     }

//     private static String buildDriverName(Map<String, Object> ds) {
//         String given = (String) ds.get('givenName');
//         String family = (String) ds.get('familyName');
//         String full = ((given != null ? given : '') + ' ' + (family != null ? family : '')).trim();
//         return String.isBlank(full) ? (String) ds.get('driverId') : full;
//     }

//     private static String normalize(String val) {
//         return val != null ? val.trim().toLowerCase() : null;
//     }
// }