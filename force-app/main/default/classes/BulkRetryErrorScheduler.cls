global class BulkRetryErrorScheduler implements Schedulable {
    public static string CRON_EXP_15 = '0 15 * * * ? *';
    public static string CRON_EXP_45 = '0 45 * * * ? *';
    global void execute(SchedulableContext sc) {
        Batch05_RetryErrors btch = new Batch05_RetryErrors();
        Database.executeBatch(btch, 50);
    }

}