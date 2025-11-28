global class driverBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> driverData =  driver.givenDriver();
            System.debug('Cantidad de constructores obtenidos: ' + driverData.size());

            List<Driver__c> driversToInsert = new List<Driver__c>();
            Map<String, String> driverConstructorMap = driver.getDriverConstructorMap();
                 for (Map<String,Object> ds : driverData) {
                            Driver__c d = new Driver__c();
                            d.Name = (String) ds.get('givenName') + ' ' + (String) ds.get('familyName');
                            d.driverId__c = (String) ds.get('driverId');
                            d.givenName__c = (String) ds.get('givenName');
                            d.familyName__c = (String) ds.get('familyName');
                            d.dateOfBirth__c = ds.get('dateOfBirth') != null ? Date.valueOf((DATE) ds.get('dateOfBirth')) : null;
                            d.nationality__c = (String) ds.get('nationality');
                            d.url__c = (String) ds.get('url');
                            d.code__c = (String) ds.get('code');
                            d.permanentNumber__c = ds.get('permanentNumber') != null ? Integer.valueOf(String.valueOf(ds.get('permanentNumber'))) : null;

                            String driverId = (String) ds.get('driverId');
                            if (driverConstructorMap.containsKey(driverId)) {
                                d.constructor__c = driverConstructorMap.get(driverId); // Si tu campo es TEXT
                            }
                      
                            driversToInsert.add(d);
                        }

            // Upsert usando External Id constructorId__c
            Database.UpsertResult[] results = Database.upsert(driversToInsert, Driver__c.Fields.driverId__c, false);

            for (Database.UpsertResult r : results) {
                if (!r.isSuccess()) {
                    System.debug('Error al upsert: ' + r.getErrors()[0].getMessage());
                }
            }

            System.debug('Constructores procesados: ' + driversToInsert.size());
        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch finalizado.');
    }
}