/**
 * =====================================================
 * F1DataQueueable - Sincronización F1 en Cadena
 * =====================================================
 * Ejecuta la sincronización de datos F1 en 6 pasos encadenados.
 * Cada paso es una transacción separada (cumple límites de Salesforce).
 * 
 * Reutiliza las clases de API existentes:
 *   - constructor.cls
 *   - constructorStanding.cls
 *   - driver.cls
 *   - driverstanding.cls
 *   - circuit.cls
 *   - result.cls
 * 
 * USO MANUAL:
 *   System.enqueueJob(new F1DataQueueable());
 * 
 * USO PROGRAMADO:
 *   System.schedule('F1 Sync', '0 0 6 ? * MON', new F1DataSyncJob());
 * 
 * PASOS:
 *   1. Constructors (básicos)
 *   2. Constructor Standings + Value
 *   3. Drivers (básicos)
 *   4. Driver Standings + Value + Constructor Lookup
 *   5. Circuits
 *   6. Results + Fastest Lap
 * =====================================================
 */
public class F1DataQueueable implements Queueable, Database.AllowsCallouts {

    // ==================== CONFIGURACIÓN VALUE ====================
    private static final Decimal DRIVER_BASE_VALUE = 5.0;
    private static final Decimal DRIVER_POINTS_FACTOR = 0.05;
    private static final Decimal DRIVER_WINS_BONUS = 0.5;
    private static final Decimal DRIVER_MAX_VALUE = 30.0;

    private static final Decimal CONSTRUCTOR_BASE_VALUE = 15.0;
    private static final Decimal CONSTRUCTOR_POINTS_FACTOR = 0.04;
    private static final Decimal CONSTRUCTOR_WINS_BONUS = 1.0;
    private static final Decimal CONSTRUCTOR_MAX_VALUE = 50.0;

    // ==================== CONTROL DE PASOS ====================
    private Integer currentStep;

    // Constructor por defecto - inicia en paso 1
    public F1DataQueueable() {
        this.currentStep = 1;
    }

    // Constructor con paso específico
    public F1DataQueueable(Integer step) {
        this.currentStep = step;
    }

    public void execute(QueueableContext context) {
        try {
            System.debug('========== F1DataQueueable - PASO ' + currentStep + ' ==========');

            switch on currentStep {
                when 1 {
                    syncConstructors();
                }
                when 2 {
                    syncConstructorStandings();
                }
                when 3 {
                    syncDrivers();
                }
                when 4 {
                    syncDriverStandings();
                }
                when 5 {
                    syncCircuits();
                }
                when 6 {
                    syncResults();
                }
            }

            // Encadenar siguiente paso si no es el último
            if (currentStep < 6) {
                System.enqueueJob(new F1DataQueueable(currentStep + 1));
                System.debug('➡️ Encolado paso ' + (currentStep + 1));
            } else {
                System.debug('🏁 F1DataQueueable COMPLETADO - Todos los pasos ejecutados');
            }

        } catch (Exception e) {
            System.debug('❌ ERROR en paso ' + currentStep + ': ' + e.getMessage() + ' - ' + e.getStackTraceString());
            // Opcional: continuar con el siguiente paso aunque falle uno
            if (currentStep < 6) {
                System.enqueueJob(new F1DataQueueable(currentStep + 1));
            }
        }
    }

    // ==================== PASO 1: CONSTRUCTORS ====================
    private void syncConstructors() {
        System.debug('--- Sincronizando Constructors ---');
        
        List<Map<String, Object>> constructorData = constructor.givenConstructors();
        
        if (constructorData == null || constructorData.isEmpty()) {
            System.debug('⚠️ No hay datos de constructors');
            return;
        }

        List<Constructor__c> constructorsToUpsert = new List<Constructor__c>();

        for (Map<String, Object> c : constructorData) {
            Constructor__c cons = new Constructor__c();
            cons.constructorId__c = normalize((String) c.get('constructorId'));
            cons.Name = (String) c.get('name');
            cons.name__c = (String) c.get('name');
            cons.nationality__c = (String) c.get('nationality');
            cons.url__c = (String) c.get('url');
            
            constructorsToUpsert.add(cons);
        }

        if (!constructorsToUpsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(constructorsToUpsert, Constructor__c.Fields.constructorId__c, false);
            logResults('Constructors', results);
        }
    }

