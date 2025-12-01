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
                       
                // Deserializamos la respuesta comenzando con la estructura que mencina la Api

                    if (res.getStatusCode() == 200) {

                        Map<String, Object> jsonMap   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        Map<String, Object> mrData    = (Map<String, Object>) jsonMap.get('MRData');
                        Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
                        List<Object> racesList        = (List<Object>) raceTable.get('Races'); // <-- antes usabas circuitTable

                        
                        // Iteramos race ya que la informacion que estamos buscando se encuentra dentro de carrera race

                        for (Object obj : racesList) {
                            Map<String, Object> raceItem = (Map<String, Object>) obj;

                            // Comenzamos a extraer la lista de los laps que se encuentra dentro de race

                            List<Object> lapsList = (List<Object>) raceItem.get('Laps');
                            if (lapsList == null) {
                                // Si esta carrera no trae Laps, pasar a la siguiente
                                continue;
                            }

                            // generamos un blucle para poder recorere cada lap que se encuentr dentro de race
                            for (Object lapObj : lapsList) {
                                Map<String, Object> lapMap = (Map<String, Object>) lapObj;

                                Object lapNumber = lapMap.get('number');
                                
                                List<Object> timingsList = (List<Object>) lapMap.get('Timings');
                                if (timingsList != null) {
                                    for (Object timingObj : timingsList) {
                                        Map<String, Object> timingMap = (Map<String, Object>) timingObj;

                                        // Se armar una fila por cada timing con los valores que se encuentra dentro de la Api y que aparecen en la vuelta
                                        Map<String, Object> row = new Map<String, Object>();
                                        row.put('lapNumber', lapNumber);
                                        row.put('driverId', timingMap.get('driverId'));
                                        row.put('position', timingMap.get('position'));
                                        row.put('time',     timingMap.get('time'));

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

                    // generamos el AuraEnabled, para poder hacer pruebas dentro de la Developer Consol, ademas se utilizara para ejecutar el batch para la carga y para las LWC


@AuraEnabled
public static void saveLap() {
    List<Map<String, Object>> lapData = giveLap();
    List<lap__c> lapToInsert = new List<lap__c>();
    List<Circuit__c> circuitsToUpsert = new List<Circuit__c>();

    for (Map<String, Object> ls : lapData) {
        // Crear circuito para upsert
        Circuit__c circuit = new Circuit__c();
        circuit.circuitId__c = (String) ls.get('circuitId'); // External Id
        circuit.Name = (String) ls.get('Name');
        circuit.url__c = (String) ls.get('circuitUrl');
        circuitsToUpsert.add(circuit);

        // Crear lap
        lap__c l = new lap__c();
        l.Name = 'Lap ' + (String) ls.get('lapNumber');
        l.position__c = Integer.valueOf((String) ls.get('position'));
        String timeVal = (String) ls.get('time');
                l.time__c = parseQuTime(timeVal);

        // Relacionar con circuito por External Id
        String circuitId = (String) ls.get('circuitId');
        if (String.isNotBlank(circuitId)) {
            l.Circuit__r = new Circuit__c(circuitId__c = circuitId);
        }

        lapToInsert.add(l);
    }

    // Upsert circuitos primero
    if (!circuitsToUpsert.isEmpty()) {
        Database.upsert(circuitsToUpsert, Circuit__c.Fields.circuitId__c, false);
    }

    // Insert laps
    if (!lapToInsert.isEmpty()) {
        Database.insert(lapToInsert, false);
    }
}

        private static Time parseQuTime(String val) {
                if (String.isBlank(val)) return null;

                try {
                    List<String> minAndRest = val.split(':');
                    if (minAndRest.size() != 2) return null;

                    Integer minutes = Integer.valueOf(minAndRest[0]);

                    List<String> secAndMs = minAndRest[1].split('\\.');
                    Integer seconds = Integer.valueOf(secAndMs[0]);
                    Integer millis = 0; // Salesforce Time no soporta milisegundos

                    return Time.newInstance(0, minutes, seconds, millis);
                } catch (Exception e) {
                    System.debug('Formato inválido para time: ' + val);
                    return null;
                }
            }
        

}