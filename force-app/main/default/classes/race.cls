public with sharing class race {

    /**
     * Obtiene las carreras desde la API y devuelve una lista de mapas.
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveRace() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2025/races.json'); // Named Credential
            req.setMethod('GET');

            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonMap   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> mrData    = (Map<String, Object>) jsonMap.get('MRData');
                Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
                List<Object> racesList        = (List<Object>) raceTable.get('Races');

                for (Object obj : racesList) {
                    Map<String, Object> race = (Map<String, Object>) obj;

                    Map<String, Object> row = new Map<String, Object>();
                    row.put('raceName', race.get('raceName'));
                    row.put('url',      race.get('url'));
                    row.put('date',     race.get('date')); // "2025-03-16"
                    row.put('time',     race.get('time')); // "04:00:00Z"

                    // Prácticas y Qualifying
                    Map<String, Object> fp = (Map<String, Object>) race.get('FirstPractice');
                    Map<String, Object> sp = (Map<String, Object>) race.get('SecondPractice');
                    Map<String, Object> tp = (Map<String, Object>) race.get('ThirdPractice');
                    Map<String, Object> q  = (Map<String, Object>) race.get('Qualifying');

                    if (fp != null) {
                        row.put('firstPracticeDate', fp.get('date'));
                        row.put('firstPracticeTime', fp.get('time'));
                    }
                    if (sp != null) {
                        row.put('secondPracticeDate', sp.get('date'));
                        row.put('secondPracticeTime', sp.get('time'));
                    }
                    if (tp != null) {
                        row.put('thirdPracticeDate', tp.get('date'));
                        row.put('thirdPracticeTime', tp.get('time'));
                    }
                    if (q != null) {
                        row.put('qualifyingDate', q.get('date'));
                        row.put('qualifyingTime', q.get('time'));
                    }

                    result.add(row);
                }
            } else {
                System.debug('Error en la llamada HTTP: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Excepción en obtenerRace: ' + e.getMessage());
        }

        return result;
    }

    /**
     * Guarda las carreras en Salesforce.
     */
    
        
                @AuraEnabled
                public static void saveRace() {
                    List<Map<String, Object>> raceData = giveRace();
                    List<race__c> raceToInsert = new List<race__c>();

                    for (Map<String, Object> ds : raceData) {
                        race__c r = new race__c();
                        r.Name   = (String) ds.get('raceName');
                        r.url__c = (String) ds.get('url');

                        // Fecha (campo tipo Date)
                        String dateStr = (String) ds.get('date'); // "2025-03-16"
                        if (!String.isBlank(dateStr)) {
                            r.date__c = Date.valueOf(dateStr);
                        }

                        // Hora (campo tipo Time)
                        /*String timeStr = (String) ds.get('time'); // "04:00:00Z" o "04:00:00.123Z"
                        Time apiTime = TimeUtil.parseApiTimeToTime(timeStr);
                        if (apiTime != null) {
                            r.time__c = apiTime;
                        } else {
                            // opcional: log o manejo si viene en blanco/invalid
                            System.debug('Hora inválida para registro: ' + timeStr);*
                        }*/

                        raceToInsert.add(r);
                    }

                    if (!raceToInsert.isEmpty()) {
                        Database.insert(raceToInsert, false);
                        System.debug('Registros insertados: ' + raceToInsert.size());
                    }
                }


}