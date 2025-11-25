public with sharing class result {
   @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveResults() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2025/results.json'); // Ajusta el Named Credential
            req.setMethod('GET');

            HttpResponse res = http.send(req);

           
            if (res.getStatusCode() == 200) {
                        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        Map<String, Object> mrData = (Map<String, Object>) jsonMap.get('MRData');
                        Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
                        List<Object> racesList = (List<Object>) raceTable.get('Races');

                        for (Object obj : racesList) {
                            Map<String, Object> race = (Map<String, Object>) obj;
                            Map<String, Object> circuit = (Map<String, Object>) race.get('Circuit');
                            Map<String, Object> location = (Map<String, Object>) circuit.get('Location');
                            

                            Map<String, Object> row = new Map<String, Object>();
                            row.put('raceName', race.get('raceName'));
                            row.put('round', race.get('round'));
                            row.put('date', race.get('date'));
                            row.put('time', race.get('time'));
                            row.put('circuitName', circuit.get('circuitName'));

                            if (location != null) {
                                row.put('locality', location.get('locality'));
                                row.put('country', location.get('country'));
                            }

                            // Ganador
                            List<Object> results = (List<Object>) race.get('Results');
                            if (results != null && !results.isEmpty()) {
                                /*Map<String, Object> winner = (Map<String, Object>) results[0];
                                Map<String, Object> driver = (Map<String, Object>) winner.get('Driver');
                                row.put('winner', driver.get('givenName') + ' ' + driver.get('familyName'));*/

                                row.put('number', race.get('number'));
                                row.put('position', race.get('position'));
                                row.put('positionText', race.get('positionText'));
                                row.put('points', race.get('points'));
                                row.put('grid', circuit.get('grid'));
                                row.put('laps', race.get('laps'));
                                row.put('status', race.get('status'));
                            }

                            result.add(row);
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error: ' + e.getMessage());
                }

        return result;
    }

    @AuraEnabled
    public static void saveResults() {
    List<Map<String, Object>> resultsData = giveResults();
     List<result__c> resulttoInsert = new List<result__c>();

          for (Map<String, Object> ds : resultsData) {
        result__c r = new result__c();
	    r.number__c = (Integer) ds.get('number');
        r.position__c = (Decimal) ds.get('position');
        r.positionText__c = (String) ds.get('positionText');
        r.points__c = (Integer ) ds.get('points');
        r.grid__c = (Integer ) ds.get('grid');
        r.laps__c = (Integer ) ds.get('laps');
        r.status__c = (String) ds.get('status');

            resulttoInsert.add(r);
    }

        if (!resulttoInsert.isEmpty()) {
            Database.insert(resulttoInsert, false);
            System.debug('Registros insertados: ' + resulttoInsert.size());
        }
    }
}