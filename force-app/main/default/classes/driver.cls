public with sharing class driver 
{

    // ###############################################################
    //  Método que consume la API de drivers y devuelve un List<Map>
    //  *** NO toca constructor aquí porque /drivers.json no lo trae. ***
    // ###############################################################
    @AuraEnabled
    public static List<Map<String, Object>> givenDriver() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2025/drivers.json'); // se coloca la direccion Url de la api en forma de callout
            req.setMethod('GET');

            HttpResponse res = http.send(req);

            // se comienza a realizar el modelado usando un Wrapper anteriormente creado
            if (res.getStatusCode() == 200) {
                driverWrapper.root data = (driverWrapper.root) JSON.deserialize(res.getBody(), driverWrapper.root.class);

                if (data != null && data.MRData != null && data.MRData.DriverTable != null &&
                    data.MRData.DriverTable.drivers != null && !data.MRData.DriverTable.drivers.isEmpty()) {

                    for (driverWrapper.Driver dr : data.MRData.DriverTable.drivers) {
                        Map<String,Object> row = new Map<String,Object>();
                        row.put('driverId', dr.driverId);
                        row.put('permanentNumber', dr.permanentNumber);
                        row.put('code', dr.code);
                        row.put('url', dr.url);
                        row.put('givenName', dr.givenName);
                        row.put('familyName', dr.familyName);
                        row.put('dateOfBirth', dr.dateOfBirth);
                        row.put('nationality', dr.nationality);
                        // NOTA: aquí NO viene constructor en /drivers.json
                        result.add(row);
                    }
                }
            } else {
                System.debug('Error en el callout: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Excepción: ' + e.getMessage());
        }

        return result;
    }

    // ##################################################################
    //  NUEVO: Método auxiliar para mapear driverId -> constructorId
    //  Fuente: /results.json, igual que tu clase result
    // ##################################################################
    public static Map<String, String> getDriverConstructorMap() {
        Map<String, String> driverConstructorMap = new Map<String, String>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2025/results.json'); // Ajusta Named Credential si cambia
            req.setMethod('GET');

            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> mrData = (Map<String, Object>) jsonMap.get('MRData');
                Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
                List<Object> racesList = (List<Object>) raceTable.get('Races');

                if (racesList != null) {
                    for (Object raceObj : racesList) {
                        Map<String, Object> raceMap = (Map<String, Object>) raceObj;
                        List<Object> resultsList = (List<Object>) raceMap.get('Results');

                        if (resultsList != null) {
                            for (Object resObj : resultsList) {
                                Map<String, Object> resMap = (Map<String, Object>) resObj;

                                Map<String, Object> driverMap = (Map<String, Object>) resMap.get('Driver');
                                Map<String, Object> constructorMap = (Map<String, Object>) resMap.get('Constructor');

                                if (driverMap != null && constructorMap != null) {
                                    String driverId = (String) driverMap.get('driverId');
                                    String constructorId = (String) constructorMap.get('constructorId');

                                    // Si hay varios resultados del mismo driver en la temporada,
                                    // este mapa se irá "actualizando". Si prefieres conservar el primero, verifica antes:
                                    // if (!driverConstructorMap.containsKey(driverId)) { ... }

                                    driverConstructorMap.put(driverId, constructorId);
                                }
                            }
                        }
                    }
                }
            } else {
                System.debug('Error en callout /results.json: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Error en getDriverConstructorMap: ' + e.getMessage());
        }

        return driverConstructorMap;
    }

    // ##################################################################
    //  Guardado en objeto Driver__c
    //  Se mantiene tu estructura. Aquí sí asignamos constructor__c.
    // ##################################################################
    @AuraEnabled
    public static void saveDrivers() {
        List<Map<String,Object>> standings = givenDriver();

        // NUEVO: obtenemos el mapa driverId -> constructorId
        Map<String, String> driverConstructorMap = getDriverConstructorMap();

        List<Driver__c> driversToInsert = new List<Driver__c>();

        for (Map<String,Object> ds : standings) {
            Driver__c d = new Driver__c();

            d.Name = (String) ds.get('givenName') + ' ' + (String) ds.get('familyName');
            d.driverId__c = (String) ds.get('driverId');
            d.givenName__c = (String) ds.get('givenName');
            d.familyName__c = (String) ds.get('familyName');

            // Manejo seguro de fecha desde API (string ISO) -> Date
            d.dateOfBirth__c = ds.get('dateOfBirth') != null ? Date.valueOf((DATE) ds.get('dateOfBirth')) : null;

            d.nationality__c = (String) ds.get('nationality');
            d.url__c = (String) ds.get('url');
            d.code__c = (String) ds.get('code');
            d.permanentNumber__c = ds.get('permanentNumber') != null
                ? Integer.valueOf(String.valueOf(ds.get('permanentNumber')))
                : null;

            // --------------- NUEVO: asignar constructor ---------------
            // Si el campo Driver__c.constructor__c es TEXT (almacenamos constructorId):
            String driverId = (String) ds.get('driverId');
            if (driverConstructorMap.containsKey(driverId)) {
                d.constructor__c = driverConstructorMap.get(driverId);
            }

            driversToInsert.add(d);
        }

        insert driversToInsert;
    }

}



