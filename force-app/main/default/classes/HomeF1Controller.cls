public with sharing class HomeF1Controller {

    // Circuitos (solo lectura; usado por @wire, debe ser cacheable)
    @AuraEnabled(cacheable=true)
    public static List<Circuit__c> getCircuits() {
        // Ajusta campos si necesitas más (p.ej. País__c)
        return [
            SELECT Id, Name, CreatedDate
            FROM circuit__c
            WITH SECURITY_ENFORCED
            ORDER BY Name ASC
            LIMIT  5
        ];
    }

    // Constructores (incluye ranking)
    @AuraEnabled(cacheable=true)
    public static List<Constructor__c> getConstructors() {
        // Ajusta Rank__c si tu field API es distinto
        return [
            SELECT Id, Name, CreatedDate
            FROM constructor__c
            WITH SECURITY_ENFORCED
            ORDER BY Name 
            LIMIT 5
        ];
    }
}