public with sharing class sprint {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> givesprint() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2024/sprint.json');
            req.setMethod('GET');

            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonMap   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> mrData    = (Map<String, Object>) jsonMap.get('MRData');
                Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
                List<Object> racesList        = (List<Object>) raceTable.get('Races');

                for (Object obj : racesList) {
                    Map<String, Object> raceItem = (Map<String, Object>) obj;
                    List<Object> sprintResults = (List<Object>) raceItem.get('SprintResults');
                    if (sprintResults == null) continue;

                    for (Object sprintObj : sprintResults) {
                        Map<String, Object> sprintMap = (Map<String, Object>) sprintObj;

                        Map<String, Object> row = new Map<String, Object>();
                        row.put('number', sprintMap.get('number'));
                        row.put('position', sprintMap.get('position'));
                        row.put('positionText', sprintMap.get('positionText'));
                        row.put('points', sprintMap.get('points'));
                        row.put('grid', sprintMap.get('grid'));
                        row.put('laps', sprintMap.get('laps'));
                        row.put('status', sprintMap.get('status'));

                        Map<String, Object> timeNode = (Map<String, Object>) sprintMap.get('Time');
                        if (timeNode != null) {
                            row.put('finishMillis', timeNode.get('millis'));
                            row.put('finishTime', timeNode.get('time'));
                        }

                        Map<String, Object> fastestLap = (Map<String, Object>) sprintMap.get('FastestLap');
                        if (fastestLap != null) {
                            row.put('fastestRank', fastestLap.get('rank'));
                            row.put('fastestLapNumber', fastestLap.get('lap'));
                            row.put('fastestLapTime', fastestLap.get('time')); 
                        }

                        Map<String, Object> driver = (Map<String, Object>) sprintMap.get('Driver');
                        if (driver != null) {
                            row.put('driverId', driver.get('driverId'));
                            row.put('driverCode', driver.get('code'));
                            row.put('driverName', driver.get('givenName') + ' ' + driver.get('familyName'));
                        }

                        Map<String, Object> constructor = (Map<String, Object>) sprintMap.get('Constructor');
                        if (constructor != null) {
                            row.put('constructorName', constructor.get('name'));
                        }

                        row.put('raceName', raceItem.get('raceName'));
                        row.put('round', raceItem.get('round'));
                        row.put('date', raceItem.get('date'));

                        result.add(row);
                    }
                }
            } else {
                System.debug('Error HTTP: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Excepción en givesprint: ' + e.getMessage());
        }

        return result;
    }

  
                @AuraEnabled
                public static void savesprint() {
                    List<Map<String, Object>> sprintData = givesprint();
                    List<sprint__c> sprintToInsert = new List<sprint__c>();

                    for (Map<String, Object> spr : sprintData) {
                        sprint__c sp = new sprint__c();
                        sp.number__c = Integer.valueOf(String.valueOf(spr.get('number')));
                        sp.position__c = Integer.valueOf(String.valueOf(spr.get('position')));
                        sp.points__c = Integer.valueOf(String.valueOf(spr.get('points')));
                        sp.laps__c = Integer.valueOf(String.valueOf(spr.get('laps')));
                        sp.status__c = (String) spr.get('status');                      
                        sp.finishTime__c = parseSprintTime((String) spr.get('finishTime')); 
                        sp.fastestLapTime__c = parseSprintTime((String) spr.get('fastestLapTime'));

                        sprintToInsert.add(sp);
                    }

                    if (!sprintToInsert.isEmpty()) {
                        Database.insert(sprintToInsert, false);
                        System.debug('Registros insertados: ' + sprintToInsert.size());
                    }
                }

                private static Time parseSprintTime(String val) {
                    if (String.isBlank(val)) return null;
                    List<String> parts = val.split(':');
                    if (parts.size() != 2) return null;
                    Integer minutes = Integer.valueOf(parts[0]);
                    List<String> secAndMs = parts[1].split('\\.');
                    Integer seconds = Integer.valueOf(secAndMs[0]);
                    Integer millis = secAndMs.size() > 1 ? Integer.valueOf(secAndMs[1]) : 0;
                    return Time.newInstance(0, minutes, seconds, millis);
                }

    
}