    // ==================== PASO 2: CONSTRUCTOR STANDINGS + VALUE ====================
    private void syncConstructorStandings() {
        System.debug('--- Sincronizando Constructor Standings + Value ---');
        
        List<Map<String, Object>> standingsData = constructorStanding.givenconstructorstanding();
        
        
        if (standingsData == null || standingsData.isEmpty()) {
            System.debug('⚠️ No hay datos de constructor standings');
            return;
        }
        // Listas para actualizaciones e inserciones
        List<Constructor__c> constructorsToUpdate = new List<Constructor__c>();
        List<constructorstanding__c> constructorstandingToInsert = new List<constructorstanding__c>();
        
        // for para procesar cada registro de standings en constructors y constructorstanding
        for (Map<String, Object> s : standingsData) {
            String constructorId = normalize((String) s.get('constructorId'));
            Integer wins = toInteger(s.get('wins'));
            Integer points = toInteger(s.get('points'));
            
            // Actualizar Constructor__c
            Constructor__c cons = new Constructor__c();
            cons.constructorId__c = constructorId;
            cons.Wins__c = wins;
            cons.Total_Points__c = points;
            cons.Value__c = calculateConstructorValue(points, wins);

            // Insertar constructorstanding__c
            constructorstanding__c constStad = new constructorstanding__c();
            constStad.Name = (String) s.get('name');
            constStad.constructorId__c = (String) s.get('constructorId');
            constStad.url__c = (String) s.get('url'); 
            constStad.nationality__c = (String) s.get('nationality');
            constStad.positionText__c = s.get('positionText') != null ? Integer.valueOf(String.valueOf(s.get('positionText'))) : null;
            constStad.position__c = s.get('position') != null ? Integer.valueOf(String.valueOf(s.get('position'))) : null;    
            constStad.points__c = s.get('points') != null ? Integer.valueOf(String.valueOf(s.get('points'))) : null;
            constStad.season__c = s.get('season') != null ? Integer.valueOf(String.valueOf(s.get('season'))) : null;    
            constStad.round__c = s.get('round') != null ? Integer.valueOf(String.valueOf(s.get('round'))) : null;
            constStad.wins__c = (String) s.get('wins');

            constructorstandingToInsert.add(constStad);
            constructorsToUpdate.add(cons);
            
            System.debug(s.get('name') + ' | Wins: ' + wins + ' | Points: ' + points + ' | Value: $' + cons.Value__c + 'M');
        }

        // Upsert de Constructors
        if (!constructorsToUpdate.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(constructorsToUpdate, Constructor__c.Fields.constructorId__c, false);
            logResults('Constructor Standings', results);
        }
        
        // Upsert de constructorstanding__c
        if (!constructorstandingToInsert.isEmpty()) {
            Database.UpsertResult[] standingResults = Database.upsert(constructorstandingToInsert, constructorstanding__c.Fields.constructorId__c, false);
            logResults('Constructor Standings Records', standingResults);
        }

    }

    // ==================== PASO 3: DRIVERS ====================
    private void syncDrivers() {
        System.debug('--- Sincronizando Drivers ---');
        
        List<Map<String, Object>> driverData = driver.givenDriver();
        
        if (driverData == null || driverData.isEmpty()) {
            System.debug('⚠️ No hay datos de drivers');
            return;
        }

        List<Driver__c> driversToUpsert = new List<Driver__c>();

        for (Map<String, Object> d : driverData) {
            Driver__c drv = new Driver__c();
            drv.driverId__c = normalize((String) d.get('driverId'));
            drv.Name = (String) d.get('givenName') + ' ' + (String) d.get('familyName');
            drv.givenName__c = (String) d.get('givenName');
            drv.familyName__c = (String) d.get('familyName');
            drv.code__c = (String) d.get('code');
            drv.permanentNumber__c = toInteger(d.get('permanentNumber'));
            drv.nationality__c = (String) d.get('nationality');
            drv.url__c = (String) d.get('url');
            
            Object dob = d.get('dateOfBirth');
            if (dob != null) {
                try {
                    if (dob instanceof Date) {
                        drv.dateOfBirth__c = (Date) dob;
                    } else {
                        drv.dateOfBirth__c = Date.valueOf((String) dob);
                    }
                } catch (Exception e) {
                    System.debug('Error parsing dateOfBirth: ' + dob);
                }
            }
            
            driversToUpsert.add(drv);
        }

        if (!driversToUpsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(driversToUpsert, Driver__c.Fields.driverId__c, false);
            logResults('Drivers', results);
        }
    }

