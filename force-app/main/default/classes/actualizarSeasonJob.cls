global class actualizarSeasonJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        seasonBatch batch = new seasonBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}