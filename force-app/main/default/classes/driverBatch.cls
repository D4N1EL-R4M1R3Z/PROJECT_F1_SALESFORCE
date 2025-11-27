global class driverBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    // Cache del constructor por defecto para no hacer SOQL/DML en cada iteración
    private Id defaultConstructorId;

    global Iterable<SObject> start(Database.BatchableContext bc) {
        // 1) Asegurar que exista el Constructor "Unknown" antes de ejecutar
        try {
            Constructor__c defaultCtor = [
                SELECT Id
                FROM Constructor__c
                WHERE Name = 'Unknown'
                LIMIT 1
            ];
            defaultConstructorId = defaultCtor.Id;
        } catch (Exception e) {
            // No existe: intentamos crearlo
            try {
                Constructor__c newDefault = new Constructor__c(Name = 'Unknown');
                insert newDefault;
                defaultConstructorId = newDefault.Id;
                System.debug('Constructor "Unknown" creado con Id: ' + defaultConstructorId);
            } catch (DmlException dmle) {
                System.debug('No se pudo crear el constructor por defecto: ' + dmle.getMessage());
                // Si no garantizamos el constructor__c, devolvemos un iterable dummy para que el batch termine sin procesar
                return new List<SObject>{ new Account() };
            }
        }

        // Dummy record para que el batch siempre se ejecute
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // 2) Obtener datos desde la fuente
            List<Map<String, Object>> standings = driver.givenDriver();
            System.debug('Cantidad de drivers obtenidos: ' + standings.size());

            List<Driver__c> driversToUpsert = new List<Driver__c>();

            for (Map<String, Object> ds : standings) {
                Driver__c d = new Driver__c();

                // Nombre compuesto
                String givenName = (String) ds.get('givenName');
                String familyName = (String) ds.get('familyName');
                d.Name = (givenName != null ? givenName : '') + ' ' + (familyName != null ? familyName : '');

                // Campos base
                d.driverId__c      = (String) ds.get('driverId');
                d.givenName__c     = givenName;
                d.familyName__c    = familyName;
                d.nationality__c   = (String) ds.get('nationality');
                d.url__c           = (String) ds.get('url');
                d.code__c          = (String) ds.get('code');

                // dateOfBirth: convertir de String (YYYY-MM-DD) a Date de forma segura
                Object dobObj = ds.get('dateOfBirth');
                if (dobObj != null) {
                    try {
                        // Asumiendo que viene como String ISO "YYYY-MM-DD"
                        d.dateOfBirth__c = Date.valueOf(String.valueOf(dobObj));
                    } catch (Exception pe) {
                        System.debug('Fecha inválida para driverId ' + d.driverId__c + ': ' + dobObj + ' -> ' + pe.getMessage());
                    }
                }

                // permanentNumber: puede venir como String o Number — convertir de forma segura
                Object permObj = ds.get('permanentNumber');
                if (permObj != null) {
                    try {
                        d.permanentNumber__c = Integer.valueOf(String.valueOf(permObj));
                    } catch (Exception ne) {
                        System.debug('permanentNumber inválido para driverId ' + d.driverId__c + ': ' + permObj + ' -> ' + ne.getMessage());
                    }
                }

                // Relación al constructor por defecto
                d.constructor__c = defaultConstructorId;

                driversToUpsert.add(d);
            }

            if (!driversToUpsert.isEmpty()) {
                // 3) Upsert por External Id driverId__c (recomendado marcar el campo como External Id)
                Database.UpsertResult[] results = Database.upsert(driversToUpsert, Driver__c.Fields.driverId__c, false);

                Integer ok = 0; Integer fail = 0;
                for (Database.UpsertResult r : results) {
                    if (r.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        Database.Error err = r.getErrors()[0];
                        System.debug('Error al upsert Driver: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }

                System.debug('Drivers procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            } else {
                System.debug('No hay drivers para procesar.');
            }

        } catch (Exception e) {
            System.debug('Error en batch (execute): ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Drivers finalizado.');
    }
}