global class Batch12_RenewBundleMigration_Scheduler implements Schedulable {
    public static string CRON_EXP_1 = '0 0 19 ? * * *';
    global void execute(SchedulableContext sc) {
        Batch12_RenewBundleMigration btch = new Batch12_RenewBundleMigration();
        Database.executeBatch(btch, 1);
    }
}