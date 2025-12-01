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

            List<race__c> raceToInsert = new List<race__c>();

                    for (Map<String, Object> ds : raceData) {
                        race__c r = new race__c();
                        r.Name   = (String) ds.get('raceName');
                        r.url__c = (String) ds.get('url');
                        //r.round__c = (Integer) ds.get('round');
                         r.round__c = ds.get('round') != null ? Integer.valueOf(String.valueOf(ds.get('round'))) : null;
                        r.season__c =(String) ds.get('season');
                        r.raceNameId__c = (String) ds.get ('raceName');
                
                        String timeStr = (String) ds.get('time'); // Ejemplo: "14:30:00"
                            if (!String.isBlank(timeStr)) {
                                List<String> parts = timeStr.replace('Z','').split(':');
                                Integer hour = Integer.valueOf(parts[0]);
                                Integer minute = Integer.valueOf(parts[1]);
                                Integer second = Integer.valueOf(parts[2]);
                                r.time__c = Time.newInstance(hour, minute, second, 0); // ✔ funciona en todas las versiones
                            }
                        String dateStr = (String) ds.get('date');
                        if (!String.isBlank(dateStr)) {
                            r.date__c = Date.valueOf(dateStr);
                        }

                        raceToInsert.add(r);
                    }

                    if (!raceToInsert.isEmpty()) {
                        Database.insert(raceToInsert, false);
                        System.debug('Registros insertados: ' + raceToInsert.size());
                    }
            // Upsert usando External Id constructorId__c
            Database.UpsertResult[] results = Database.upsert(raceToInsert, race__c.Fields.raceNameId__c, false);

            for (Database.UpsertResult r : results) {
                if (!r.isSuccess()) {
                    System.debug('Error al upsert: ' + r.getErrors()[0].getMessage());
                }
            }

            System.debug('Constructores procesados: ' + raceToInsert.size());
        } catch (Exception e) {
            System.debug('Error en batch: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch finalizado.');
    }
 }