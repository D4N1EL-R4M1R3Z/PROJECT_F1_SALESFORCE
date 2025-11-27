global class actualizarRaceJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        raceBatch batch = new raceBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}