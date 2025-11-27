global class actualizarDriverJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        driverBatch batch = new driverBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}