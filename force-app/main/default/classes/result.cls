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

                //crear un row NUEVO por cada resultado
                Map<String, Object> row = new Map<String, Object>();

                // Contexto de la carrera
                row.put('season', season);
                row.put('round', round);
                row.put('raceUrl', raceUrl);
                row.put('raceName', raceName);
                
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

                // CircuIT
                  //  Map<String, Object> circuitMap = (Map<String, Object>) resMap.get('Circuit');
                    if(circuitMap != null){
                     row.put('circuitId', (circuitId));
                     row.put('circuitName', (circuitName));

                // (Opcional) tiempos/paradas si existen
                // Ejemplo: row.put('fastestLapRank', ((Map<String,Object>)resMap.get('FastestLap'))?.get('rank'));
                }   
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
    if (resultsData.isEmpty()) {
        System.debug(LoggingLevel.WARN, 'No hay datos para procesar.');
        return;
    }

    List<result__c> resultsToInsert = new List<result__c>();
    List<Constructor__c> constructorsToUpsert = new List<Constructor__c>();
    List<Driver__c> driversToUpsert = new List<Driver__c>();
    List<Circuit__c> circuitsToUpsert = new List<Circuit__c>();

    Set<String> driverIds = new Set<String>();
    Set<String> constructorIds = new Set<String>();
    Set<String> circuitIds = new Set<String>();

    // 1. Preparar datos
    for (Map<String, Object> ds : resultsData) {
        String driverIdRaw = (String) ds.get('driverId');
        String constructorIdRaw = (String) ds.get('constructorId');
        String circuitIdRaw = (String) ds.get('circuitId');

        String driverId = driverIdRaw != null ? driverIdRaw.trim().toLowerCase() : null;
        String constructorId = constructorIdRaw != null ? constructorIdRaw.trim().toLowerCase() : null;
        String circuitId = circuitIdRaw != null ? circuitIdRaw.trim().toLowerCase() : null;

        if (!String.isBlank(driverId)) driverIds.add(driverId);
        if (!String.isBlank(constructorId)) constructorIds.add(constructorId);
        if (!String.isBlank(circuitId)) circuitIds.add(circuitId);

        // Driver
        if (!String.isBlank(driverId)) {
            Driver__c d = new Driver__c();
            d.driverId__c = driverId;
            d.Name = buildDriverName(ds);
            d.nationality__c = (String) ds.get('nationality');
            d.url__c = (String) ds.get('driverUrl');
            driversToUpsert.add(d);
        }

        // Constructor
        if (!String.isBlank(constructorId)) {
            Constructor__c c = new Constructor__c();
            c.constructorId__c = constructorId;
            c.Name = (String) ds.get('constructorName');
            c.url__c = (String) ds.get('constructorUrl');
            c.nationality__c = (String) ds.get('constructorNat');
            constructorsToUpsert.add(c);
        }

        // Circuit
        if (!String.isBlank(circuitId)) {
            Circuit__c ci = new Circuit__c();
            ci.circuitId__c = circuitId;
            ci.Name = (String) ds.get('circuitName');
            ci.url__c = (String) ds.get('circuitUrl');
            circuitsToUpsert.add(ci);
        }

        // Result (sin Lookups aún)
        result__c r = new result__c();
        r.Name = (String) ds.get('raceName');
        r.number__c = toInteger(ds.get('number'));
        r.position__c = toInteger(ds.get('position'));
        r.positionText__c = (String) ds.get('positionText');
        r.points__c = toInteger(ds.get('points'));
        r.grid__c = toInteger(ds.get('grid'));
        r.laps__c = toInteger(ds.get('laps'));
        r.status__c = (String) ds.get('status');
        resultsToInsert.add(r);
    }

    // 2. Upsert Drivers, Constructors y Circuits
    if (!driversToUpsert.isEmpty()) {
        Database.upsert(driversToUpsert, Driver__c.Fields.driverId__c, false);
    }
    if (!constructorsToUpsert.isEmpty()) {
        Database.upsert(constructorsToUpsert, Constructor__c.Fields.constructorId__c, false);
    }
    if (!circuitsToUpsert.isEmpty()) {
        Database.upsert(circuitsToUpsert, Circuit__c.Fields.circuitId__c, false);
    }

    // 3. Consultar Ids reales y normalizar claves
    Map<String, Id> driverMap = new Map<String, Id>();
    for (Driver__c d : [SELECT Id, driverId__c FROM Driver__c WHERE driverId__c IN :driverIds]) {
        driverMap.put(d.driverId__c.trim().toLowerCase(), d.Id);
    }

    Map<String, Id> constructorMap = new Map<String, Id>();
    for (Constructor__c c : [SELECT Id, constructorId__c FROM Constructor__c WHERE constructorId__c IN :constructorIds]) {
        constructorMap.put(c.constructorId__c.trim().toLowerCase(), c.Id);
    }

    Map<String, Id> circuitMap = new Map<String, Id>();
    for (Circuit__c ci : [SELECT Id, circuitId__c FROM Circuit__c WHERE circuitId__c IN :circuitIds]) {
        circuitMap.put(ci.circuitId__c.trim().toLowerCase(), ci.Id);
    }

    System.debug('driverMap: ' + driverMap);
    System.debug('constructorMap: ' + constructorMap);
    System.debug('circuitMap: ' + circuitMap);

    // 4. Asignar Lookups
    Integer index = 0;
    for (Map<String, Object> ds : resultsData) {
        String dId = ((String) ds.get('driverId')).trim().toLowerCase();
        String cId = ((String) ds.get('constructorId')).trim().toLowerCase();
        String ciId = ((String) ds.get('circuitId')).trim().toLowerCase();

        resultsToInsert[index].Driver__c = driverMap.get(dId);
        resultsToInsert[index].Constructor__c = constructorMap.get(cId);
        resultsToInsert[index].Circuit__c = circuitMap.get(ciId);
        index++;
    }

    // 5. Insert Results
    if (!resultsToInsert.isEmpty()) {
        Database.SaveResult[] sr = Database.insert(resultsToInsert, false);
        Integer ok = 0, fail = 0;
        for (Database.SaveResult s : sr) {
            if (s.isSuccess()) {
                ok++;
            } else {
                fail++;
                for (Database.Error e : s.getErrors()) {
                    System.debug('Error insert Result: ' + e.getStatusCode() + ' - ' + e.getMessage());
                }
            }
        }
        System.debug('Resultados procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
    }
}

// Helpers
private static Integer toInteger(Object val) {
    if (val == null) return null;
    try { return Integer.valueOf(String.valueOf(val)); } catch (Exception e) { return null; }
}
private static String buildDriverName(Map<String, Object> ds) {
    String given = (String) ds.get('givenName');
    String family = (String) ds.get('familyName');
    String full = ((given != null ? given : '') + ' ' + (family != null ? family : '')).trim();
    return String.isBlank(full) ? (String) ds.get('driverId') : full;
}

}