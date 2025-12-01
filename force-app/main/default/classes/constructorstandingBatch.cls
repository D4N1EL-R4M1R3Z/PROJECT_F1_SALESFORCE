global class constructorstandingBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // Obtener datos desde la API
            List<Map<String, Object>> constructorStandingData = constructorStanding.givenconstructorstanding();
            System.debug('Cantidad de constructor standings obtenidos: ' + constructorStandingData.size());

            List<constructorstanding__c> standingsToUpsert = new List<constructorstanding__c>();
                    
                    for (Map<String,Object> cons : constructorStandingData) {
                        constructorstanding__c constStad = new constructorstanding__c();
                        constStad.Name = (String) cons.get('name');
                        constStad.constructorId__c = (String) cons.get('constructorId');
                        constStad.url__c = (String) cons.get('url'); 
                        constStad.Name = (String) cons.get('name');
                        constStad.nationality__c = (String) cons.get('nationality');
                        constStad.positionText__c = cons.get('positionText') != null ? Integer.valueOf(String.valueOf(cons.get('positionText'))) : null;
                        constStad.position__c = cons.get('position') != null ? Integer.valueOf(String.valueOf(cons.get('position'))) : null;    
                        constStad.points__c = cons.get('points') != null ? Integer.valueOf(String.valueOf(cons.get('points'))) : null;
                        //constStad.positionText__c = (Integer) cons.get('positionText');
                        //constStad.position__c = (Integer) cons.get('position');
                        //constStad.points__c = (Integer) cons.get('points');
                        constStad.wins__c = (String) cons.get('wins');
                        constStad.season__c = cons.get('season') != null ? Integer.valueOf(String.valueOf(cons.get('season'))) : null;    
                         constStad.round__c = cons.get('round') != null ? Integer.valueOf(String.valueOf(cons.get('round'))) : null;
                        //constStad.season__c = (Integer) cons.get('season');
                        //constStad.round__c = (Integer) cons.get('round');
                        standingsToUpsert.add(constStad);
                    }

            // Upsert usando External Id constructorId__c
            Database.UpsertResult[] results = Database.upsert(standingsToUpsert, constructorstanding__c.Fields.constructorId__c, false);

            for (Database.UpsertResult r : results) {
                if (!r.isSuccess()) {
                    System.debug('Error al upsert: ' + r.getErrors()[0].getMessage());
                }
            }

            System.debug('Constructor standings procesados: ' + standingsToUpsert.size());
        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch finalizado.');
    }
}