    // ==================== PASO 4: DRIVER STANDINGS + VALUE + CONSTRUCTOR ====================
    // private void syncDriverStandings() {
    //     System.debug('--- Sincronizando Driver Standings + Value ---');
        
    //     List<Map<String, Object>> standingsData = driverstanding.obtenerClasificacion();
        
    //     if (standingsData == null || standingsData.isEmpty()) {
    //         System.debug('⚠️ No hay datos de driver standings');
    //         return;
    //     }

    //     // Obtener mapa de Constructor IDs
    //     Map<String, Id> constructorMap = getConstructorMap();

    //     List<Driver__c> driversToUpdate = new List<Driver__c>();

    //     for (Map<String, Object> s : standingsData) {
    //         String driverId = normalize((String) s.get('driverId'));
    //         Integer wins = toInteger(s.get('wins'));
    //         Integer points = toInteger(s.get('points'));

    //         Driver__c drv = new Driver__c();
    //         drv.driverId__c = driverId;
    //         drv.Wins__c = wins;
    //         drv.Total_Points__c = points;
    //         drv.Value__c = calculateDriverValue(points, wins);

    //         // Buscar Constructor desde los datos de standings si está disponible
    //         // Si no, usar el mapa de driver-constructor de results
    //         String constructorId = (String) s.get('constructorId');
    //         if (String.isBlank(constructorId)) {
    //             // Intentar obtener de results
    //             Map<String, String> driverConstructorMap = driver.getDriverConstructorMap();
    //             constructorId = driverConstructorMap.get((String) s.get('driverId'));
    //         }
            
    //         if (String.isNotBlank(constructorId) && constructorMap.containsKey(normalize(constructorId))) {
    //             drv.Constructor__c = constructorMap.get(normalize(constructorId));
    //         }

    //         driversToUpdate.add(drv);
            
    //         System.debug(s.get('givenName') + ' ' + s.get('familyName') + 
    //             ' | Wins: ' + wins + ' | Points: ' + points + ' | Value: $' + drv.Value__c + 'M');
    //     }

    //     if (!driversToUpdate.isEmpty()) {
    //         Database.UpsertResult[] results = Database.upsert(driversToUpdate, Driver__c.Fields.driverId__c, false);
    //         logResults('Driver Standings', results);
    //     }
    // }
    // ==================== PASO 4: DRIVER STANDINGS + VALUE + CONSTRUCTOR ====================
    private void syncDriverStandings() {
        System.debug('--- Sincronizando Driver Standings + Value ---');
    
        List<Map<String, Object>> standingsData = driverstanding.obtenerClasificacion();
    
        if (standingsData == null || standingsData.isEmpty()) {
            System.debug('⚠️ No hay datos de driver standings');
            return;
        }

        // Obtener mapa de Constructor IDs
        Map<String, Id> constructorMap = getConstructorMap();
    
        // Obtener mapa Driver -> Constructor desde results
        Map<String, String> driverConstructorMap = driver.getDriverConstructorMap();

        List<Driver__c> driversToUpdate = new List<Driver__c>();
        List<driverstanding__c> driverstandingToInsert = new List<driverstanding__c>();  // ← AGREGAR ESTA LÍNEA

        for (Map<String, Object> s : standingsData) {
            String driverId = normalize((String) s.get('driverId'));
            Integer wins = toInteger(s.get('wins'));
            Integer points = toInteger(s.get('points'));

            // ========== ACTUALIZAR Driver__c ==========
            Driver__c drv = new Driver__c();
            drv.driverId__c = driverId;
            drv.Wins__c = wins;
            drv.Total_Points__c = points;
            drv.Value__c = calculateDriverValue(points, wins);

            // Buscar Constructor
            String constructorId = (String) s.get('constructorId');
            if (String.isBlank(constructorId)) {
                constructorId = driverConstructorMap.get((String) s.get('driverId'));
            }
        
            if (String.isNotBlank(constructorId) && constructorMap.containsKey(normalize(constructorId))) {
                drv.Constructor__c = constructorMap.get(normalize(constructorId));
            }

            driversToUpdate.add(drv);

            // ========== CREAR REGISTRO EN driverstanding__c ========== (AGREGAR ESTE BLOQUE)
            driverstanding__c standing = new driverstanding__c();
            standing.Name = (String) s.get('givenName') + ' ' + (String) s.get('familyName');
            standing.driverId__c = (String) s.get('driverId');
            standing.givenName__c = (String) s.get('givenName');
            standing.familyName__c = (String) s.get('familyName');
            standing.nationality__c = (String) s.get('nationality');
            standing.url__c = (String) s.get('url');
            standing.code__c = (String) s.get('code');
            standing.permanentNumber__c = toInteger(s.get('permanentNumber'));
            standing.position__c = toInteger(s.get('position'));
            standing.points__c = toInteger(s.get('points'));
            standing.wins__c = toInteger(s.get('wins'));
        
            // Fecha de nacimiento
            Object dob = s.get('dateOfBirth');
            if (dob != null) {
                try {
                    standing.dateOfBirth__c = Date.valueOf((String) dob);
                } catch (Exception e) {
                    System.debug('Error parsing dateOfBirth: ' + dob);
                }
            }
        
            driverstandingToInsert.add(standing);
            // ========== FIN BLOQUE NUEVO ==========
        
            System.debug(s.get('givenName') + ' ' + s.get('familyName') +
                ' | Wins: ' + wins + ' | Points: ' + points + ' | Value: $' + drv.Value__c + 'M');
        }

        // Upsert Driver__c
        if (!driversToUpdate.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(driversToUpdate, Driver__c.Fields.driverId__c, false);
            logResults('Drivers', results);
        }

        // Upsert driverstanding__c (AGREGAR ESTE BLOQUE)
        if (!driverstandingToInsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(driverstandingToInsert, driverstanding__c.Fields.driverId__c, false);
            logResults('Driver Standing Records', results);
        }
    }


