global class raceBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> raceData = race.giveRace();
            System.debug('Cantidad de carreras obtenidas: ' + raceData.size());

            List<race__c> racesToUpsert = new List<race__c>();

            for (Map<String, Object> ds : raceData) {
                race__c r = new race__c();

                // Campos básicos
                r.Name   = (String) ds.get('raceName');
                r.url__c = (String) ds.get('url');

                // Conversión segura para fecha
                String dateStr = (String) ds.get('date');
                if (!String.isBlank(dateStr)) {
                    try {
                        r.date__c = Date.valueOf(dateStr);
                    } catch (Exception e) {
                        System.debug('Fecha inválida para race: ' + dateStr);
                    }
                }

                // Si tienes más campos como round, season, circuitId, agrégalos aquí
                if (ds.containsKey('round')) {
                    try {
                        r.round__c = Integer.valueOf(String.valueOf(ds.get('round')));
                    } catch (Exception e) {
                        System.debug('Valor inválido para round: ' + ds.get('round'));
                    }
                }
                /*if (ds.containsKey('season')) {
                    try {
                        r.season__c = Integer.valueOf(String.valueOf(ds.get('season')));
                    } catch (Exception e) {
                        System.debug('Valor inválido para season: ' + ds.get('season'));
                    }
                }*/

                racesToUpsert.add(r);
            }

            if (!racesToUpsert.isEmpty()) {
                // Upsert usando Name (o mejor un campo External Id como raceId__c si lo tienes)
                Database.UpsertResult[] results = Database.upsert(racesToUpsert, race__c.Fields.Name, false);

                Integer ok = 0; Integer fail = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert Race: ' + r.getErrors()[0].getMessage());
                    }
                }

                System.debug('Carreras procesadas. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay carreras para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Race finalizado.');
    }
}