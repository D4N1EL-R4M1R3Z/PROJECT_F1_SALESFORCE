public with sharing class driver {
     @AuraEnabled
    public static List<Map<String, Object>> givenDriver() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2025/drivers.json');
            req.setMethod('GET');

            HttpResponse res = http.send(req);

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

    
    @AuraEnabled       
        public static void saveDrivers() {
        List<Map<String,Object>> standings = givenDriver();
        List<Driver__c> driversToInsert = new List<Driver__c>();

        for (Map<String,Object> ds : standings) {
            Driver__c d = new Driver__c();
            d.Name = (String) ds.get('givenName') + ' ' + (String) ds.get('familyName');
            d.driverId__c = (String) ds.get('driverId');
            d.givenName__c = (String) ds.get('givenName');
            d.familyName__c = (String) ds.get('familyName');
            d.dateOfBirth__c = ds.get('dateOfBirth') != null ? Date.valueOf((DATE) ds.get('dateOfBirth')) : null;
            d.nationality__c = (String) ds.get('nationality');
            d.url__c = (String) ds.get('url');
            d.code__c = (String) ds.get('code');
            d.permanentNumber__c = ds.get('permanentNumber') != null ? Integer.valueOf(String.valueOf(ds.get('permanentNumber'))) : null;
             Id defaultConstructorId;
                        try {
                            Constructor__c defaultCtor = [
                                SELECT Id
                                FROM Constructor__c
                                WHERE Name = 'Unknown'
                                LIMIT 1
                            ];
                            defaultConstructorId = defaultCtor.Id;
                        } catch (Exception e) {
                            System.debug('Constructor "Unknown" no existe. Se intentará crear. Detalle: ' + e.getMessage());
                        }

            if (defaultConstructorId == null) {
                            try {
                                Constructor__c newDefault = new Constructor__c(Name = 'Unknown');
                                insert newDefault;
                                defaultConstructorId = newDefault.Id;
                                System.debug('Constructor "Unknown" creado con Id: ' + defaultConstructorId);
                            } catch (DmlException s) {
                                System.debug('No se pudo crear el constructor por defecto: ' + s.getMessage());
                                // Si no podemos garantizar constructor__c, evita el insert para no lanzar REQUIRED_FIELD_MISSING
                                return;
                            }
    }
                     d.constructor__c = defaultConstructorId;
            driversToInsert.add(d);
        }
        insert driversToInsert;
    }

   
}