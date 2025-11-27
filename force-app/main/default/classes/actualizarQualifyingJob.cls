global class actualizarQualifyingJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        qualifyingBatch batch = new qualifyingBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}