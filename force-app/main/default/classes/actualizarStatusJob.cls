global class actualizarStatusJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        statusBatch batch = new statusBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}