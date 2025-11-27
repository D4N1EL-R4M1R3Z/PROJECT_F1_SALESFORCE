global class statusBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la fuente (tu método existente)
            List<Map<String, Object>> statusData = status.giveStatus();
            System.debug('Cantidad de status obtenidos: ' + statusData.size());

            List<status__c> statusesToUpsert = new List<status__c>();

            for (Map<String, Object> stat : statusData) {
                status__c s = new status__c();

                // Conversión segura
                s.statusId__c = toInteger(stat.get('statusId'));
                s.status__c   = (String) stat.get('status');

                // (Opcional) Si tienes más campos en el objeto status__c, mapealos aquí

                statusesToUpsert.add(s);
            }

            if (!statusesToUpsert.isEmpty()) {
                // Upsert usando el External Id statusId__c (recomendado marcarlo como External Id y Unique)
                Database.UpsertResult[] results = Database.upsert(statusesToUpsert, status__c.Fields.statusId__c, false);

                Integer ok = 0, fail = 0;
                for (Database.UpsertResult ur : results) {
                    if (ur.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        Database.Error err = ur.getErrors()[0];
                        System.debug('Error al upsert Status: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
                System.debug('Status procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay status para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch (execute): ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Status finalizado.');
    }

    // Helpers de conversión segura
    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try {
            return Integer.valueOf(String.valueOf(val));
        } catch (Exception e) {
            return null;
        }
    }
}