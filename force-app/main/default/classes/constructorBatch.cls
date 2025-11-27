global class constructorBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> constructorData =  constructor.givenConstructors();
            System.debug('Cantidad de constructores obtenidos: ' + constructorData.size());

            List<constructor__c> constructorsToUpsert = new List<constructor__c>();

            for (Map<String, Object> cons : constructorData) {
                constructor__c constObj = new constructor__c();
                constObj.Name = (String) cons.get('name');
                constObj.constructorId__c = (String) cons.get('constructorId');
                constObj.url__c = (String) cons.get('url');
                constObj.name__c = (String) cons.get('name');
                constObj.nationality__c = (String) cons.get('nationality');

                constructorsToUpsert.add(constObj);
            }

            // Upsert usando External Id constructorId__c
            Database.UpsertResult[] results = Database.upsert(constructorsToUpsert, constructor__c.Fields.constructorId__c, false);

            for (Database.UpsertResult r : results) {
                if (!r.isSuccess()) {
                    System.debug('Error al upsert: ' + r.getErrors()[0].getMessage());
                }
            }

            System.debug('Constructores procesados: ' + constructorsToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch finalizado.');
    }
}