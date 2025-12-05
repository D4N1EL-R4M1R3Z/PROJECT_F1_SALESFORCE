public with sharing class race {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveRace() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2024/races.json'); // Named Credential
            req.setMethod('GET');

            HttpResponse res = http.send(req);

                // Deserializamos la respuesta comenzando con la estructura que mencina la Api


            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonMap   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> mrData    = (Map<String, Object>) jsonMap.get('MRData');
                Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
                List<Object> racesList        = (List<Object>) raceTable.get('Races');

                for (Object obj : racesList) {
                    Map<String, Object> race = (Map<String, Object>) obj;

                    Map<String, Object> row = new Map<String, Object>();
                    row.put('raceName', race.get('raceName'));
                    row.put('url',      race.get('url'));
                    row.put('date',     race.get('date')); 
                    row.put('time',     race.get('time')); 
                    row.put('season',   race.get('season'));
                    row.put('round',    race.get('round'));

                    // mencionamos en donde se obtiene los datos de Prácticas y Qualifying
                    Map<String, Object> fp = (Map<String, Object>) race.get('FirstPractice');
                    Map<String, Object> sp = (Map<String, Object>) race.get('SecondPractice');
                    Map<String, Object> tp = (Map<String, Object>) race.get('ThirdPractice');
                    Map<String, Object> q  = (Map<String, Object>) race.get('Qualifying');

                    if (fp != null) {
                        row.put('firstPracticeDate', fp.get('date'));
                        row.put('firstPracticeTime', fp.get('time'));
                    }
                    if (sp != null) {
                        row.put('secondPracticeDate', sp.get('date'));
                        row.put('secondPracticeTime', sp.get('time'));
                    }
                    if (tp != null) {
                        row.put('thirdPracticeDate', tp.get('date'));
                        row.put('thirdPracticeTime', tp.get('time'));
                    }
                    if (q != null) {
                        row.put('qualifyingDate', q.get('date'));
                        row.put('qualifyingTime', q.get('time'));
                    }

                    Map<String, Object> circuitMap = (Map<String, Object>) race.get('Circuit');
                    Map<String, Object> location = (Map<String, Object>) circuitMap.get('Location');
                        Object circuitId   = circuitMap != null ? circuitMap.get('circuitId') : null;
                        Object circuitName = circuitMap != null ? circuitMap.get('circuitName') : null; 
                    if (circuitMap != null) {
                        row.put('circuitId',  circuitMap.get ('circuitId'));
                        row.put('circuitName', circuitMap.get ('circuitName'));
                        row.put('url', circuitMap.get('url')); 
                     }

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
            System.debug('Excepción en obtenerRace: ' + e.getMessage());
        }

        return result;
    }

        // generamos el AuraEnabled, para poder hacer pruebas dentro de la Developer Consol, ademas se utilizara para ejecutar el batch para la carga y para las LWC

        
                @AuraEnabled
                public static void saveRace() {
                    List<Map<String, Object>> raceData = giveRace();
                    List<race__c> raceToInsert = new List<race__c>();
                    List<circuit__c> circuitToUpsert = new List<circuit__c>();
                    
                    Set<String> circuitIds = new Set<String>();

                    for (Map<String, Object> ds : raceData) {

                        String circuitId = ((String) ds.get('circuitId')).trim().toLowerCase();
                        
                        if (!String.isBlank(circuitId)) circuitIds.add(circuitId);

                        // RACE //
                        race__c r = new race__c();
                        r.Name   = (String) ds.get('raceName');
                        r.url__c = (String) ds.get('url');
                        //r.round__c = (Integer) ds.get('round');
                        r.round__c = ds.get('round') != null ? Integer.valueOf(String.valueOf(ds.get('round'))) : null;
                        r.season__c =(String) ds.get('season');
                        r.raceNameId__c = (String) ds.get ('raceName');
                        
                        String timeStr = (String) ds.get('time'); // Ejemplo: "14:30:00"
                            if (!String.isBlank(timeStr)) {
                                List<String> parts = timeStr.replace('Z','').split(':');
                                Integer hour = Integer.valueOf(parts[0]);
                                Integer minute = Integer.valueOf(parts[1]);
                                Integer second = Integer.valueOf(parts[2]);
                                r.time__c = Time.newInstance(hour, minute, second, 0); // ✔ funciona en todas las versiones
                            }
                          String dateStr = (String) ds.get('date');
                        if (!String.isBlank(dateStr)) {
                            r.date__c = Date.valueOf(dateStr);
                        }

                         raceToInsert.add(r);

                        // CIRCUIT// 

                        if(!String.isBlank(circuitId)){
                        circuit__c c = new circuit__c ();
                        c.circuitId__c = circuitId;
                        c.Name = (String) ds.get('circuitName');
                        c.url__c = (String) ds.get('url');
                        if (ds.get('lat') != null) {
                            c.Location__Latitude__s = Decimal.valueOf(String.valueOf(ds.get('lat')));
                        }
                        if (ds.get('long') != null) {
                            c.Location__Longitude__s = Decimal.valueOf(String.valueOf(ds.get('long')));
                        }
                        c.locality__c = (String) ds.get('locality');
                        c.country__c = (String) ds.get('country');


                        circuitToUpsert.add(c);
                        }
                        
                    }
                       // UPSERT CIRCUIT

                    if (!circuitToUpsert.isEmpty()) {
                        Database.upsert(circuitToUpsert, circuit__c.Fields.circuitId__c, false);
                        }
                
                        //CONSTRUCCION DE CONSULTA SOQL PARA CIRCUIT
                    Map<String, Id> circuitMap = new Map<String, Id>();
                        for(circuit__c c : [SELECT Id,circuitId__c FROM circuit__c WHERE circuitId__c IN :circuitIds]) {
                            circuitMap.put(c.circuitId__c.trim().toLowerCase(), c.Id);
                        }
                        
                       //ASIGANCION DE LOOKUPS
                    Integer index = 0 ;
                        for (Map<String, Object> ds : raceData){
                            String CrId = ((String) ds.get('circuitId')).trim().toLowerCase();

                            raceToInsert[index].circuit__c = circuitMap.get(CrId);
                            index++;
                        }

                        // INSERT RACE



                    if (!raceToInsert.isEmpty()) {
                        Database.insert(raceToInsert, false);
                        System.debug('Registros insertados: ' + raceToInsert.size());
                    }
                }


}