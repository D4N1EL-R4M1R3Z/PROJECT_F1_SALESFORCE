public with sharing class status {
   @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> giveStatus() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

                            try {
                                Http http = new Http();
                                HttpRequest req = new HttpRequest();
                                req.setEndpoint('callout:pilotos2/ergast/f1/status.json'); 
                                req.setMethod('GET');

                                HttpResponse res = http.send(req);

                                if (res.getStatusCode() == 200){

                                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                                    Map<String,Object> mrData = (Map<String,Object>)jsonMap.get('MRData');
                                    Map<String,Object> statusTable = (Map<String,Object>)mrData.get('StatusTable');
                                    list<Object> Statuslist = (list<Object>)statusTable.get('Status');
                                    for (object obj : Statuslist){      
                                        map<String,Object> status = (map<String,Object>)obj;         
                                        Map<String,Object> row = new Map<String,Object>();
                                        row.put('statusId', status.get('statusId'));
                                        row.put('status', status.get('status'));
                                        result.add(row); 

                                            result.add(row);
                                        }

                    

                            }
                            } catch (Exception e) {
                                        System.debug('Error: ' + e.getMessage());
                                    }
                        return result;
                        }   

                @AuraEnabled
                public static void SaveSatatus() {
                    List<Map<String, Object>> statustData = giveStatus();
                    List<Status__c> statustoInsert = new List<Status__c>();

                    for (Map<String, Object> stat : statustData){

                        status__c s = new status__c();
                        s.statusId__c = Integer.valueOf(String.valueOf(stat.get('statusId')));
                        s.status__c = (string)stat.get('status');
                        statustoInsert.add(s);
                }
                if (!statustoInsert.isEmpty()) {
                    Database.insert(statustoInsert, false);
                    System.debug('Registros insertados: ' + statustoInsert.size());
                }
            }
}