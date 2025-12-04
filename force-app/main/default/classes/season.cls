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
                // Deserializamos la respuesta usando como modelado deserializeUntyped el cual reliza la 
                //extracion en la misma pagina sin necesida de asociado dentro de las classes
            if (res.getStatusCode() == 200) {
         
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> mrData = (Map<String, Object>) jsonMap.get('MRData');
                Map<String, Object> SeasonTable = (Map<String, Object>) mrData.get('SeasonTable');
                List<Object> SeasonsList = (List<Object>) SeasonTable.get('Seasons');

                for (Object obj : SeasonsList) {
                    Map<String, Object> Seasons = (Map<String, Object>) obj;    

                    Map<String, Object> row = new Map<String, Object>();
                    row.put('season', Seasons.get('season'));
                    row.put('url', Seasons.get('url'));

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

        // generamos el AuraEnabled, para poder hacer pruebas dentro de la Developer Consol, ademas se utilizara para ejecutar el batch para la carga y para las LWC


            @AuraEnabled
                public static void saveSeasion() {
                    List<Map<String, Object>> seasonData = giveSeason();
                    List<season__c> seasionToInsert = new List<season__c>();

                    for (Map<String, Object> ls : seasonData) {
                        season__c s = new season__c();
                        s.Name = (String) ls.get('season');
                        s.url__c = (String) ls.get('url');
                        s.season__c = Integer.valueOf((String) ls.get('season'));
                        seasionToInsert.add(s);
                    }

                    if (!seasionToInsert.isEmpty()) {
                        Database.insert(seasionToInsert, false);
                        System.debug('Registros insertados: ' + seasionToInsert.size());
                    }
                }
}