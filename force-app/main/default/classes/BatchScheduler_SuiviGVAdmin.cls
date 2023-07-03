global class BatchScheduler_SuiviGVAdmin implements Schedulable {
    public static string cronExpression4AM = '0 0 4 ? * * *';
    global void execute(SchedulableContext sc) {
        Batch08_SuiviGVAdmin batch = new Batch08_SuiviGVAdmin(); 
        Database.executeBatch(batch);
    }
}