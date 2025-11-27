public with sharing class pitstop {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> givepitstop() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2025/1/pitstops.json'); // Ajusta el Named Credential
            req.setMethod('GET');

            HttpResponse res = http.send(req);

                                if (res.getStatusCode() == 200) {
                         // Deserializamos la respuesta comenzando con la estructura que mencina la Api
                        Map<String, Object> jsonMap   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                        Map<String, Object> mrData    = (Map<String, Object>) jsonMap.get('MRData');
                        Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
                        List<Object> racesList        = (List<Object>) raceTable.get('Races'); // <-- antes usabas circuitTable

                        // Iteramos race ya que la informacion que estamos buscando se encuentra dentro de carrera race
                        
                        for (Object obj : racesList) {
                            Map<String, Object> raceItem = (Map<String, Object>) obj;

                                        // Extraer la lista de Laps de la carrera
                                        List<Object> PitStops = (List<Object>) raceItem.get('PitStops');
                                        if (PitStops == null) {
                                            // Si esta carrera no trae Laps, pasar a la siguiente
                                            continue;
                                        }


                                    for (Object PitngObj : PitStops) {
                                        Map<String, Object> pitngMap = (Map<String, Object>) PitngObj;
                                      
                                        // Se armar una fila por cada timing con los valores que se encuentra dentro de la Api y que aparecen en la vuelta
                                        
                                        Map<String, Object> row = new Map<String, Object>();
                                        row.put('driverId', pitngMap.get('driverId'));
                                        row.put('lap', pitngMap.get('lap'));
                                        row.put('stop',     pitngMap.get('stop'));
                                        row.put('time',     pitngMap.get('time'));
                                        row.put('duration',     pitngMap.get('duration'));

                    
                                        result.add(row);
                                    }
                                
                            //}
                        }
                    } else {
                        System.debug('Error en la llamada HTTP: ' + res.getStatusCode());}
        

        } catch (Exception e) {
            System.debug('Excepción en givepitstop: ' + e.getMessage());
        }

        return result;
    }

                // generamos el AuraEnabled, para poder hacer pruebas dentro de la Developer Consol, ademas se utilizara para ejecutar el batch para la carga y para las LWC


                @AuraEnabled
                public static void savepitstop() {
                    List<Map<String, Object>> lapData = givepitstop();
                    List<pitstop__c> pitstopToInsert = new List<pitstop__c>();

                    for (Map<String, Object> ps : lapData) {
                        pitstop__c p = new pitstop__c();
                        p.Name = (String) ps.get('Name');
                        p.lap__c = Integer.valueOf((String) ps.get('lap'));
                        p.stop__c = Integer.valueOf((String) ps.get('stop'));
                        p.time__c = parseQuTime((String) ps.get('time'));
                        p.duration__c = Decimal.valueOf((String) ps.get('durationduration'));

                        pitstopToInsert.add(p);
                    }

                    if (!pitstopToInsert.isEmpty()) {
                        Database.insert(pitstopToInsert, false);
                        System.debug('Registros insertados: ' + pitstopToInsert.size());
                    }
                }

                private static Time parseQuTime(String val) {
                    if (String.isBlank(val)) return null;

                    // Formato esperado: para la conversion de time
                    List<String> minAndRest = val.split(':');
                    if (minAndRest.size() != 2) return null;

                    Integer minutes = Integer.valueOf(minAndRest[0]);

                    List<String> secAndMs = minAndRest[1].split('\\.');
                    Integer seconds = Integer.valueOf(secAndMs[0]);
                    Integer millis = 0;

                    return Time.newInstance(0, minutes, seconds, millis);
                }
}