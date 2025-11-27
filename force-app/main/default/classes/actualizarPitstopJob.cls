global class actualizarPitstopJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        pitstopBatch batch = new pitstopBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}