public with sharing class race {

//     @AuraEnabled(cacheable=true)
//     public static List<Map<String, Object>> giveRace() {
//         List<Map<String, Object>> result = new List<Map<String, Object>>();

//         try {
//             Http http = new Http();
//             HttpRequest req = new HttpRequest();
//             req.setEndpoint('callout:pilotos2/ergast/f1/2025/races.json'); // Named Credential
//             req.setMethod('GET');

//             HttpResponse res = http.send(req);

//                 // Deserializamos la respuesta comenzando con la estructura que mencina la Api


//             if (res.getStatusCode() == 200) {
//                 Map<String, Object> jsonMap   = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
//                 Map<String, Object> mrData    = (Map<String, Object>) jsonMap.get('MRData');
//                 Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
//                 List<Object> racesList        = (List<Object>) raceTable.get('Races');

//                 for (Object obj : racesList) {
//                     Map<String, Object> race = (Map<String, Object>) obj;

//                     Map<String, Object> row = new Map<String, Object>();
//                     row.put('raceName', race.get('raceName'));
//                     row.put('url',      race.get('url'));
//                     row.put('date',     race.get('date')); 
//                     row.put('time',     race.get('time')); 
//                     row.put('season',   race.get('season'));
//                     row.put('round',    race.get('round'));

//                     // mencionamos en donde se obtiene los datos de Prácticas y Qualifying
//                     Map<String, Object> fp = (Map<String, Object>) race.get('FirstPractice');
//                     Map<String, Object> sp = (Map<String, Object>) race.get('SecondPractice');
//                     Map<String, Object> tp = (Map<String, Object>) race.get('ThirdPractice');
//                     Map<String, Object> q  = (Map<String, Object>) race.get('Qualifying');

//                     if (fp != null) {
//                         row.put('firstPracticeDate', fp.get('date'));
//                         row.put('firstPracticeTime', fp.get('time'));
//                     }
//                     if (sp != null) {
//                         row.put('secondPracticeDate', sp.get('date'));
//                         row.put('secondPracticeTime', sp.get('time'));
//                     }
//                     if (tp != null) {
//                         row.put('thirdPracticeDate', tp.get('date'));
//                         row.put('thirdPracticeTime', tp.get('time'));
//                     }
//                     if (q != null) {
//                         row.put('qualifyingDate', q.get('date'));
//                         row.put('qualifyingTime', q.get('time'));
//                     }

//                     result.add(row);
//                 }
//             } else {
//                 System.debug('Error en la llamada HTTP: ' + res.getStatusCode());
//             }
//         } catch (Exception e) {
//             System.debug('Excepción en obtenerRace: ' + e.getMessage());
//         }

//         return result;
//     }

//         // generamos el AuraEnabled, para poder hacer pruebas dentro de la Developer Consol, ademas se utilizara para ejecutar el batch para la carga y para las LWC

        
//                 @AuraEnabled
//                 public static void saveRace() {
//                     List<Map<String, Object>> raceData = giveRace();
//                     List<race__c> raceToInsert = new List<race__c>();

//                     for (Map<String, Object> ds : raceData) {
//                         race__c r = new race__c();
//                         r.Name   = (String) ds.get('raceName');
//                         r.url__c = (String) ds.get('url');
//                         r.round__c = (Integer) ds.get('round');
//                         r.season__c =(String) ds.get('season');
//                         r.raceNameId__c = (String) ds.get ('raceName');
//                         String dateStr = (String) ds.get('date');
//                         if (!String.isBlank(dateStr)) {
//                             r.date__c = Date.valueOf(dateStr);
//                         }

//                         raceToInsert.add(r);
//                     }

//                     if (!raceToInsert.isEmpty()) {
//                         Database.insert(raceToInsert, false);
//                         System.debug('Registros insertados: ' + raceToInsert.size());
//                     }
//                 }


}