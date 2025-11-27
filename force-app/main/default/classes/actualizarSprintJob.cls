global class actualizarSprintJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        sprintBatch batch = new sprintBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}