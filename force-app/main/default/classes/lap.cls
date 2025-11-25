public with sharing class lap {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveLap() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2025/1/laps.json'); // Ajusta el Named Credential
            req.setMethod('GET');

            HttpResponse res = http.send(req);

                                if (res.getStatusCode() == 200) {
                        // Deserializamos la respuesta
                        Map<String, Object> jsonMap   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        Map<String, Object> mrData    = (Map<String, Object>) jsonMap.get('MRData');
                        Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
                        List<Object> racesList        = (List<Object>) raceTable.get('Races'); // <-- antes usabas circuitTable

                        // Iterar carreras
                        for (Object obj : racesList) {
                            Map<String, Object> raceItem = (Map<String, Object>) obj;

                            // Extraer la lista de Laps de la carrera
                            List<Object> lapsList = (List<Object>) raceItem.get('Laps');
                            if (lapsList == null) {
                                // Si esta carrera no trae Laps, pasar a la siguiente
                                continue;
                            }

                            // Recorrer cada lap
                            for (Object lapObj : lapsList) {
                                Map<String, Object> lapMap = (Map<String, Object>) lapObj;

                                // Número de vuelta (string en la API)
                                Object lapNumber = lapMap.get('number');

                                // Timings de la vuelta (driverId, position, time)
                                List<Object> timingsList = (List<Object>) lapMap.get('Timings');
                                if (timingsList != null) {
                                    for (Object timingObj : timingsList) {
                                        Map<String, Object> timingMap = (Map<String, Object>) timingObj;

                                        // Armar fila por cada timing (piloto/posición/tiempo) de la vuelta
                                        Map<String, Object> row = new Map<String, Object>();
                                        row.put('lapNumber', lapNumber);
                                        row.put('driverId', timingMap.get('driverId'));
                                        row.put('position', timingMap.get('position'));
                                        row.put('time',     timingMap.get('time'));

                                        // (Opcional) incluir datos de la carrera para contexto
                                        row.put('raceName', raceItem.get('raceName'));
                                        row.put('round',    raceItem.get('round'));
                                        row.put('date',     raceItem.get('date'));
                                        row.put('raceUrl',  raceItem.get('url'));

                                        result.add(row);
                                    }
                                }
                            }
                        }
                    } else {
                        System.debug('Error en la llamada HTTP: ' + res.getStatusCode());
                    }

        } catch (Exception e) {
            System.debug('Excepción en giveLap: ' + e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static void saveLap() {
        List<Map<String, Object>> lapData = giveLap();
        List<lap__c> lapToInsert = new List<lap__c>();

        for (Map<String, Object> ls : lapData) {
            lap__c l = new lap__c();
            l.Name = (String) ls.get('Name');
            //c.circuitName__c = (String) ds.get('circuitName'); 
            l.number__c = Integer.valueOf((String) ls.get('number'));
             //(String) ds.get('url');

            /*if (ds.get('lat') != null) {
                c.Location__Latitude__s = Decimal.valueOf(String.valueOf(ds.get('lat')));
            }
            if (ds.get('long') != null) {
                c.Location__Longitude__s = Decimal.valueOf(String.valueOf(ds.get('long')));
            }

            c.locality__c = (String) ds.get('locality');
            c.country__c = (String) ds.get('country');*/

            lapToInsert.add(l);
        }

        if (!lapToInsert.isEmpty()) {
            Database.insert(lapToInsert, false);
            System.debug('Registros insertados: ' + lapToInsert.size());
        }
    }
}