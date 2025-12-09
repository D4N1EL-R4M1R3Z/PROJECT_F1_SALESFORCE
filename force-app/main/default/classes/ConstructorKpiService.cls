public with sharing class ConstructorKpiService {
  @AuraEnabled(cacheable=true)
    public static Integer countConstructor() {
        // Busca el SObjectType de forma case-insensitive
        Schema.SObjectType sType = resolveSObjectTypeIgnoreCase('constructor__c');
        if (sType == null) {
            throw new AuraHandledException('No existe un objeto llamado constructor__c / constructor__c en esta org.');
        }

        Schema.DescribeSObjectResult d = sType.getDescribe();

        // Seguridad: respeta permisos del usuario
        if (!d.isAccessible()) {
            throw new AuraHandledException('El usuario no tiene permiso de lectura sobre ' + d.getName());
        }

        // Usa el nombre real (incluye namespace si existe)
        String objectName = d.getName();
        String soql = 'SELECT count() FROM ' + objectName;
        return (Integer) Database.countQuery(soql);
    }

    /** Utilidad: resuelve SObjectType ignorando mayúsculas/minúsculas. */
    private static Schema.SObjectType resolveSObjectTypeIgnoreCase(String apiName) {
        Map<String, Schema.SObjectType> all = Schema.getGlobalDescribe();
        for (String key : all.keySet()) {
            if (key != null && key.equalsIgnoreCase(apiName)) {
                return all.get(key);
            }
        }
        return null;
    }
}