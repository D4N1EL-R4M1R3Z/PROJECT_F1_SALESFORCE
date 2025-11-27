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

            List<driverstanding__c> standingsToUpsert = new List<driverstanding__c>();

            for (Map<String, Object> ds : standings) {
                driverstanding__c d = new driverstanding__c();

                // Nombre compuesto
                String givenName = (String) ds.get('givenName');
                String familyName = (String) ds.get('familyName');
                d.Name = (givenName != null ? givenName : '') + ' ' + (familyName != null ? familyName : '');

                // Campos base
                d.driverId__c      = (String) ds.get('driverId');
                d.givenName__c     = givenName;
                d.familyName__c    = familyName;
                d.nationality__c   = (String) ds.get('nationality');
                d.url__c           = (String) ds.get('url');
                d.code__c          = (String) ds.get('code');

                // dateOfBirth: conversión segura
                Object dobObj = ds.get('dateOfBirth');
                if (dobObj != null) {
                    try {
                        d.dateOfBirth__c = Date.valueOf(String.valueOf(dobObj));
                    } catch (Exception pe) {
                        System.debug('Fecha inválida para driverId ' + d.driverId__c + ': ' + dobObj);
                    }
                }

                // permanentNumber: conversión segura
                Object permObj = ds.get('permanentNumber');
                if (permObj != null) {
                    try {
                        d.permanentNumber__c = Integer.valueOf(String.valueOf(permObj));
                    } catch (Exception ne) {
                        System.debug('Número inválido para driverId ' + d.driverId__c + ': ' + permObj);
                    }
                }

                standingsToUpsert.add(d);
            }

            if (!standingsToUpsert.isEmpty()) {
                // Upsert usando External Id driverId__c
                Database.UpsertResult[] results = Database.upsert(standingsToUpsert, driverstanding__c.Fields.driverId__c, false);

                Integer ok = 0; Integer fail = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert Driver Standing: ' + r.getErrors()[0].getMessage());
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