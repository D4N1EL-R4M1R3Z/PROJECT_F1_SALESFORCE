global class actualizarCircuitJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        circuitBatch batch = new circuitBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}