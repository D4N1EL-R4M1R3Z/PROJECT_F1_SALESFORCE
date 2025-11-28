public with sharing class circuit {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveCircuits() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/circuits.json'); // se coloca la direccion Url de la api en forma de callout
            req.setMethod('GET');

            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                // Deserializamos la respuesta usando como modelado deserializeUntyped el cual reliza la 
                //extracion en la misma pagina sin necesida de asociado dentro de las classes
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> mrData = (Map<String, Object>) jsonMap.get('MRData');
                Map<String, Object> circuitTable = (Map<String, Object>) mrData.get('CircuitTable');
                List<Object> circuitsList = (List<Object>) circuitTable.get('Circuits');

                for (Object obj : circuitsList) {
                    Map<String, Object> circuit = (Map<String, Object>) obj;
                    Map<String, Object> location = (Map<String, Object>) circuit.get('Location');

                    Map<String, Object> row = new Map<String, Object>();
                    row.put('circuitId', circuit.get('circuitId'));
                    row.put('circuitName', circuit.get('circuitName'));
                    row.put('url', circuit.get('url'));

                    if (location != null) {
                        row.put('lat', location.get('lat'));
                        row.put('long', location.get('long'));
                        row.put('locality', location.get('locality'));
                        row.put('country', location.get('country'));
                    }

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
            public static void saveCircuits() {
                List<Map<String, Object>> circuitsData = giveCircuits();
                List<circuit__c> circuitsToInsert = new List<circuit__c>();

                for (Map<String, Object> ds : circuitsData) {
                    circuit__c c = new circuit__c();
                    c.Name = (String) ds.get('circuitName');
                    //c.circuitName__c = (String) ds.get('circuitName'); 
                    c.circuitId__c = (String) ds.get('circuitId');
                    c.url__c = (String) ds.get('url');

                    if (ds.get('lat') != null) {
                        c.Location__Latitude__s = Decimal.valueOf(String.valueOf(ds.get('lat')));
                    }
                    if (ds.get('long') != null) {
                        c.Location__Longitude__s = Decimal.valueOf(String.valueOf(ds.get('long')));
                    }
                    c.locality__c = (String) ds.get('locality');
                    c.country__c = (String) ds.get('country');

                    circuitsToInsert.add(c);
                }
                    // enn este apartado utilizamos un debug para mirar cuando datos inserto dentro de salesforce usando Developer Consol
                if (!circuitsToInsert.isEmpty()) {
                    Database.insert(circuitsToInsert, false);
                    System.debug('Registros insertados: ' + circuitsToInsert.size());
                }
            }
}