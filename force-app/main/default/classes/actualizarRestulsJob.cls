global class actualizarRestulsJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        resultsBatch batch = new resultsBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}