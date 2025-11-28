global class resultsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Llamamos al método que obtiene los datos desde la API
            List<Map<String, Object>> resultsData = result.giveResults();
            System.debug('Cantidad de resultados obtenidos: ' + resultsData.size());

            List<result__c> resultsToInsert = new List<result__c>();
            List<Constructor__c> constructorsToInsert = new List<Constructor__c>();
            List<driver__c> driversToInsert = new List<driver__c>();

            for (Map<String, Object> ds : resultsData) {
            result__c r = new result__c();
            driver__c d = new driver__c();
            Constructor__c c = new Constructor__c();
            r.number__c        = toInteger(ds.get('number'));
            r.position__c      = toInteger(ds.get('position'));
            r.positionText__c  = (String) ds.get('positionText');
            r.points__c        = toInteger(ds.get('points'));
            r.grid__c          = toInteger(ds.get('grid'));
            r.laps__c          = toInteger(ds.get('laps'));
            r.status__c        = (String) ds.get('status');
            r.driver__c      = (String) ds.get('driverId');
            r.Name           = (String) ds.get('raceName');
            r.constructor__c = (String) ds.get('constructorId');
          



            resultsToInsert.add(r);
            constructorsToInsert.add(c);
            driversToInsert.add(d);
        }

            if (!resultsToInsert.isEmpty()) {
                // Inserción parcial (continúa aunque algunos registros fallen)
                Database.SaveResult[] sr = Database.insert(resultsToInsert, false);

                Integer ok = 0, fail = 0;
                for (Database.SaveResult s : sr) {
                    if (s.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        Database.Error e = s.getErrors()[0];
                        System.debug('Error al insertar Result: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    }
                }
                System.debug('Resultados procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay resultados para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en execute: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Results finalizado.');
    }

    // Helper seguro para conversión
    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try { return Integer.valueOf(String.valueOf(val)); } catch (Exception e) { return null; }
    }
}