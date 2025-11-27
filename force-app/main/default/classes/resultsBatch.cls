global class resultsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> resultsData = result.giveResults();
            System.debug('Cantidad de resultados obtenidos: ' + resultsData.size());

            List<result__c> resultsToUpsert = new List<result__c>();

            for (Map<String, Object> ds : resultsData) {
                result__c r = new result__c();

                // Conversión segura usando helpers
                r.number__c       = toInteger(ds.get('number'));
                r.position__c     = toDecimal(ds.get('position'));
                r.positionText__c = (String) ds.get('positionText');
                r.points__c       = toInteger(ds.get('points'));
                r.grid__c         = toInteger(ds.get('grid'));
                r.laps__c         = toInteger(ds.get('laps'));
                r.status__c       = (String) ds.get('status');

                resultsToUpsert.add(r);
            }

            if (!resultsToUpsert.isEmpty()) {
                // Upsert usando un campo único (ideal: driverId + raceId o resultId__c marcado como External Id)
                Database.UpsertResult[] results = Database.upsert(resultsToUpsert, result__c.Fields.Name, false);

                Integer ok = 0; Integer fail = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert Result: ' + r.getErrors()[0].getMessage());
                    }
                }

                System.debug('Resultados procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay resultados para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Results finalizado.');
    }

    // Helpers para conversión segura
    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try { return Integer.valueOf(String.valueOf(val)); } catch (Exception e) { return null; }
    }

    private static Decimal toDecimal(Object val) {
        if (val == null) return null;
        try { return Decimal.valueOf(String.valueOf(val)); } catch (Exception e) { return null; }
    }
}