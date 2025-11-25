public with sharing class season {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveSeason() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/seasons.json'); // Ajusta el Named Credential
            req.setMethod('GET');

            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                // Deserializamos la respuesta
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> mrData = (Map<String, Object>) jsonMap.get('MRData');
                Map<String, Object> SeasonTable = (Map<String, Object>) mrData.get('SeasonTable');
                List<Object> SeasonsList = (List<Object>) SeasonTable.get('Seasons');

                for (Object obj : SeasonsList) {
                    Map<String, Object> Seasons = (Map<String, Object>) obj;
                    //Map<String, Object> location = (Map<String, Object>) circuit.get('Location');

                    Map<String, Object> row = new Map<String, Object>();
                    row.put('season', Seasons.get('season'));
                    //row.put('circuitName', circuit.get('circuitName'));
                    row.put('url', Seasons.get('url'));

                   /* if (location != null) {
                        row.put('lat', location.get('lat'));
                        row.put('long', location.get('long'));
                        row.put('locality', location.get('locality'));
                        row.put('country', location.get('country'));
                    }*/

                    result.add(row);
                }
            } else {
                System.debug('Error en la llamada HTTP: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Excepción en obtenerCircuits: ' + e.getMessage());
        }

        return result;
    }

   @AuraEnabled
    public static void saveSeasion() {
        List<Map<String, Object>> seasonData = giveSeason();
        List<season__c> seasionToInsert = new List<season__c>();

        for (Map<String, Object> ls : seasonData) {
            season__c s = new season__c();
            s.url__c = (String) ls.get('url');
            //c.circuitName__c = (String) ds.get('circuitName'); 
            s.season__c = Integer.valueOf((String) ls.get('season'));
            //c.url__c = (String) ds.get('url');

           /* if (ds.get('lat') != null) {
                c.Location__Latitude__s = Decimal.valueOf(String.valueOf(ds.get('lat')));
            }
            if (ds.get('long') != null) {
                c.Location__Longitude__s = Decimal.valueOf(String.valueOf(ds.get('long')));
            }

            c.locality__c = (String) ds.get('locality');
            c.country__c = (String) ds.get('country');*/

            seasionToInsert.add(s);
        }

        if (!seasionToInsert.isEmpty()) {
            Database.insert(seasionToInsert, false);
            System.debug('Registros insertados: ' + seasionToInsert.size());
        }
    }
}