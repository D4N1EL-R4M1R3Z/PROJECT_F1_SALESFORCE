public with sharing class qualifying {

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveQualifying() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2024/qualifying.json');
            req.setMethod('GET');

            HttpResponse res = http.send(req);
                
                // Deserializamos la respuesta comenzando con la estructura que mencina la Api

                        if (res.getStatusCode() == 200) {
                            Map<String, Object> jsonMap   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                            Map<String, Object> mrData    = (Map<String, Object>) jsonMap.get('MRData');
                            Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');

                            // Races es una LISTA
                            List<Object> races = (List<Object>) raceTable.get('Races');

                            for (Object raceObj : races) {
                                Map<String, Object> race = (Map<String, Object>) raceObj;

                                List<Object> qualifyingResults = (List<Object>) race.get('QualifyingResults');
                                if (qualifyingResults == null) continue;

                                for (Object qrObj : qualifyingResults) {
                                    Map<String, Object> qr = (Map<String, Object>) qrObj;

                                    // Creamos un Map plano para devolver la informacion que se encuentra dentro de la Api
                                    Map<String, Object> qualiMap = new Map<String, Object>();
                                    qualiMap.put('position', qr.get('position'));
                                    qualiMap.put('number', qr.get('number'));
                                    qualiMap.put('Q1', qr.get('Q1'));
                                    qualiMap.put('Q2', qr.get('Q2'));
                                    qualiMap.put('Q3', qr.get('Q3'));
                                    qualiMap.put('Driver', qr.get('Driver'));
                                    qualiMap.put('Constructor', qr.get('Constructor'));

                                    result.add(qualiMap);

                                    // Debug opcional
                                    System.debug(LoggingLevel.INFO,
                                        'Quali: pos=' + qr.get('position') +
                                        ', driver=' + ((Map<String,Object>) qr.get('Driver')).get('code') +
                                        ', team=' + ((Map<String,Object>) qr.get('Constructor')).get('name') +
                                        ', Q1=' + qr.get('Q1') +
                                        ', Q2=' + qr.get('Q2') +
                                        ', Q3=' + qr.get('Q3')
                                    );
                                }
                            }
                        }
            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage());
            }

        return result;
    }
                    
    
            // generamos el AuraEnabled, para poder hacer pruebas dentro de la Developer Consol, ademas se utilizara para ejecutar el batch para la carga y para las LWC

                @AuraEnabled
                public static void SaveQualifyingResults() {
                    List<Map<String, Object>> qualifyingData = giveQualifying();
                    List<qualifying__c> qualifyingToInsert = new List<qualifying__c>();

                    for (Map<String, Object> stat : qualifyingData) {
                        qualifying__c q = new qualifying__c();

                        // Convertir Q1, Q2, Q3 a Time
                        q.Q1__c = parseQuTime((String) stat.get('Q1'));
                        q.Q2__c = parseQuTime((String) stat.get('Q2'));
                        q.Q3__c = parseQuTime((String) stat.get('Q3'));

                        qualifyingToInsert.add(q);
                    }

                    if (!qualifyingToInsert.isEmpty()) {
                        Database.insert(qualifyingToInsert, false);
                        System.debug('Registros insertados (Quali): ' + qualifyingToInsert.size());
                    }
                }

                // Método helper fuera de cualquier bloque
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