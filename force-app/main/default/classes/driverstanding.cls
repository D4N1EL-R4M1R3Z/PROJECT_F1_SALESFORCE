public with sharing class driverstanding {
   @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> obtenerClasificacion() {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:pilotos2/ergast/f1/2025/driverstandings.json'); // se coloca la direccion Url de la api en forma de callout
        req.setMethod('GET');

        HttpResponse res = http.send(req);

        // 🔍 Debug para verificar la respuesta del API
        System.debug('Status Code: ' + res.getStatusCode());
        System.debug('Respuesta completa: ' + res.getBody());

        List<Map<String,Object>> result = new List<Map<String,Object>>();

                    if (res.getStatusCode() == 200) {
                        try {
                            
                        // se comienza a realizar el modelado usando un Wrapper anteriormente creado para pode abstraer la informacion de la Api
                            driverstandingWrapper.root data = (driverstandingWrapper.root) JSON.deserialize(res.getBody(), driverstandingWrapper.root.class);

                            if (data != null && data.MRData != null && data.MRData.StandingsTable != null &&
                                data.MRData.StandingsTable.StandingsLists != null && !data.MRData.StandingsTable.StandingsLists.isEmpty()) {

                                for (driverstandingWrapper.DriverStandings ds : data.MRData.StandingsTable.StandingsLists[0].DriverStandings) {
                                    Map<String,Object> row = new Map<String,Object>();
                                    row.put('driverId', ds.Driver.DriverId);
                                    row.put('givenName', ds.Driver.givenName);
                                    row.put('familyName', ds.Driver.familyName);
                                    row.put('dateOfBirth', ds.Driver.dateOfBirth);
                                    row.put('nationality', ds.Driver.nationality);
                                    row.put('url', ds.Driver.url);
                                    row.put('code', ds.Driver.code);
                                    row.put('permanentNumber', ds.Driver.permanentNumber);
                                    row.put('position', ds.position);
                                    row.put('points', ds.points);
                                    row.put('wins', ds.wins);
                                    result.add(row);
                                }
                            }
                        } catch (Exception e){
                            System.debug('Error con Wrapper, usando parseo dinámico: ' + e.getMessage());
                        }
                    }
                    return result;
    }


                // generamos el AuraEnabled, para poder hacer pruebas dentro de la Developer Consol, ademas se utilizara para ejecutar el batch para la carga y para las LWC
                
                @AuraEnabled
                public static void guardarDrivers() {
                    List<Map<String,Object>> standings = obtenerClasificacion();
                    List<driverstanding__c> driversToInsert = new List<driverstanding__c>();

                    for (Map<String,Object> ds : standings) {
                        driverstanding__c d = new driverstanding__c();
                        d.Name = (String) ds.get('givenName') + ' ' + (String) ds.get('familyName');
                       // d.driverId__c = (String) ds.get('driverId');
                        d.givenName__c = (String) ds.get('givenName');
                        d.familyName__c = (String) ds.get('familyName');
                        d.dateOfBirth__c = ds.get('dateOfBirth') != null ? Date.valueOf((String) ds.get('dateOfBirth')) : null;
                        d.nationality__c = (String) ds.get('nationality');
                        d.url__c = (String) ds.get('url');
                        d.code__c = (String) ds.get('code');
                        d.permanentNumber__c = ds.get('permanentNumber') != null ? Integer.valueOf(String.valueOf(ds.get('permanentNumber'))) : null;
                        driversToInsert.add(d);
                    }
                    insert driversToInsert;
                }
}