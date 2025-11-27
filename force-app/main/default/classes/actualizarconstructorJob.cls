global class actualizarconstructorJob implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Llama al batch que sí permite callouts
        constructorBatch batch = new constructorBatch();
        Database.executeBatch(batch, 1); // tamaño de lote mínimo
    }
}