global class DeleteLogsErrorBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        Batch04_DeleteErrorsLogs btch = new Batch04_DeleteErrorsLogs();
        Database.executeBatch(btch);
    }
}