global class seasonBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> seasonData = season.giveSeason();
            System.debug('Cantidad de temporadas obtenidas: ' + seasonData.size());

            List<season__c> seasonsToUpsert = new List<season__c>();

            for (Map<String, Object> ls : seasonData) {
                season__c s = new season__c();

                // URL
                s.url__c = (String) ls.get('url');

                // Conversión segura para season
                Object seasonObj = ls.get('season');
                if (seasonObj != null) {
                    try {
                        s.season__c = Integer.valueOf(String.valueOf(seasonObj));
                    } catch (Exception e) {
                        System.debug('Valor inválido para season: ' + seasonObj);
                    }
                }

                seasonsToUpsert.add(s);
            }

            if (!seasonsToUpsert.isEmpty()) {
                // Upsert usando season__c como External Id (recomendado marcarlo como tal)
                Database.UpsertResult[] results = Database.upsert(seasonsToUpsert, season__c.Fields.season__c, false);

                Integer ok = 0; Integer fail = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        System.debug('Error al upsert Season: ' + r.getErrors()[0].getMessage());
                    }
                }

                System.debug('Temporadas procesadas. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay temporadas para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Season finalizado.');
    }
}