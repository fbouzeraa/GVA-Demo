@isTest
public with sharing class Batch12_RenewBundleMigration_Test {

    @TestSetup
    static void makeData(){
        //add Zuora Mock and Eligibility Mock to MultiMock class
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        TestUtils.createSub();
    }
    
    @isTest
    public static void Batch12_RenewBundleMigration_Test() {


        
        Zuora__Subscription__c sub = [SELECT Id, Zuora__Account__c, ExpectedRenewalDate__c, Create_Bundle_C_subscription__c, Prior_expedted_renewal_Date__c,
                                        CBundle_Periode__c,SUB_Tech_Material__c,SUB_Offer__c,SUB_Options__c, C_Migration_Date__c, Zuora__Status__c
                                    FROM Zuora__Subscription__c
                                    LIMIT 1];

        sub.C_Migration_Date__c = datetime.now();
        sub.Zuora__Status__c = 'Active';
        sub.SUB_T_Produit_De_Base__c = 'Start';
        sub.CompensationDaysAtNextRenewal__c = '0';

        try {
            update sub;
        } catch (Exception e) {
            system.debug(e.getLineNumber()+' '+e.getMessage());
        }

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;
        Zuora__SubscriptionProductCharge__c subProduct2 = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subProduct2;

        Bundle_C_Follow_up__c suiviBundle = new Bundle_C_Follow_up__c();
        suiviBundle.Fiber_Offer__c = 'Premium';
        suiviBundle.Prepaid_Period__c = '1';
        suiviBundle.Payment_Method__c = 'cash';
        suiviBundle.Canal_Offer__c = '10GVAAC|ACDD';
        suiviBundle.Canal_Category__c = 'Access';
        suiviBundle.BC_Code_Action__c = 'ACT007';
        suiviBundle.BC_Subscription__c = sub.Id;
        suiviBundle.Migration_Date__c = date.today();
        insert suiviBundle;

        Test.startTest();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:CGAWeb', new CBundeMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        String cronExpr = '0 0 * ? * * *';
        Batch12_RenewBundleMigration_Scheduler smsbs = new Batch12_RenewBundleMigration_Scheduler();
        String jobId = System.schedule('myJobTestJobName', cronExpr, smsbs);
        CronTrigger ct = [SELECT id, CronExpression FROM CronTrigger where id = :jobId];
        System.assertEquals(cronExpr, ct.CronExpression, 'Scheduler not set correctly');
        smsbs.execute(null);

        Batch12_RenewBundleMigration btch = new Batch12_RenewBundleMigration();
        Database.executeBatch(btch, 1);

        Test.stopTest();

        Zuora__Subscription__c updatedSub = [SELECT Zuora__Account__c, ExpectedRenewalDate__c, Zuora__Status__c,SUB_Status__c,SUB_Offer__c
                                        FROM Zuora__Subscription__c
                                        LIMIT 1];

        System.assertEquals(true, updatedSub.SUB_Offer__c != null, 'reabo Bundle est fait');
    }

    @isTest
    public static void Batch12_RenewBundleMigration2_Test() {


        
        Zuora__Subscription__c sub = [SELECT Id, Zuora__Account__c, ExpectedRenewalDate__c, Create_Bundle_C_subscription__c, Prior_expedted_renewal_Date__c,
                                        CBundle_Periode__c,SUB_Tech_Material__c,SUB_Offer__c,SUB_Options__c, C_Migration_Date__c, Zuora__Status__c
                                    FROM Zuora__Subscription__c
                                    LIMIT 1];

        sub.C_Migration_Date__c = datetime.now();
        sub.Zuora__Status__c = 'Active';
        sub.SUB_T_Produit_De_Base__c = 'Start';
        sub.CompensationDaysAtNextRenewal__c = '0';

        try {
            update sub;
        } catch (Exception e) {
            system.debug(e.getLineNumber()+' '+e.getMessage());
        }

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;
        Zuora__SubscriptionProductCharge__c subProduct2 = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subProduct2;

        Bundle_C_Follow_up__c suiviB = new Bundle_C_Follow_up__c();
        suiviB.Fiber_Offer__c = 'Start';
        suiviB.Prepaid_Period__c = '1';
        suiviB.Payment_Method__c = 'cash';
        suiviB.Canal_Offer__c = '10GVAAC|ACDD';
        suiviB.Canal_Category__c = 'Access';
        suiviB.BC_Code_Action__c = 'ACT007';
        suiviB.BC_Subscription__c = sub.Id;
        suiviB.Migration_Date__c = date.today();
        insert suiviB;

        Test.startTest();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:CGAWeb', new CBundeMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        String cronExpr = '0 0 * ? * * *';
        Batch12_RenewBundleMigration_Scheduler smsbs = new Batch12_RenewBundleMigration_Scheduler();
        String jobId = System.schedule('myJobTestJobName', cronExpr, smsbs);
        CronTrigger ct = [SELECT id, CronExpression FROM CronTrigger where id = :jobId];
        System.assertEquals(cronExpr, ct.CronExpression, 'Scheduler not set correctly');
        smsbs.execute(null);

        Batch12_RenewBundleMigration btch = new Batch12_RenewBundleMigration();
        Database.executeBatch(btch, 1);

        Test.stopTest();

        Zuora__Subscription__c updatedSub = [SELECT Zuora__Account__c, ExpectedRenewalDate__c, Zuora__Status__c,SUB_Status__c,SUB_Offer__c
                                        FROM Zuora__Subscription__c
                                        LIMIT 1];

        System.assertEquals(true, updatedSub.SUB_Offer__c != null, 'reabo Bundle est fait');
    }
}