    // ==================== PASO 5: CIRCUITS ====================
    private void syncCircuits() {
        System.debug('--- Sincronizando Circuits ---');
        
        List<Map<String, Object>> circuitData = circuit.giveCircuits();
        
        if (circuitData == null || circuitData.isEmpty()) {
            System.debug('⚠️ No hay datos de circuits');
            return;
        }

        List<Circuit__c> circuitsToUpsert = new List<Circuit__c>();

        for (Map<String, Object> c : circuitData) {
            Circuit__c cir = new Circuit__c();
            cir.circuitId__c = normalize((String) c.get('circuitId'));
            cir.Name = (String) c.get('circuitName');
            cir.url__c = (String) c.get('url');
            cir.country__c = (String) c.get('country');
            cir.locality__c = (String) c.get('locality');
            
            if (c.get('lat') != null) {
                cir.Location__Latitude__s = Decimal.valueOf(String.valueOf(c.get('lat')));
            }
            if (c.get('long') != null) {
                cir.Location__Longitude__s = Decimal.valueOf(String.valueOf(c.get('long')));
            }
            
            circuitsToUpsert.add(cir);
        }

        if (!circuitsToUpsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(circuitsToUpsert, Circuit__c.Fields.circuitId__c, false);
            logResults('Circuits', results);
        }
    }

