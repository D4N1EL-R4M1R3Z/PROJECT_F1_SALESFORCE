global class resultsBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    // Ejecutamos siempre (dummy scope)
    global Iterable<SObject> start(Database.BatchableContext bc) {
        return new List<SObject>{ new Account() };
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            // 1) Traer datos desde la API (tu clase result.giveResults())
            List<Map<String, Object>> resultsData = result.giveResults();
            System.debug('Cantidad de resultados obtenidos: ' + resultsData.size());
            if (resultsData.isEmpty()) {
                System.debug('No hay resultados para procesar.');
                return;
            }

            // 2) Preparar colecciones
            Set<String> driverExtIds = new Set<String>();
            Set<String> constructorExtIds = new Set<String>();

            // Usamos Maps para evitar duplicados al upsert
            Map<String, Driver__c> driversToUpsertByExt = new Map<String, Driver__c>();
            Map<String, Constructor__c> constructorsToUpsertByExt = new Map<String, Constructor__c>();

            // Resultados que luego insertaremos con los lookups
            List<result__c> resultsBuffer = new List<result__c>();

            // 3) Recorrer la data y armar Upserts y Results (sin lookups todavía)
            for (Map<String, Object> ds : resultsData) {
                String dId = (String) ds.get('driverId');
                String cId = (String) ds.get('constructorId');

                if (!String.isBlank(dId)) {
                    driverExtIds.add(dId);
                    if (!driversToUpsertByExt.containsKey(dId)) {
                        Driver__c d = new Driver__c();
                        d.driverId__c   = dId;                                 // External Id (Unique)
                        d.Name          = buildDriverName(ds);                  // givenName + familyName
                        d.nationality__c= (String) ds.get('nationality');
                        d.url__c        = (String) ds.get('driverUrl');
                        driversToUpsertByExt.put(dId, d);
                    }
                }

                if (!String.isBlank(cId)) {
                    constructorExtIds.add(cId);
                    if (!constructorsToUpsertByExt.containsKey(cId)) {
                        Constructor__c c = new Constructor__c();
                        c.constructorId__c = cId;                               // External Id (Unique)
                        c.Name             = (String) ds.get('constructorName');
                        c.url__c           = (String) ds.get('constructorUrl');
                        c.nationality__c   = (String) ds.get('constructorNat');
                        constructorsToUpsertByExt.put(cId, c);
                    }
                }

                // Construimos el Result (sin Lookups aún)
                result__c r = new result__c();
                r.Name            = (String) ds.get('raceName');
                r.number__c       = toInteger(ds.get('number'));
                r.position__c     = toInteger(ds.get('position'));
                r.positionText__c = (String) ds.get('positionText');
                r.points__c       = toInteger(ds.get('points'));
                r.grid__c         = toInteger(ds.get('grid'));
                r.laps__c         = toInteger(ds.get('laps'));
                r.status__c       = (String) ds.get('status');
                // ⚠️ OJO: NO asignar strings a Lookups, siempre Ids reales
                resultsBuffer.add(r);
            }

            // 4) Upsert Pilotos y Constructores por External Id
            if (!driversToUpsertByExt.isEmpty()) {
                Database.upsert(driversToUpsertByExt.values(), Driver__c.Fields.driverId__c, false);
            }
            if (!constructorsToUpsertByExt.isEmpty()) {
                Database.upsert(constructorsToUpsertByExt.values(), Constructor__c.Fields.constructorId__c, false);
            }

            // 5) Consultar Ids reales para los lookups
            Map<String, Id> driverMap = new Map<String, Id>();
            if (!driverExtIds.isEmpty()) {
                for (Driver__c d : [SELECT Id, driverId__c FROM Driver__c WHERE driverId__c IN :driverExtIds]) {
                    driverMap.put(d.driverId__c, d.Id);
                }
            }

            Map<String, Id> constructorMap = new Map<String, Id>();
            if (!constructorExtIds.isEmpty()) {
                for (Constructor__c c : [SELECT Id, constructorId__c FROM Constructor__c WHERE constructorId__c IN :constructorExtIds]) {
                    constructorMap.put(c.constructorId__c, c.Id);
                }
            }

            // 6) Asignar Lookups en Results usando los Ids consultados
            Integer i = 0;
           
                for (Map<String, Object> ds : resultsData) {
                    String cId = (String) ds.get('constructorId');
                    resultsBuffer[i].Constructor__c = constructorMap.get(cId);
                    i++;
}


            // 7) Insert de Results con tolerancia a errores
            if (!resultsBuffer.isEmpty()) {
                Database.SaveResult[] sr = Database.insert(resultsBuffer, false);

                Integer ok = 0, fail = 0;
                for (Database.SaveResult s : sr) {
                    if (s.isSuccess()) {
                        ok++;
                    } else {
                        fail++;
                        for (Database.Error e : s.getErrors()) {
                            System.debug('Error al insertar Result: ' + e.getStatusCode() + ' - ' + e.getMessage());
                        }
                    }
                }
                System.debug('Resultados procesados. Éxitos: ' + ok + ', Fallos: ' + fail);
            }

        } catch (Exception e) {
            System.debug('Error en execute: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch de Results finalizado.');
    }

    // Helpers
    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try { return Integer.valueOf(String.valueOf(val)); } catch (Exception e) { return null; }
    }

    private static String buildDriverName(Map<String, Object> ds) {
        String given   = (String) ds.get('givenName');
        String family  = (String) ds.get('familyName');
        String full    = ((given != null ? given : '') + ' ' + (family != null ? family : '')).trim();
        return String.isBlank(full) ? (String) ds.get('driverId') : full;
    }
}