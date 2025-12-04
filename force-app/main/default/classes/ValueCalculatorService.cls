/**
 * =====================================================
 * ValueCalculatorService
 * =====================================================
 * Servicio para calcular y asignar Value__c a Drivers y Constructors
 * basado en su rendimiento (puntos y victorias).
 * 
 * USO:
 *   ValueCalculatorService.calculateAllValues();      // Ambos
 *   ValueCalculatorService.calculateDriverValues();   // Solo Drivers
 *   ValueCalculatorService.calculateConstructorValues(); // Solo Constructors
 * 
 * FÓRMULA:
 *   Value = Base + (Points * factor) + (Wins * bonus)
 * =====================================================
 */
public with sharing class ValueCalculatorService 
{

    // ==================== CONFIGURACIÓN DRIVERS ====================
    private static final Decimal DRIVER_BASE_VALUE = 5.0;       // $5M mínimo
    private static final Decimal DRIVER_POINTS_FACTOR = 0.05;   // $0.05M por punto
    private static final Decimal DRIVER_WINS_BONUS = 0.5;       // $0.5M por victoria
    private static final Decimal DRIVER_MAX_VALUE = 30.0;       // $30M máximo

    // ==================== CONFIGURACIÓN CONSTRUCTORS ====================
    private static final Decimal CONSTRUCTOR_BASE_VALUE = 15.0;     // $15M mínimo
    private static final Decimal CONSTRUCTOR_POINTS_FACTOR = 0.04;  // $0.04M por punto
    private static final Decimal CONSTRUCTOR_WINS_BONUS = 1.0;      // $1M por victoria
    private static final Decimal CONSTRUCTOR_MAX_VALUE = 50.0;      // $50M máximo

    /**
     * Calcula y asigna valores a todos los Drivers y Constructors
     */
    public static void calculateAllValues() {
        calculateDriverValues();
        calculateConstructorValues();
        System.debug('✅ Todos los valores calculados correctamente');
    }

    /**
     * Calcula y asigna Value__c a todos los Drivers
     * Fórmula: Base + (Points * factor) + (Wins * bonus)
     * Rango: $5M - $30M
     */
    public static void calculateDriverValues() {
        List<Driver__c> drivers = [
            SELECT Id, Name, Total_Points__c, Wins__c, Value__c 
            FROM Driver__c 
            ORDER BY Total_Points__c DESC NULLS LAST
        ];

        if (drivers.isEmpty()) {
            System.debug('⚠️ No se encontraron Drivers');
            return;
        }

        System.debug('Calculando valores para ' + drivers.size() + ' drivers...');

        List<Driver__c> driversToUpdate = new List<Driver__c>();

        for (Driver__c d : drivers) {
            Decimal points = d.Total_Points__c != null ? d.Total_Points__c : 0;
            Decimal wins = d.Wins__c != null ? d.Wins__c : 0;

            // Calcular valor
            Decimal calculatedValue = DRIVER_BASE_VALUE 
                + (points * DRIVER_POINTS_FACTOR) 
                + (wins * DRIVER_WINS_BONUS);

            // Aplicar máximo
            if (calculatedValue > DRIVER_MAX_VALUE) {
                calculatedValue = DRIVER_MAX_VALUE;
            }

            // Redondear a 1 decimal
            calculatedValue = calculatedValue.setScale(1, RoundingMode.HALF_UP);

            d.Value__c = calculatedValue;
            driversToUpdate.add(d);

            System.debug(d.Name + ' | Points: ' + points + ' | Wins: ' + wins + ' | Value: $' + calculatedValue + 'M');
        }

        if (!driversToUpdate.isEmpty()) {
            update driversToUpdate;
            System.debug('✅ ' + driversToUpdate.size() + ' drivers actualizados con Value__c');
        }
    }

    /**
     * Calcula y asigna Value__c a todos los Constructors
     * Fórmula: Base + (Points * factor) + (Wins * bonus)
     * Rango: $15M - $50M
     */
    public static void calculateConstructorValues() {
        List<Constructor__c> constructors = [
            SELECT Id, Name, Total_Points__c, Wins__c, Value__c 
            FROM Constructor__c 
            ORDER BY Total_Points__c DESC NULLS LAST
        ];

        if (constructors.isEmpty()) {
            System.debug('⚠️ No se encontraron Constructors');
            return;
        }

        System.debug('Calculando valores para ' + constructors.size() + ' constructors...');

        List<Constructor__c> constructorsToUpdate = new List<Constructor__c>();

        for (Constructor__c c : constructors) {
            Decimal points = c.Total_Points__c != null ? c.Total_Points__c : 0;
            Decimal wins = c.Wins__c != null ? c.Wins__c : 0;

            // Calcular valor
            Decimal calculatedValue = CONSTRUCTOR_BASE_VALUE 
                + (points * CONSTRUCTOR_POINTS_FACTOR) 
                + (wins * CONSTRUCTOR_WINS_BONUS);

            // Aplicar máximo
            if (calculatedValue > CONSTRUCTOR_MAX_VALUE) {
                calculatedValue = CONSTRUCTOR_MAX_VALUE;
            }

            // Redondear a 1 decimal
            calculatedValue = calculatedValue.setScale(1, RoundingMode.HALF_UP);

            c.Value__c = calculatedValue;
            constructorsToUpdate.add(c);

            System.debug(c.Name + ' | Points: ' + points + ' | Wins: ' + wins + ' | Value: $' + calculatedValue + 'M');
        }

        if (!constructorsToUpdate.isEmpty()) {
            update constructorsToUpdate;
            System.debug('✅ ' + constructorsToUpdate.size() + ' constructors actualizados con Value__c');
        }
    }

    /**
     * Recalcula el valor de un Driver específico (útil para triggers)
     * @param driverId Id del Driver a recalcular
     */
    public static void recalculateDriverValue(Id driverId) {
        List<Driver__c> drivers = [
            SELECT Id, Name, Total_Points__c, Wins__c, Value__c 
            FROM Driver__c 
            WHERE Id = :driverId
        ];

        if (drivers.isEmpty()) {
            System.debug('⚠️ Driver no encontrado: ' + driverId);
            return;
        }

        Driver__c d = drivers[0];
        Decimal points = d.Total_Points__c != null ? d.Total_Points__c : 0;
        Decimal wins = d.Wins__c != null ? d.Wins__c : 0;

        Decimal calculatedValue = DRIVER_BASE_VALUE 
            + (points * DRIVER_POINTS_FACTOR) 
            + (wins * DRIVER_WINS_BONUS);

        if (calculatedValue > DRIVER_MAX_VALUE) {
            calculatedValue = DRIVER_MAX_VALUE;
        }

        d.Value__c = calculatedValue.setScale(1, RoundingMode.HALF_UP);
        update d;

        System.debug('✅ Driver ' + d.Name + ' actualizado: $' + d.Value__c + 'M');
    }

    /**
     * Recalcula el valor de un Constructor específico (útil para triggers)
     * @param constructorId Id del Constructor a recalcular
     */
    public static void recalculateConstructorValue(Id constructorId) {
        List<Constructor__c> constructors = [
            SELECT Id, Name, Total_Points__c, Wins__c, Value__c 
            FROM Constructor__c 
            WHERE Id = :constructorId
        ];

        if (constructors.isEmpty()) {
            System.debug('⚠️ Constructor no encontrado: ' + constructorId);
            return;
        }

        Constructor__c c = constructors[0];
        Decimal points = c.Total_Points__c != null ? c.Total_Points__c : 0;
        Decimal wins = c.Wins__c != null ? c.Wins__c : 0;

        Decimal calculatedValue = CONSTRUCTOR_BASE_VALUE 
            + (points * CONSTRUCTOR_POINTS_FACTOR) 
            + (wins * CONSTRUCTOR_WINS_BONUS);

        if (calculatedValue > CONSTRUCTOR_MAX_VALUE) {
            calculatedValue = CONSTRUCTOR_MAX_VALUE;
        }

        c.Value__c = calculatedValue.setScale(1, RoundingMode.HALF_UP);
        update c;

        System.debug('✅ Constructor ' + c.Name + ' actualizado: $' + c.Value__c + 'M');
    }
}