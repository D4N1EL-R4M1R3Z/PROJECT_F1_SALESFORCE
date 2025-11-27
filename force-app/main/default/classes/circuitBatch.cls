global class circuitBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            List<Map<String, Object>> circuitsData = circuit.giveCircuits();
            System.debug('Cantidad de circuitos obtenidos: ' + circuitsData.size());

            List<circuit__c> circuitsToUpsert = new List<circuit__c>();

            for (Map<String, Object> ds : circuitsData) {
                circuit__c c = new circuit__c();
                c.Name = (String) ds.get('circuitName'); // Usamos Name como etiqueta
                c.circuitId__c = (String) ds.get('circuitId'); // External Id
                c.url__c = (String) ds.get('url');

                // Conversión segura para lat/long
                if (ds.get('lat') != null) {
                    c.Location__Latitude__s = Decimal.valueOf(String.valueOf(ds.get('lat')));
                }
                if (ds.get('long') != null) {
                    c.Location__Longitude__s = Decimal.valueOf(String.valueOf(ds.get('long')));
                }

                c.locality__c = (String) ds.get('locality');
                c.country__c = (String) ds.get('country');

                circuitsToUpsert.add(c);
            }

            // ✅ Upsert usando External Id circuitId__c (evita duplicados)
            if (!circuitsToUpsert.isEmpty()) {
                Database.UpsertResult[] results = Database.upsert(circuitsToUpsert, circuit__c.Fields.circuitId__c, false);

                Integer successCount = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        successCount++;
                    } else {
                        System.debug('Error al upsert: ' + r.getErrors()[0].getMessage());
                    }
                }
                System.debug('Circuitos procesados: ' + successCount);
            } else {
                System.debug('No se encontraron circuitos para procesar.');
            }
        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch finalizado.');
    }
}