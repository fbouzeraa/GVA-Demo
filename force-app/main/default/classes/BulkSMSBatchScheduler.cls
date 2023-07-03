global class BulkSMSBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Batch01_SendBulkSMS btch = new Batch01_SendBulkSMS();
        Database.executeBatch(btch, 20);
    }
}