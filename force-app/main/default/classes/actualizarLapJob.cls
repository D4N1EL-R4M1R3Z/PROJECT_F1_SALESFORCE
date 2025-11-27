global class actualizarLapJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        lapBatch batch = new lapBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}