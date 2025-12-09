public with sharing class CircuitKpiService {
    /**
     * Devuelve el total de registros del objeto circuit__c / Circuit__c
     * Resolviendo el API Name sin importar mayúsculas/minúsculas y namespace.
     */
    @AuraEnabled(cacheable=true)
    public static Integer countCircuits() {
        // Busca el SObjectType de forma case-insensitive
        Schema.SObjectType sType = resolveSObjectTypeIgnoreCase('circuit__c');
        if (sType == null) {
            throw new AuraHandledException('No existe un objeto llamado circuit__c / Circuit__c en esta org.');
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

    /**
     * Opción alternativa (si quieres ignorar sharing y ver el total absoluto).
     * ¡Úsalo solo si el caso de negocio lo permite!
     */
    /*@AuraEnabled(cacheable=true)
    public static Integer countCircuitsWithoutSharing() {
        System.assert(false, 'Solo habilita esta opción si realmente lo necesitas.');
        return 0;
    }*/

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