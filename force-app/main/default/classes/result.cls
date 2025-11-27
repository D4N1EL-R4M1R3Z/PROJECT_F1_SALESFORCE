public with sharing class result {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveResults() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        Integer limitVal  = 100;  
        Integer offsetVal = 0;
        Boolean morePages = true;

        try {
            while (morePages) {
                Http http = new Http();
                HttpRequest req = new HttpRequest();

       
                req.setEndpoint('callout:pilotos2/ergast/f1/2025/results.json?limit=' + limitVal + '&offset=' + offsetVal);
                req.setMethod('GET');

                HttpResponse res = http.send(req);
                if (res.getStatusCode() != 200) {
                    System.debug(LoggingLevel.ERROR, 'HTTP error: ' + res.getStatusCode() + ' - ' + res.getStatus());
                    break;
                }

                Map<String, Object> jsonMap   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> mrData    = (Map<String, Object>) jsonMap.get('MRData');
                Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
                List<Object> racesList        = (List<Object>) raceTable.get('Races');

                System.debug(LoggingLevel.INFO, 'Page info: limit=' + mrData.get('limit') + ', offset=' + mrData.get('offset') + ', total=' + mrData.get('total'));

                if (racesList == null || racesList.isEmpty()) break;

                for (Object rObj : racesList) {
                    Map<String, Object> race = (Map<String, Object>) rObj;
                    List<Object> resultsList = (List<Object>) race.get('Results');
                    if (resultsList == null) continue;

                    for (Object resObj : resultsList) {
                        Map<String, Object> resultObj = (Map<String, Object>) resObj;

                        Map<String, Object> row = new Map<String, Object>();

                        row.put('number',        toInteger(resultObj.get('number')));
                        row.put('position',      toDecimal(resultObj.get('position'))); 
                        row.put('positionText',  resultObj.get('positionText'));
                        row.put('points',        toInteger(resultObj.get('points')));
                        row.put('grid',          toInteger(resultObj.get('grid')));
                        row.put('laps',          toInteger(resultObj.get('laps')));
                        row.put('status',        resultObj.get('status'));

                
                        row.put('season',        race.get('season'));
                        row.put('round',         race.get('round'));
                        row.put('raceName',      race.get('raceName'));
                        row.put('date',          race.get('date'));
                        row.put('time',          race.get('time'));

                        Map<String, Object> driver = (Map<String, Object>) resultObj.get('Driver');
                        if (driver != null) {
                            row.put('driverId',     driver.get('driverId'));
                            row.put('driverCode',   driver.get('code'));
                            row.put('driverGiven',  driver.get('givenName'));
                            row.put('driverFamily', driver.get('familyName'));
                            row.put('driverNat',    driver.get('nationality'));
                            row.put('driverNumber', toInteger(driver.get('permanentNumber')));
                        }

                        Map<String, Object> constructor = (Map<String, Object>) resultObj.get('Constructor');
                        if (constructor != null) {
                            row.put('constructorId',   constructor.get('constructorId'));
                            row.put('constructorName', constructor.get('name'));
                            row.put('constructorNat',  constructor.get('nationality'));
                        }


                        Map<String, Object> timeNode = (Map<String, Object>) resultObj.get('Time');
                        if (timeNode != null) {
                            row.put('finishMillis',  toInteger(timeNode.get('millis')));
                            row.put('finishTimeStr', timeNode.get('time')); 
                        }

                        Map<String, Object> flNode = (Map<String, Object>) resultObj.get('FastestLap');
                        if (flNode != null) {
                            row.put('fastestRank',  toInteger(flNode.get('rank')));
                            Map<String, Object> flTime = (Map<String, Object>) flNode.get('Time');
                            if (flTime != null) row.put('flTime', flTime.get('time'));
                            Map<String, Object> avgSp = (Map<String, Object>) flNode.get('AverageSpeed');
                            if (avgSp != null) {
                                row.put('flAvgSpeed', avgSp.get('speed'));
                                row.put('flAvgUnits', avgSp.get('units')); 
                            }
                        }

                        result.add(row);
                    }
                }


                Integer mrLimit  = toInteger(mrData.get('limit'));
                Integer mrOffset = toInteger(mrData.get('offset'));
                Integer mrTotal  = toInteger(mrData.get('total'));

                Integer nextOffset = (mrOffset != null && mrLimit != null) ? (mrOffset + mrLimit) : null;
                if (mrTotal != null && nextOffset != null && nextOffset < mrTotal) {
                    offsetVal = nextOffset;     
                } else {
                    morePages = false;       
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Excepción en giveResults: ' + e.getMessage());
        }

        System.debug(LoggingLevel.INFO, 'Total Results devueltos: ' + result.size());
        return result;
    }

                @AuraEnabled
                public static void saveResults() {
                    List<Map<String, Object>> resultsData = giveResults();
                    List<result__c> resulttoInsert = new List<result__c>();

                    for (Map<String, Object> ds : resultsData) {
                        result__c r = new result__c();
                        r.number__c        = (Integer) ds.get('number');
                        r.position__c      = (Decimal) ds.get('position'); 
                        r.positionText__c  = (String)  ds.get('positionText');
                        r.points__c        = (Integer) ds.get('points');
                        r.grid__c          = (Integer) ds.get('grid');
                        r.laps__c          = (Integer) ds.get('laps');
                        r.status__c        = (String)  ds.get('status');

                        resulttoInsert.add(r);
                    }

                    if (!resulttoInsert.isEmpty()) {
                        Database.insert(resulttoInsert, false);
                        System.debug(LoggingLevel.INFO, 'Registros insertados: ' + resulttoInsert.size());
                    } else {
                        System.debug(LoggingLevel.WARN, 'No hay resultados para insertar.');
                    }
                }

                // Helpers de casting seguros
                private static Integer toInteger(Object val) {
                    if (val == null) return null;
                    try { return Integer.valueOf(String.valueOf(val)); } catch (Exception e) { return null; }
                }
                private static Decimal toDecimal(Object val) {
                    if (val == null) return null;
                    String s = String.valueOf(val);
                    try { return Decimal.valueOf(s); } catch (Exception e) { return null; }
                }
}