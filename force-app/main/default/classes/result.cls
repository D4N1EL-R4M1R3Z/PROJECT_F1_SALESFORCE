public with sharing class result {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveResults() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2025/results.json'); // Ajusta Named Credential
            req.setMethod('GET');

            HttpResponse res = http.send(req);
            
            
if (res.getStatusCode() == 200) {
    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
    Map<String, Object> mrData = (Map<String, Object>) jsonMap.get('MRData');
    Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
    List<Object> racesList = (List<Object>) raceTable.get('Races');

    for (Object raceObj : racesList) {
        Map<String, Object> raceMap = (Map<String, Object>) raceObj;

        // Datos del Race
        Object season       = raceMap.get('season');
        Object round        = raceMap.get('round');
        Object raceUrl      = raceMap.get('url');
        Object raceName     = raceMap.get('raceName');
       /* Object date         = raceMap.get('date');
        Object time         = raceMap.get('time');*/

        // (Opcional) Circuito
        Map<String, Object> circuitMap = (Map<String, Object>) raceMap.get('Circuit');
        Object circuitId   = circuitMap != null ? circuitMap.get('circuitId') : null;
        Object circuitName = circuitMap != null ? circuitMap.get('circuitName') : null;

        // Solo extraemos Results[]
        List<Object> resultsList = (List<Object>) raceMap.get('Results');
        if (resultsList != null) {
            for (Object resObj : resultsList) {
                Map<String, Object> resMap = (Map<String, Object>) resObj;

                // ¡IMPORTANTE!: crear un row NUEVO por cada resultado
                Map<String, Object> row = new Map<String, Object>();

                // Contexto de la carrera
                row.put('season', season);
                row.put('round', round);
                row.put('raceUrl', raceUrl);
                row.put('raceName', raceName);
                /*row.put('raceDate', date);
                row.put('raceTime', time);*/
                row.put('circuitId', circuitId);
                row.put('circuitName', circuitName);

                // Campos del resultado
                row.put('number',       resMap.get('number'));
                row.put('position',     resMap.get('position'));
                row.put('positionText', resMap.get('positionText'));
                row.put('points',       resMap.get('points'));
                row.put('grid',         resMap.get('grid'));
                row.put('laps',         resMap.get('laps'));
                row.put('status',       resMap.get('status'));

                // Driver
                Map<String, Object> driverMap = (Map<String, Object>) resMap.get('Driver');
                if (driverMap != null) {
                    row.put('driverId',        driverMap.get('driverId'));          // clave correcta
                    row.put('permanentNumber', driverMap.get('permanentNumber'));
                    row.put('code',            driverMap.get('code'));
                    row.put('driverUrl',       driverMap.get('url'));
                    row.put('givenName',       driverMap.get('givenName'));
                    row.put('familyName',      driverMap.get('familyName'));
                    row.put('dateOfBirth',     driverMap.get('dateOfBirth'));
                    row.put('nationality',     driverMap.get('nationality'));
                }

                // Constructor
                Map<String, Object> constructorMap = (Map<String, Object>) resMap.get('Constructor');
                if (constructorMap != null) { // condición corregida
                    row.put('constructorId',   constructorMap.get('constructorId')); // clave correcta
                    row.put('constructorName', constructorMap.get('name'));
                    row.put('constructorUrl',  constructorMap.get('url'));
                    row.put('constructorNat',  constructorMap.get('nationality'));
                }

                // (Opcional) tiempos/paradas si existen
                // Ejemplo: row.put('fastestLapRank', ((Map<String,Object>)resMap.get('FastestLap'))?.get('rank'));

                result.add(row);
            }
        }
    }
            } else {
                System.debug('Error en la llamada HTTP: ' + res.getStatusCode());
            }

                    
        } catch (Exception e) {
            System.debug('Excepción en giveResults: ' + e.getMessage());
        }

        return result;
    }

   @AuraEnabled
    public static void saveResults() {
        List<Map<String, Object>> resultsData = giveResults();
       List<result__c> resultsToInsert = new List<result__c>();
            List<Constructor__c> constructorsToInsert = new List<Constructor__c>();
            List<driver__c> driversToInsert = new List<driver__c>();

        for (Map<String, Object> ds : resultsData) {
            result__c r = new result__c();
            driver__c d = new driver__c();
            Constructor__c c = new Constructor__c();
            r.number__c        = toInteger(ds.get('number'));
            r.position__c      = toInteger(ds.get('position'));
            r.positionText__c  = (String) ds.get('positionText');
            r.points__c        = toInteger(ds.get('points'));
            r.grid__c          = toInteger(ds.get('grid'));
            r.laps__c          = toInteger(ds.get('laps'));
            r.status__c        = (String) ds.get('status');
            r.driver__c      = (String) ds.get('driverId');
            r.Name           = (String) ds.get('raceName');
            r.constructor__c = (String) ds.get('constructorId');
          



            resultsToInsert.add(r);
            constructorsToInsert.add(c);
            driversToInsert.add(d);
        }

        if (!resultsToInsert.isEmpty()) {
            Database.insert(resultsToInsert, false);
            System.debug('Registros insertados: ' + resultsToInsert.size());
        }


    }

    

    // Helper seguro
    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try { return Integer.valueOf(String.valueOf(val)); } catch (Exception e) { return null; }
    }
}