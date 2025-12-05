public with sharing class pitstop { 
@AuraEnabled(cacheable=true)
public static List<Map<String, Object>> givepitstop() {
    List<Map<String, Object>> result = new List<Map<String, Object>>();

    try {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:pilotos2/ergast/f1/2024/1/pitstops.json'); // Named Credential
        req.setMethod('GET');

        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> mrData = (Map<String, Object>) jsonMap.get('MRData');
            Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
            List<Object> racesList = (List<Object>) raceTable.get('Races');

            for (Object obj : racesList) {
                Map<String, Object> raceItem = (Map<String, Object>) obj;

                // Circuit info (a nivel de carrera)
                Map<String, Object> circuitMap = (Map<String, Object>) raceItem.get('Circuit');
                String circuitId = circuitMap != null ? (String) circuitMap.get('circuitId') : null;
                String circuitName = circuitMap != null ? (String) circuitMap.get('circuitName') : null;

                // Lista de pitstops
                List<Object> pitStops = (List<Object>) raceItem.get('PitStops');
                if (pitStops == null) continue;

                for (Object pitObj : pitStops) {
                    Map<String, Object> pitMap = (Map<String, Object>) pitObj;

                    Map<String, Object> row = new Map<String, Object>();
                    row.put('lap', pitMap.get('lap'));
                    row.put('stop', pitMap.get('stop'));
                    row.put('time', pitMap.get('time'));
                    row.put('duration', pitMap.get('duration'));

                    // DriverId viene directamente en pitstop
                    row.put('driverId', pitMap.get('driverId'));

                    // Circuit info desde la carrera
                    row.put('circuitId', circuitId);
                    row.put('circuitName', circuitName);

                    result.add(row);
                }
            }
        } else {
            System.debug('Error en la llamada HTTP: ' + res.getStatusCode());
        }
    } catch (Exception e) {
        System.debug('Excepción en givepitstop: ' + e.getMessage());
    }

    return result;
}


    // generamos el AuraEnabled, para poder hacer pruebas dentro de la Developer Consol, ademas se utilizara para ejecutar el batch para la carga y para las LWC


                @AuraEnabled
                public static void savepitstop() {
                    List<Map<String, Object>> pitstopData = givepitstop();
                    List<pitstop__c> pitstopToInsert = new List<pitstop__c>();
                    List<Driver__c> driversToUpsert = new List<Driver__c>();
                    List<Circuit__c> circuitsToUpsert = new List<Circuit__c>();

                         Set<String> driverIds = new Set<String>();           
                        Set<String> circuitIds = new Set<String>();

                    for (Map<String, Object> ps : pitstopData) {
                        
                        String driverIdRaw = (String) ps.get('driverId');
                        String circuitIdRaw = (String) ps.get('circuitId');
                        
                        String driverId = driverIdRaw != null ? driverIdRaw.trim().toLowerCase() : null;
                        String circuitId = circuitIdRaw != null ? circuitIdRaw.trim().toLowerCase() : null;

                        if (!String.isBlank(driverId)) driverIds.add(driverId);
                        if (!String.isBlank(circuitId)) circuitIds.add(circuitId);

                     

                        if(!String.isBlank(driverIdRaw)){
                             Driver__c d = new Driver__c();
                             d.driverId__c = driverId;
                             d.Name = buildDriverName(ps);
                             driversToUpsert.add(d);
                        } 

                        if(!String.isblank(circuitIdRaw)){
                            Circuit__c ci = new Circuit__c();
                            ci.circuitId__c = circuitId;
                            ci.Name = (String) ps.get('circuitName');
                            circuitsToUpsert.add(ci);
                        }

                      
                                pitstop__c p = new pitstop__c();
                                p.Name = (String) ps.get('name');
                                p.lap__c = Integer.valueOf((String) ps.get('lap'));
                                p.stop__c = Integer.valueOf((String) ps.get('stop'));

                                // Convertir time (formato HH:mm:ss)
                                String timeVal = (String) ps.get('time');
                                if (!String.isBlank(timeVal)) {
                                    p.time__c = parsePitstopTime(timeVal); // Nuevo método
                                }

                                // Convertir duration (formato decimal)
                                String durationVal = (String) ps.get('duration');
                                if (!String.isBlank(durationVal)) {
                                    p.duration__c = Decimal.valueOf(durationVal);
                                }

                                pitstopToInsert.add(p);


                    }

                    // Upsert Circuit and Driver
                    if (!driversToUpsert.isEmpty()) {
                        Database.upsert(driversToUpsert, Driver__c.Fields.driverId__c, false);
                    }
                    
                    if (!circuitsToUpsert.isEmpty()) {
                        Database.upsert(circuitsToUpsert, Circuit__c.Fields.circuitId__c, false);
                    }

                    // 3. Consultar Ids reales y normalizar claves

                    Map<String, Id> driverMap = new Map<String, Id>();
                        for (Driver__c d : [SELECT Id, driverId__c FROM Driver__c WHERE driverId__c IN :driverIds]) {
                          driverMap.put(d.driverId__c.trim().toLowerCase(), d.Id);
                        }

                    Map<String, Id> circuitMap = new Map<String, Id>();
                        for (Circuit__c ci : [SELECT Id, circuitId__c FROM Circuit__c WHERE circuitId__c IN :circuitIds]) {
                          circuitMap.put(ci.circuitId__c.trim().toLowerCase(), ci.Id);
                        }
                    System.debug('circuitMap: ' + circuitMap);
                    System.debug('driverMap: ' + driverMap);
                        
                    // 4. Asignar Lookups
                

                  for (Integer i = 0; i < pitstopData.size(); i++) {
                        Map<String, Object> ps = pitstopData[i];
                        String dId = ps.get('driverId') != null ? ((String) ps.get('driverId')).trim().toLowerCase() : null;
                        String ciId = ps.get('circuitId') != null ? ((String) ps.get('circuitId')).trim().toLowerCase() : null;

                        if (!String.isBlank(dId)) pitstopToInsert[i].Driver__c = driverMap.get(dId);
                        if (!String.isBlank(ciId)) pitstopToInsert[i].Circuit__c = circuitMap.get(ciId);
                    }

                    if (!pitstopToInsert.isEmpty()) {
                        Database.insert(pitstopToInsert, false);
                        System.debug('Registros insertados: ' + pitstopToInsert.size());
                    }

                        
                }

                
                    private static Time parsePitstopTime(String val) {
                        if (String.isBlank(val)) return null;
                        List<String> parts = val.split(':');
                        if (parts.size() != 3) return null; // HH:mm:ss
                        Integer hours = Integer.valueOf(parts[0]);
                        Integer minutes = Integer.valueOf(parts[1]);
                        Integer seconds = Integer.valueOf(parts[2]);
                        return Time.newInstance(hours, minutes, seconds, 0);
                    }

            
                private static String buildDriverName(Map<String, Object> ds) {
                String given = (String) ds.get('givenName');
                String family = (String) ds.get('familyName');
                String full = ((given != null ? given : '') + ' ' + (family != null ? family : '')).trim();
                return String.isBlank(full) ? (String) ds.get('driverId') : full;
                }

}