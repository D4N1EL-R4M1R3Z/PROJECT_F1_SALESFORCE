public with sharing class RaceResultsController 
{
    public class RaceResultDTO {
        @AuraEnabled public Integer position;
        @AuraEnabled public String  driverName;
        @AuraEnabled public String  team;
        @AuraEnabled public Id      driverId;
        @AuraEnabled public String  photoUrl;

        // Constructor de 5 parámetros (si lo necesitas)
        public RaceResultDTO(Integer position, String driverName, String team, Id driverId, String photoUrl) {
            this.position   = position;
            this.driverName = driverName;
            this.team       = team;
            this.driverId   = driverId;
            this.photoUrl   = photoUrl;
        }

        // 👉 Constructor de 4 parámetros (el que coincide con tu "new RaceResultDTO(...)")
        public RaceResultDTO(Integer position, String driverName, String team, Id driverId) {
            this.position   = position;
            this.driverName = driverName;
            this.team       = team;
            this.driverId   = driverId;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<RaceResultDTO> getRecentResults(Integer limitSize) {
        Integer pageSize = (limitSize == null || limitSize <= 0) ? 10 : Math.min(limitSize, 200);

        List<Result__c> rows = [
            SELECT Id,
                   Position__c,
                   Driver__c,
                   Driver__r.Name,
                   Constructor__c
            FROM Result__c
            WHERE Position__c != null
            ORDER BY Position__c ASC
            LIMIT :pageSize
        ];

        List<RaceResultDTO> dtos = new List<RaceResultDTO>();
        for (Result__c r : rows) {
            Integer pos      = (r.Position__c == null) ? null : Integer.valueOf(r.Position__c);
            String  name     = (r.Driver__r != null) ? r.Driver__r.Name : null;
            String  team     = r.Constructor__c;
            Id      driverId = r.Driver__c;

            // 👉 Ahora sí existe este constructor
            dtos.add(new RaceResultDTO(pos, name, team, driverId));
        }
        return dtos;
    }
}