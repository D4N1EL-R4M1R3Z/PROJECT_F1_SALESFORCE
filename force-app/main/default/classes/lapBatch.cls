global class lapBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> lapData = lap.giveLap();
            System.debug('Cantidad de laps obtenidos: ' + lapData.size());

            List<lap__c> lapsToUpsert = new List<lap__c>();

            for (Map<String, Object> ls : lapData) {
                lap__c l = new lap__c();

                // Nombre: si no viene en el API, usar driverId + lapNumber
                String driverId = (String) ls.get('driverId');
                String lapNumber = String.valueOf(ls.get('lapNumber'));
                l.Name = (String) ls.get('Name') != null ? (String) ls.get('Name') : driverId + ' - Lap ' + lapNumber;

                // position
                Object posObj = ls.get('position');
                if (posObj != null) {
                    try {
                        l.position__c = Integer.valueOf(String.valueOf(posObj));
                    } catch (Exception e) {
                        System.debug('Valor inválido para position: ' + posObj);
                    }
                }

                // time
                String timeVal = (String) ls.get('time');
                l.time__c = parseQuTime(timeVal);

                lapsToUpsert.add(l);
            }

            if (!lapsToUpsert.isEmpty()) {
                // Upsert usando Name (o mejor un campo External Id si lo tienes)
                Database.UpsertResult[] results = Database.upsert(lapsToUpsert, lap__c.Fields.Name, false);

                Integer ok = 0; Integer fail = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert Lap: ' + r.getErrors()[0].getMessage());
                    }
                }

                System.debug('Laps procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay laps para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Laps finalizado.');
    }

    // Conversión de tiempo en formato mm:ss.ms a Time
    private static Time parseQuTime(String val) {
        if (String.isBlank(val)) return null;

        try {
            List<String> minAndRest = val.split(':');
            if (minAndRest.size() != 2) return null;

            Integer minutes = Integer.valueOf(minAndRest[0]);

            List<String> secAndMs = minAndRest[1].split('\\.');
            Integer seconds = Integer.valueOf(secAndMs[0]);
            Integer millis = 0; // Salesforce Time no soporta milisegundos

            return Time.newInstance(0, minutes, seconds, millis);
        } catch (Exception e) {
            System.debug('Formato inválido para time: ' + val);
            return null;
        }
    }
}