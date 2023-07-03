/**
 * Classe test pour Batch05_RetryErrors
 * Couverture: 100%
 */
@isTest
public class Batch05_RetryErrors_Test {
    @TestSetup
    static void makeData(){
        string body = '{"type" : "External", "SourceOperator_Reserved" : "58692", "Source_Reserved" : "Shop", "Processing_Reserved" : "N/A", "PrepaidPeriods_Reserved" : "1", "PaymentProcessor_Reserved" : "Moov", "paymentMethodId" : "8adc9dee73a422880173a5b39a4f785a", "OrderNumber_Reserved" : "O-00000587", "OperatorAgent_Reserved" : "Yara Bourdoukan", "invoices" :[{"invoiceId" : "8adcc2417fb5021d017fbc5a9b9e7f2b", "amount" : 15000.0}], "effectiveDate" : "2022-03-24", "currency_toReplace" : "XOF", "amount" : 15000.0, "accountId" : "8adc90277d096b02017d0eab02374a6c"}';

        List<Log__c> listLog = new list<Log__c>();
        for(integer i = 0; i < 10; i++) {
            Log__c lg = new Log__c();
            lg.LG_Success__c = false;
            lg.LG_Error_Solved__c = false;
            lg.LG_Body__c = body;
            lg.LG_Method_URL__c = '/v1/object/invoice/8adcc2417e7c3080017e8c50c3d84712';
            lg.LG_Interface__c = 'Zuora';
            lg.LG_Method_Type__c = 'PUT';
            lg.LG_Retry__c = true;
            listLog.add(lg);
        }
        Log__c lg = new Log__c();
        lg.LG_Success__c = false;
        lg.LG_Error_Solved__c = false;
        lg.LG_Body__c = body;
        lg.LG_Method_URL__c = '/v1/order';
        lg.LG_Interface__c = 'Zuora';
        lg.LG_Method_Type__c = 'PUT';
        lg.LG_Retry__c = false;
        listLog.add(lg);
        insert listLog;
    }
    @isTest
    static void testBatch(){

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        BulkRetryErrorScheduler sch = new BulkRetryErrorScheduler();
        System.schedule('JobTestAt15', BulkRetryErrorScheduler.CRON_EXP_15, sch);
        System.schedule('JobTestAt45', BulkRetryErrorScheduler.CRON_EXP_45, sch);

        Id batchJobId = Database.executeBatch(new Batch05_RetryErrors(), 50);
        Test.stopTest();
        list<Log__c> listLog = [SELECT Id FROM Log__c WHERE LG_Error_Solved__c = true];
        System.assertEquals (10, listLog.size(), 'All errors should be solved');

    }
}