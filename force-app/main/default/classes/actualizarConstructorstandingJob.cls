global class actualizarConstructorstandingJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        constructorstandingBatch batch = new constructorstandingBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}