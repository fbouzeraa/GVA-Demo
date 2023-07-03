global class BulkInstallationBatchScheduler implements Schedulable {
    public static string CRON_EXP_0 = '0 0 0/2 1/1 * ? *';
    global void execute(SchedulableContext sc) {
        Batch02_Installation btch = new Batch02_Installation();
        Database.executeBatch(btch, 1);
    }
}