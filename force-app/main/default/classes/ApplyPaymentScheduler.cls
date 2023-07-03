global with sharing class ApplyPaymentScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Batch06_ApplyPayment btch = new Batch06_ApplyPayment();
        Database.executeBatch(btch);
    }
}