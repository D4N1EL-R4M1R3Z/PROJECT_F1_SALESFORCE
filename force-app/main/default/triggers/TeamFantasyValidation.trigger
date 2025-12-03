trigger TeamFantasyValidation on Team_Fantasy__c (before insert, before update) 
{
    // Límites estáticos 2 drivers y 5 constructors
    Integer maxDrivers = 5;
    Integer maxConstructors = 2;

    // Validación de duplicados y límites para cada registro se crea o actualiza
    for (Team_Fantasy__c team : Trigger.new) 
    {
        Set<Id> driverIds = new Set<Id>();
        Set<Id> constructorIds = new Set<Id>();

        // Pilotos (lookup a Piloto__c)
        List<Id> drivers = new List<Id>
        {
            team.Driver_1__c, team.Driver_2__c, team.Driver_3__c,
            team.Driver_4__c, team.Driver_5__c
        };
        // Constructores (lookup a Escuderia__c)
        List<Id> constructors = new List<Id>
        {
            team.Constructor_1__c, team.Constructor_2__c
        };

        Integer driverCount = 0;
        for (Id d : drivers) 
        {
            if (d != null) 
            {
                driverIds.add(d);
                driverCount++;
            }
        }

        Integer constructorCount = 0;
        for (Id c : constructors) 
        {
            if (c != null) 
            {
                constructorIds.add(c);
                constructorCount++;
            }
        }

        // Si hay duplicados entonces el tamaño del set será menor
        if (driverIds.size() < driverCount) 
        {
            team.addError('No puedes seleccionar el mismo piloto más de una vez.');
        }
        if (constructorIds.size() < constructorCount) 
        {
            team.addError('No puedes seleccionar la misma escudería dos veces.');
        }

        // Límites
        if (driverCount > maxDrivers) 
        {
            team.addError('Has seleccionado más pilotos de los permitidos (5).');
        }
        if (constructorCount > maxConstructors) 
        {
            team.addError('Has seleccionado más escuderías de las permitidas (2).');
        }
    }
}