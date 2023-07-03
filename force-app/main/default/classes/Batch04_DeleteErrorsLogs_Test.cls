/**
 * Classe test pour Batch04_DeleteErrorsLogs
 * Couverture: 100%
 */
@isTest
public class Batch04_DeleteErrorsLogs_Test {

    @TestSetup
    static void makeData(){
        //add Zuora Mock and Eligibility Mock to MultiMock class
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());

        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        TestUtils.createSub();
        Zuora__Product__c zpr = TestUtils.createZuoraProduct();
        insert zpr;
        Zuora__Subscription__c newSub = [SELECT Id, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        newSub.CompensationDaysAtNextRenewal__c = '15';
        newSub.Zuora__Status__c = 'Active';
        update newSub;

        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;
        Test.startTest();
        string paymentResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 2, 'Credit_Card', null, null, null, null, null, null, null, null, null, null);
        ZuoraResponseObjects.ZuoraPayment deserializedPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
        deserializedPaymentResponse = (ZuoraResponseObjects.ZuoraPayment)JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);
        System.assertEquals(true, deserializedPaymentResponse.success, 'Payment should not be created');
        SubscriptionRenewalActions.addPaymentNumberToSubscription(newSub.Id, deserializedPaymentResponse.number_toReplace);
        List<Log__c> listLog = [SELECT Id, Name FROM Log__c];
        System.assertEquals(true, listLog.size() > 0, 'Logs should be created');
        Test.stopTest();
        for(log__c lg : listLog) {
            Test.setCreatedDate(lg.Id, DateTime.newInstance(2020, 12, 12));
        }
    }
    @isTest
    static void testBatch(){
        Erreur_de_Interface__c ei = new Erreur_de_Interface__c(EI_Description__c = 'test');
        insert ei;
        Test.setCreatedDate(ei.Id, DateTime.newInstance(2020, 12, 12));
        Test.startTest();
        String cronExpr = '0 0 23 * * ?';
        DeleteLogsErrorBatchScheduler sch = new DeleteLogsErrorBatchScheduler();
        String jobId = System.schedule('myJobTestJobName', cronExpr, sch);
        system.debug(jobId);

        Test.stopTest();

    }

}