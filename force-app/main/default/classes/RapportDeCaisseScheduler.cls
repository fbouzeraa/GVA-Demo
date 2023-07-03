global class RapportDeCaisseScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Batch03_RapportDeCaisse btch = new Batch03_RapportDeCaisse();
        Database.executeBatch(btch, 9);

    }
}