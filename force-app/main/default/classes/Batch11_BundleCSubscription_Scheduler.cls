global class Batch11_BundleCSubscription_Scheduler implements Schedulable {
    public static string CRON_EXP_1 = '0 0 * ? * * *';
    global void execute(SchedulableContext sc) {
        Batch_11_SubscribeToBundleC btch = new Batch_11_SubscribeToBundleC();
        Database.executeBatch(btch, 1);
    }
}