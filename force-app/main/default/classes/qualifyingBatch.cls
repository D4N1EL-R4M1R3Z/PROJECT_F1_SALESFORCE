global class qualifyingBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> qualifyingData = qualifying.giveQualifying();
            System.debug('Cantidad de resultados de clasificación obtenidos: ' + qualifyingData.size());

            List<qualifying__c> qualifyingToUpsert = new List<qualifying__c>();

            for (Map<String, Object> stat : qualifyingData) {
                qualifying__c q = new qualifying__c();

                // Conversión segura para Q1, Q2, Q3
                q.Q1__c = parseQuTime((String) stat.get('Q1'));
                q.Q2__c = parseQuTime((String) stat.get('Q2'));
                q.Q3__c = parseQuTime((String) stat.get('Q3'));

                // Si tienes más campos como driverId, position, etc., agrégalos aquí
                if (stat.containsKey('driverId')) {
                    q.driverId__c = (String) stat.get('driverId');
                }
                if (stat.containsKey('position')) {
                    try {
                        q.position__c = Integer.valueOf(String.valueOf(stat.get('position')));
                    } catch (Exception e) {
                        System.debug('Valor inválido para position: ' + stat.get('position'));
                    }
                }

                qualifyingToUpsert.add(q);
            }

            if (!qualifyingToUpsert.isEmpty()) {
                // Upsert usando driverId__c (ideal si está marcado como External Id)
                Database.UpsertResult[] results = Database.upsert(qualifyingToUpsert, qualifying__c.Fields.driverId__c, false);

                Integer ok = 0; Integer fail = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert Qualifying: ' + r.getErrors()[0].getMessage());
                    }
                }

                System.debug('Resultados de clasificación procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay resultados de clasificación para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Qualifying finalizado.');
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
            System.debug('Formato inválido para tiempo: ' + val);
            return null;
        }
    }
}