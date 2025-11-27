global class actualizarDriverstadingJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        driverstadingBatch batch = new driverstadingBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}