// public with sharing class TeamFantasyController {
    
//     @AuraEnabled(cacheable=true)
//     public static Map<String, Object> getFantasyData() {
//         Map<String, Object> result = new Map<String, Object>();
        
//         // Obtener pilotos con sus datos
//         List<driver__c> drivers = [
//             SELECT Id, Name, driverId__c, code__c, nationality__c, 
//                    permanentNumber__c, constructor__c, url__c
//             FROM driver__c
//             ORDER BY Name
//         ];
        
//         // Obtener constructores
//         List<constructor__c> constructors = [
//             SELECT Id, Name, constructorId__c, nationality__c, url__c
//             FROM constructor__c
//             ORDER BY Name
//         ];
        
//         // Obtener los últimos puntos de la temporada
//         List<result__c> latestResults = [
//             SELECT driver__c, points__c
//             FROM result__c
//             WHERE driver__c != null
//             ORDER BY CreatedDate DESC
//             LIMIT 100
//         ];
        
//         result.put('drivers', drivers);
//         result.put('constructors', constructors);
//         result.put('latestResults', latestResults);
        
//         return result;
//     }
    
//     @AuraEnabled
//     public static String saveTeamFantasy(String teamName, List<String> driverIds, List<String> constructorIds) {
//         try {
//             // Validar que sean exactamente 5 pilotos y 2 escuderías
//             if(driverIds.size() != 5) {
//                 throw new AuraHandledException('Debes seleccionar exactamente 5 pilotos');
//             }
//             if(constructorIds.size() != 2) {
//                 throw new AuraHandledException('Debes seleccionar exactamente 2 escuderías');
//             }
            
//             // Crear el equipo fantasy
//             Team_Fantasy__c team = new Team_Fantasy__c();
//             team.Name = teamName;
//             insert team;
            
//             // Aquí deberías crear los registros de relación entre el equipo y los pilotos/constructores
//             // Esto dependerá de tu objeto intermedio de relación
            
//             return team.Id;
            
//         } catch(Exception e) {
//             throw new AuraHandledException('Error al guardar el equipo: ' + e.getMessage());
//         }
//     }
    
//     @AuraEnabled(cacheable=true)
//     public static Integer calculateTeamValue(List<String> driverIds, List<String> constructorIds) {
//         // Implementar lógica de cálculo de valor del equipo (100M máximo)
//         // Por ahora retornamos un valor de ejemplo
//         Integer totalValue = 0;
        
//         // Aquí implementarías la lógica de precios de pilotos y constructores
        
//         return totalValue;
//     }
// }

public with sharing class TeamFantasyController {
    @AuraEnabled
    public static Id createTeamFantasy(String driver1Id, String driver2Id, String driver3Id, String driver4Id, String driver5Id, String constructor1Id, String constructor2Id) {
        Team_Fantasy__c teamFantasy = new Team_Fantasy__c();
        
        teamFantasy.Driver_1__c = driver1Id;
        teamFantasy.Driver_2__c = driver2Id;
        teamFantasy.Driver_3__c = driver3Id;
        teamFantasy.Driver_4__c = driver4Id;
        teamFantasy.Driver_5__c = driver5Id;
        teamFantasy.Constructor_1__c = constructor1Id;
        teamFantasy.Constructor_2__c = constructor2Id;

        insert teamFantasy;

        return teamFantasy.Id;
    }
}