global class driverstadingBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> standings = driverstanding.obtenerClasificacion();
            System.debug('Cantidad de driver standings obtenidos: ' + standings.size());

            List<driverstanding__c> driversToInsert = new List<driverstanding__c>();
                    for (Map<String,Object> ds : standings) {
                        driverstanding__c d = new driverstanding__c();
                        d.Name = (String) ds.get('givenName') + ' ' + (String) ds.get('familyName');
                       // d.driverId__c = (String) ds.get('driverId');
                        d.givenName__c = (String) ds.get('givenName');
                        d.familyName__c = (String) ds.get('familyName');
                        d.dateOfBirth__c = ds.get('dateOfBirth') != null ? Date.valueOf((String) ds.get('dateOfBirth')) : null;
                        d.nationality__c = (String) ds.get('nationality');
                        d.url__c = (String) ds.get('url');
                        d.code__c = (String) ds.get('code');
                        d.permanentNumber__c = ds.get('permanentNumber') != null ? Integer.valueOf(String.valueOf(ds.get('permanentNumber'))) : null;
                        driversToInsert.add(d);
                    }
         
            if (!driversToInsert.isEmpty()) {
                // Upsert usando External Id driverId__c
                Database.UpsertResult[] results = Database.upsert(driversToInsert, driverstanding__c.Fields.driverId__c, false);

                Integer ok = 0; Integer fail = 0;
               for (Database.UpsertResult d : results) {
                if (!d.isSuccess()) {
                    System.debug('Error al upsert: ' + d.getErrors()[0].getMessage());
                }
            }

                System.debug('Driver standings procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay driver standings para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Driver Standings finalizado.');
    }
}