    // ==================== PASO 6: RESULTS ====================
    private void syncResults() {
        System.debug('--- Sincronizando Results ---');
        
        List<Map<String, Object>> resultsData = result.giveResults();
        
        if (resultsData == null || resultsData.isEmpty()) {
            System.debug('⚠️ No hay datos de results');
            return;
        }

        // Obtener mapas de IDs
        Map<String, Id> driverMap = getDriverMap();
        Map<String, Id> constructorMap = getConstructorMap();
        Map<String, Id> circuitMap = getCircuitMap();

        List<result__c> resultsToUpsert = new List<result__c>();

        for (Map<String, Object> r : resultsData) {
            String driverId = normalize((String) r.get('driverId'));
            String constructorId = normalize((String) r.get('constructorId'));
            String circuitId = normalize((String) r.get('circuitId'));
            String season = String.valueOf(r.get('season'));
            String round = String.valueOf(r.get('round'));

            result__c res = new result__c();
            
            // External ID único
            res.ResultKey__c = season + '_' + round + '_' + driverId;
            
            res.Name = (String) r.get('raceName');
            res.number__c = toInteger(r.get('number'));
            res.position__c = toInteger(r.get('position'));
            res.positionText__c = (String) r.get('positionText');
            res.points__c = toInteger(r.get('points'));
            res.grid__c = toInteger(r.get('grid'));
            res.laps__c = toInteger(r.get('laps'));
            res.status__c = (String) r.get('status');

            // Fastest Lap
            Object fastestLapRank = r.get('fastestLapRank');
            res.Fastest_Lap__c = (fastestLapRank != null && String.valueOf(fastestLapRank) == '1');

            // Lookups
            if (driverId != null && driverMap.containsKey(driverId)) {
                res.Driver__c = driverMap.get(driverId);
            }
            if (constructorId != null && constructorMap.containsKey(constructorId)) {
                res.Constructor__c = constructorMap.get(constructorId);
            }
            if (circuitId != null && circuitMap.containsKey(circuitId)) {
                res.Circuit__c = circuitMap.get(circuitId);
            }

            resultsToUpsert.add(res);
        }

        if (!resultsToUpsert.isEmpty()) {
            Database.UpsertResult[] results = Database.upsert(resultsToUpsert, result__c.Fields.ResultKey__c, false);
            logResults('Results', results);
        }
    }

    // ==================== HELPERS ====================

    private Map<String, Id> getDriverMap() {
        Map<String, Id> driverMap = new Map<String, Id>();
        for (Driver__c d : [SELECT Id, driverId__c FROM Driver__c WHERE driverId__c != null]) {
            driverMap.put(normalize(d.driverId__c), d.Id);
        }
        return driverMap;
    }

    private Map<String, Id> getConstructorMap() {
        Map<String, Id> constructorMap = new Map<String, Id>();
        for (Constructor__c c : [SELECT Id, constructorId__c FROM Constructor__c WHERE constructorId__c != null]) {
            constructorMap.put(normalize(c.constructorId__c), c.Id);
        }
        return constructorMap;
    }

    private Map<String, Id> getCircuitMap() {
        Map<String, Id> circuitMap = new Map<String, Id>();
        for (Circuit__c c : [SELECT Id, circuitId__c FROM Circuit__c WHERE circuitId__c != null]) {
            circuitMap.put(normalize(c.circuitId__c), c.Id);
        }
        return circuitMap;
    }

    private Decimal calculateDriverValue(Integer points, Integer wins) {
        Decimal p = points != null ? points : 0;
        Decimal w = wins != null ? wins : 0;
        
        Decimal value = DRIVER_BASE_VALUE + (p * DRIVER_POINTS_FACTOR) + (w * DRIVER_WINS_BONUS);
        
        if (value > DRIVER_MAX_VALUE) {
            value = DRIVER_MAX_VALUE;
        }
        
        return value.setScale(1, RoundingMode.HALF_UP);
    }

    private Decimal calculateConstructorValue(Integer points, Integer wins) {
        Decimal p = points != null ? points : 0;
        Decimal w = wins != null ? wins : 0;
        
        Decimal value = CONSTRUCTOR_BASE_VALUE + (p * CONSTRUCTOR_POINTS_FACTOR) + (w * CONSTRUCTOR_WINS_BONUS);
        
        if (value > CONSTRUCTOR_MAX_VALUE) {
            value = CONSTRUCTOR_MAX_VALUE;
        }
        
        return value.setScale(1, RoundingMode.HALF_UP);
    }

    private static String normalize(String val) {
        return val != null ? val.trim().toLowerCase() : null;
    }

    private static Integer toInteger(Object val) {
        if (val == null) return null;
        try {
            return Integer.valueOf(String.valueOf(val));
        } catch (Exception e) {
            return null;
        }
    }

    private void logResults(String objectName, Database.UpsertResult[] results) {
        Integer ok = 0, fail = 0;
        for (Database.UpsertResult ur : results) {
            if (ur.isSuccess()) {
                ok++;
            } else {
                fail++;
                for (Database.Error err : ur.getErrors()) {
                    System.debug('❌ Error ' + objectName + ': ' + err.getMessage());
                }
            }
        }
        System.debug('✅ ' + objectName + ' sincronizados. Éxitos: ' + ok + ', Fallos: ' + fail);
    }
}