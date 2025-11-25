public with sharing class  constructor {

    @AuraEnabled
    public static List<Map<String, Object>> givenConstructors() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:pilotos2/ergast/f1/2025/constructors.json');
            req.setMethod('GET');

            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                constructorWrapper.root data = (constructorWrapper.root) JSON.deserialize(res.getBody(), constructorWrapper.root.class);

                if (data != null && data.MRData != null && data.MRData.constructorTable != null &&
                    data.MRData.constructorTable.constructors != null && !data.MRData.constructorTable.constructors.isEmpty()) {

                 
                    for (constructorWrapper.constructor cons : data.MRData.constructorTable.constructors) {
                        Map<String,Object> row = new Map<String,Object>();
                        row.put('constructorId', cons.constructorId);
                        row.put('url', cons.url);
                        row.put('name', cons.name);
                        row.put('nationality', cons.nationality);
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
    public static void saveConstructors() {
        List<Map<String,Object>> constructorTable = givenConstructors();
        List<constructor__c> constructorToInsert = new List<constructor__c>();

        for (Map<String,Object> cons : constructorTable) {
            constructor__c constObj = new constructor__c();
            constObj.Name = (String) cons.get('name');
            constObj.constructorId__c = (String) cons.get('constructorId');
            constObj.url__c = (String) cons.get('url');
            constObj.name__c = (String) cons.get('name');
            constObj.nationality__c = (String) cons.get('nationality');
            constructorToInsert.add(constObj);
        }

        if (!constructorToInsert.isEmpty()) {
            insert constructorToInsert;
        }
    }
}