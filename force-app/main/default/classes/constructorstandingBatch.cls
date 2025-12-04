global class constructorstandingBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // 1. Obtener datos desde la API
            List<Map<String, Object>> constructorStandingData = constructorStanding.givenconstructorstanding();
            System.debug('Cantidad de constructor standings obtenidos: ' + constructorStandingData.size());

            if (constructorStandingData.isEmpty()) {
                System.debug('No hay constructor standings para procesar.');
                return;
            }

            // 2. Preparar listas
            List<constructorstanding__c> standingsToUpsert = new List<constructorstanding__c>();
            List<Constructor__c> constructorsToUpdate = new List<Constructor__c>();

            // 3. Procesar cada registro
            for (Map<String, Object> cons : constructorStandingData) {
                String constructorId = (String) cons.get('constructorId');
                
                // ========== CREAR REGISTRO EN constructorstanding__c ==========
                constructorstanding__c constStad = new constructorstanding__c();
                constStad.Name = (String) cons.get('name');
                constStad.constructorId__c = constructorId;
                constStad.url__c = (String) cons.get('url');
                constStad.nationality__c = (String) cons.get('nationality');
                constStad.positionText__c = toInteger(cons.get('positionText'));
                constStad.position__c = toInteger(cons.get('position'));
                constStad.points__c = toInteger(cons.get('points'));
                constStad.wins__c = String.valueOf(cons.get('wins')); // Si es String en tu objeto
                constStad.season__c = toInteger(cons.get('season'));
                constStad.round__c = toInteger(cons.get('round'));
                
                standingsToUpsert.add(constStad);

                // ========== ACTUALIZAR Constructor__c CON WINS Y POINTS ==========
                Constructor__c constructor = new Constructor__c();
                constructor.constructorId__c = constructorId; // External ID para upsert
                
                // Campos nuevos
                constructor.Wins__c = toInteger(cons.get('wins'));
                constructor.Total_Points__c = toInteger(cons.get('points'));
                
                constructorsToUpdate.add(constructor);
            }

            // 4. Upsert constructorstanding__c
            if (!standingsToUpsert.isEmpty()) {
                Database.UpsertResult[] standingResults = Database.upsert(standingsToUpsert, constructorstanding__c.Fields.constructorId__c, false);
                
                Integer ok = 0, fail = 0;
                for (Database.UpsertResult r : standingResults) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert constructorstanding: ' + r.getErrors()[0].getMessage());
                    }
                }
                System.debug('Constructor standings procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            }

            // 5. Upsert Constructor__c (actualizar Wins y Points)
            if (!constructorsToUpdate.isEmpty()) {
                Database.UpsertResult[] constructorResults = Database.upsert(constructorsToUpdate, Constructor__c.Fields.constructorId__c, false);
                
                Integer ok = 0, fail = 0;
                for (Database.UpsertResult r : constructorResults) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al actualizar Constructor: ' + r.getErrors()[0].getMessage());
                    }
                }
                System.debug('Constructors actualizados con Wins/Points. Éxitos: ' + ok + ', Fallos: ' + fail);
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Constructor Standings finalizado.');
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

// global class constructorstandingBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

//     global Iterable<SObject> start(Database.BatchableContext bc) {
//         // Dummy record para que el batch siempre se ejecute
//         return new List<SObject>{ new Account() };
//     }

//     global void execute(Database.BatchableContext bc, List<SObject> scope) {
//         try {
//             // Obtener datos desde la API
//             List<Map<String, Object>> constructorStandingData = constructorStanding.givenconstructorstanding();
//             System.debug('Cantidad de constructor standings obtenidos: ' + constructorStandingData.size());

//             List<constructorstanding__c> standingsToUpsert = new List<constructorstanding__c>();
                    
//                     for (Map<String,Object> cons : constructorStandingData) {
//                         constructorstanding__c constStad = new constructorstanding__c();
//                         constStad.Name = (String) cons.get('name');
//                         constStad.constructorId__c = (String) cons.get('constructorId');
//                         constStad.url__c = (String) cons.get('url'); 
//                         constStad.Name = (String) cons.get('name');
//                         constStad.nationality__c = (String) cons.get('nationality');
//                         constStad.positionText__c = cons.get('positionText') != null ? Integer.valueOf(String.valueOf(cons.get('positionText'))) : null;
//                         constStad.position__c = cons.get('position') != null ? Integer.valueOf(String.valueOf(cons.get('position'))) : null;    
//                         constStad.points__c = cons.get('points') != null ? Integer.valueOf(String.valueOf(cons.get('points'))) : null;
//                         //constStad.positionText__c = (Integer) cons.get('positionText');
//                         //constStad.position__c = (Integer) cons.get('position');
//                         //constStad.points__c = (Integer) cons.get('points');
//                         constStad.wins__c = (String) cons.get('wins');
//                         constStad.season__c = cons.get('season') != null ? Integer.valueOf(String.valueOf(cons.get('season'))) : null;    
//                          constStad.round__c = cons.get('round') != null ? Integer.valueOf(String.valueOf(cons.get('round'))) : null;
//                         //constStad.season__c = (Integer) cons.get('season');
//                         //constStad.round__c = (Integer) cons.get('round');
//                         standingsToUpsert.add(constStad);
//                     }

//             // Upsert usando External Id constructorId__c
//             Database.UpsertResult[] results = Database.upsert(standingsToUpsert, constructorstanding__c.Fields.constructorId__c, false);

//             for (Database.UpsertResult r : results) {
//                 if (!r.isSuccess()) {
//                     System.debug('Error al upsert: ' + r.getErrors()[0].getMessage());
//                 }
//             }

//             System.debug('Constructor standings procesados: ' + standingsToUpsert.size());
//         } catch (Exception e) {
//             System.debug('Error en batch: ' + e.getMessage());
//         }
//     }

//     global void finish(Database.BatchableContext bc) {
//         System.debug('Batch finalizado.');
//     }
// }