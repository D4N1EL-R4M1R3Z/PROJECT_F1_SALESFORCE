public with sharing class constructorstanding {
//     @AuraEnabled
//     public static List<Map<String, Object>> givenconstructorstanding() {
//         List<Map<String, Object>> result = new List<Map<String, Object>>();

//         try {
//             Http http = new Http();
//             HttpRequest req = new HttpRequest();
//             req.setEndpoint('callout:pilotos2/ergast/f1/2025/constructorstandings.json');
//             req.setMethod('GET');

//             HttpResponse res = http.send(req);
                
//                     if (res.getStatusCode() == 200) {
//                         ConstructorStandingWrapper.Root data = (ConstructorStandingWrapper.root)
//                             JSON.deserialize(res.getBody(), ConstructorStandingWrapper.root.class);

//                         if (data != null && data.MRData != null && data.MRData.StandingsTable != null &&
//                             data.MRData.StandingsTable.StandingsLists != null && !data.MRData.StandingsTable.StandingsLists.isEmpty()) {

//                             for (ConstructorStandingWrapper.StandingsLists constd : data.MRData.StandingsTable.StandingsLists) {
//                                 if (constd.ConstructorStandings != null && !constd.ConstructorStandings.isEmpty()) {
//                                     for (ConstructorStandingWrapper.ConstructorStandings consStanding : constd.ConstructorStandings) {
//                                         if (consStanding.Constructor != null) {
//                                             Map<String, Object> row = new Map<String, Object>();
//                                             row.put('constructorId', consStanding.Constructor.constructorId);
//                                             row.put('url', consStanding.Constructor.url);
//                                             row.put('name', consStanding.Constructor.name);
//                                             row.put('nationality', consStanding.Constructor.nationality);
//                                             //////////////////////////////////////////////////////////////////
//                                             row.put('position', consStanding.position);
//                                             row.put('positionText', consStanding.positionText);
//                                             row.put('points', consStanding.points);
//                                             row.put('wins', consStanding.wins);
//                                             //////////////////////////////////////////////////////////////////
//                                             row.put('season', constd.season);
//                                             row.put('round', constd.round);

//                                             result.add(row);
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     } else {
//                         System.debug('Error en el callout: ' + res.getStatus());
//                     }

            
//         } catch (Exception e) {
//             System.debug('Excepción: ' + e.getMessage());
//         }

//         return result;
//     }

//      @AuraEnabled
//     public static void saveconstructorstanding() {
//         List<Map<String,Object>> constructorTable = givenconstructorstanding();
//         List<constructorstanding__c> constructorstandingToInsert = new List<constructorstanding__c>();

//         for (Map<String,Object> cons : constructorTable) {
//             constructorstanding__c constStad = new constructorstanding__c();
//             constStad.Name = (String) cons.get('name');
//             constStad.constructorId__c = (String) cons.get('constructorId');
//             constStad.url__c = (String) cons.get('url'); 
//             constStad.name__c = (String) cons.get('name');
//             constStad.nationality__c = (String) cons.get('nationality');
//             constStad.position__c = (String) cons.get('position');
//             constStad.points__c = (String) cons.get('points');
//             constStad.wins__c = (String) cons.get('wins');
//             constStad.season__c = (String) cons.get('season');
//             constStad.round__c = (String) cons.get('round');
//             constructorstandingToInsert.add(constStad);
//          }

//         if (!constructorstandingToInsert.isEmpty()) {
//             insert constructorstandingToInsert;
//         }
//      }
}