// public with sharing class driver {
//      @AuraEnabled
//     public static List<Map<String, Object>> givenDriver() 
//     {
//         List<Map<String, Object>> result = new List<Map<String, Object>>();

//         try {
//             Http http = new Http();
//             HttpRequest req = new HttpRequest();
//             req.setEndpoint('callout:pilotos2/ergast/f1/2025/drivers.json'); // se coloca la direccion Url de la api en forma de callout
//             req.setMethod('GET');

//             HttpResponse res = http.send(req);
                
//                 // se comienza a realizar el modelado usando un Wrapper anteriormente creado para pode abstraer la informacion de la Api
            
//                         if (res.getStatusCode() == 200) {
//                             driverWrapper.root data = (driverWrapper.root) JSON.deserialize(res.getBody(), driverWrapper.root.class);

//                             if (data != null && data.MRData != null && data.MRData.DriverTable != null &&
//                                 data.MRData.DriverTable.drivers != null && !data.MRData.DriverTable.drivers.isEmpty()) {

                            
//                                 for (driverWrapper.Driver dr : data.MRData.DriverTable.drivers) {
//                                     Map<String,Object> row = new Map<String,Object>();
//                                     row.put('driverId', dr.driverId);
//                                     row.put('permanentNumber', dr.permanentNumber);
//                                     row.put('code', dr.code);
//                                     row.put('url', dr.url);
//                                     row.put('givenName', dr.givenName);
//                                     row.put('familyName', dr.familyName);
//                                     row.put('dateOfBirth', dr.dateOfBirth);
//                                     row.put('nationality', dr.nationality);
//                                     result.add(row);
//                                 }

//                             }
//                         } else {
//                             System.debug('Error en el callout: ' + res.getStatus());
//                         }
//                     } catch (Exception e) {
//                         System.debug('Excepción: ' + e.getMessage());
//                     }

//                     return result;
//                 }

//         // generamos el AuraEnabled, para poder hacer pruebas dentro de la Developer Consol, ademas se utilizara para ejecutar el batch para la carga y para las LWC
    
//                     @AuraEnabled       
//                         public static void saveDrivers() 
//                         {
//                         List<Map<String,Object>> standings = givenDriver();
//                         List<Driver__c> driversToInsert = new List<Driver__c>();

//                         for (Map<String,Object> ds : standings) {
//                             Driver__c d = new Driver__c();
//                             d.Name = (String) ds.get('givenName') + ' ' + (String) ds.get('familyName');
//                             d.driverId__c = (String) ds.get('driverId');
//                             d.givenName__c = (String) ds.get('givenName');
//                             d.familyName__c = (String) ds.get('familyName');
//                             d.dateOfBirth__c = ds.get('dateOfBirth') != null ? Date.valueOf((DATE) ds.get('dateOfBirth')) : null;
//                             d.nationality__c = (String) ds.get('nationality');
//                             d.url__c = (String) ds.get('url');
//                             d.code__c = (String) ds.get('code');
//                             d.permanentNumber__c = ds.get('permanentNumber') != null ? Integer.valueOf(String.valueOf(ds.get('permanentNumber'))) : null;
                      
//                             driversToInsert.add(d);
//                         }
//                         insert driversToInsert;
//                     }

//     private static Map<String, String> getDriverConstructorMap() {
//         Map<String, String> driverConstructorMap = new Map<String, String>();
//         try {
//             Http http = new Http();
//             HttpRequest req = new HttpRequest();
//             req.setEndpoint('callout:pilotos2/ergast/f1/2025/results.json');
//             req.setMethod('GET');
//             HttpResponse res = http.send(req);

//             if (res.getStatusCode() == 200) {
//                 Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
//                 Map<String, Object> mrData = (Map<String, Object>) jsonMap.get('MRData');
//                 Map<String, Object> raceTable = (Map<String, Object>) mrData.get('RaceTable');
//                 List<Object> racesList = (List<Object>) raceTable.get('Races');

//                 for (Object raceObj : racesList) {
//                     Map<String, Object> raceMap = (Map<String, Object>) raceObj;
//                     List<Object> resultsList = (List<Object>) raceMap.get('Results');
//                     if (resultsList != null) {
//                         for (Object resObj : resultsList) {
//                             Map<String, Object> resMap = (Map<String, Object>) resObj;
//                             Map<String, Object> driverMap = (Map<String, Object>) resMap.get('Driver');
//                             Map<String, Object> constructorMap = (Map<String, Object>) resMap.get('Constructor');
//                             if (driverMap != null && constructorMap != null) {
//                                 String driverId = (String) driverMap.get('driverId');
//                                 String constructorId = (String) constructorMap.get('constructorId');
//                                 driverConstructorMap.put(driverId, constructorId);
//                             }
//                         }
//                     }
//                 }
//             }
//         } catch (Exception e) {
//             System.debug('Error en getDriverConstructorMap: ' + e.getMessage());
//         }
//         return driverConstructorMap;
//     }


   
// }