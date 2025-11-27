global class pitstopBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> lapData = pitstop.givepitstop();
            System.debug('Cantidad de pit stops obtenidos: ' + lapData.size());

            List<pitstop__c> pitstopToUpsert = new List<pitstop__c>();

            for (Map<String, Object> ps : lapData) {
                pitstop__c p = new pitstop__c();

                p.Name = (String) ps.get('Name');

                // Conversión segura para lap y stop
                Object lapObj = ps.get('lap');
                if (lapObj != null) {
                    try {
                        p.lap__c = Integer.valueOf(String.valueOf(lapObj));
                    } catch (Exception e) {
                        System.debug('Valor inválido para lap: ' + lapObj);
                    }
                }

                Object stopObj = ps.get('stop');
                if (stopObj != null) {
                    try {
                        p.stop__c = Integer.valueOf(String.valueOf(stopObj));
                    } catch (Exception e) {
                        System.debug('Valor inválido para stop: ' + stopObj);
                    }
                }

                // Conversión segura para time
                String timeVal = (String) ps.get('time');
                p.time__c = parseQuTime(timeVal);

                // Conversión segura para duration
                Object durationObj = ps.get('durationduration'); // Verifica si el key correcto es 'duration' o 'durationduration'
                if (durationObj != null) {
                    try {
                        p.duration__c = Decimal.valueOf(String.valueOf(durationObj));
                    } catch (Exception e) {
                        System.debug('Valor inválido para duration: ' + durationObj);
                    }
                }

                pitstopToUpsert.add(p);
            }

            if (!pitstopToUpsert.isEmpty()) {
                // Upsert usando Name como identificador (o crea un External Id si lo tienes)
                Database.UpsertResult[] results = Database.upsert(pitstopToUpsert, pitstop__c.Fields.Name, false);

                Integer ok = 0; Integer fail = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert Pit Stop: ' + r.getErrors()[0].getMessage());
                    }
                }

                System.debug('Pit Stops procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay pit stops para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Pit Stops finalizado.');
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
            Integer millis = 0; // Salesforce Time no soporta milisegundos, se ignora

            return Time.newInstance(0, minutes, seconds, millis);
        } catch (Exception e) {
            System.debug('Formato inválido para time: ' + val);
            return null;
        }
    }
}