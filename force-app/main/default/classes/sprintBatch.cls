global class sprintBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> sprintData = sprint.givesprint();
            System.debug('Cantidad de sprints obtenidos: ' + sprintData.size());

            List<sprint__c> sprintsToUpsert = new List<sprint__c>();

            for (Map<String, Object> spr : sprintData) {
                sprint__c sp = new sprint__c();

                // Conversión segura para campos numéricos
                sp.number__c = toInteger(spr.get('number'));
                sp.position__c = toInteger(spr.get('position'));
                sp.points__c = toInteger(spr.get('points'));
                sp.laps__c = toInteger(spr.get('laps'));

                // Campos de texto
                sp.status__c = (String) spr.get('status');

                // Conversión segura para tiempos
                sp.finishTime__c = parseSprintTime((String) spr.get('finishTime'));
                sp.fastestLapTime__c = parseSprintTime((String) spr.get('fastestLapTime'));

                sprintsToUpsert.add(sp);
            }

            if (!sprintsToUpsert.isEmpty()) {
                // Upsert usando un identificador único (ideal: sprintId__c marcado como External Id)
                Database.UpsertResult[] results = Database.upsert(sprintsToUpsert, sprint__c.Fields.Name, false);

                Integer ok = 0; Integer fail = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert Sprint: ' + r.getErrors()[0].getMessage());
                    }
                }

                System.debug('Sprints procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay sprints para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Sprint finalizado.');
    }

    // Conversión segura para tiempo en formato mm:ss.ms
    private static Time parseSprintTime(String val) {
        if (String.isBlank(val)) return null;
        try {
            List<String> parts = val.split(':');
            if (parts.size() != 2) return null;

            Integer minutes = Integer.valueOf(parts[0]);
            List<String> secAndMs = parts[1].split('\\.');
            Integer seconds = Integer.valueOf(secAndMs[0]);
            Integer millis = 0; // Salesforce Time no soporta milisegundos

            return Time.newInstance(0, minutes, seconds, millis);
        } catch (Exception e) {
            System.debug('Formato inválido para tiempo: ' + val);
            return null;
        }
    }

    // Conversión segura para Integer
    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try { return Integer.valueOf(String.valueOf(val)); } catch (Exception e) { return null; }
    }
}