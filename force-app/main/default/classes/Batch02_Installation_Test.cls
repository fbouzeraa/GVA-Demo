@isTest
public class Batch02_Installation_Test {
    @TestSetup
    public static void makeData() {
        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));

        TestUtils.createSub();
    }
    @isTest
    static void testSucceededInstallation(){
        Suivi_de_Souscription__c suivi = [SELECT id, SV_Reference_Externe__c
                                          FROM Suivi_de_Souscription__c
                                          WHERE SV_Code_Action__c = 'ACT001' LIMIT 1];

        suivi.SV_Reference_Externe__c = '012332112';
        suivi.SV_statut__c = 'STA002';

        update suivi;
        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        // Test Scheduler and Batch
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));

        Database.executeBatch(new Batch02_Installation(), 1);
        Test.stopTest();
//SV_Tech_Installation_Termine__c
        Suivi_de_Souscription__c updatedSuivi = [SELECT id, SV_Date_activation__c,
                                                 SV_Id_Souscription__r.Zuora__Account__r.ACC_TechInstallation__c,
                                                 SV_Id_Souscription__r.Zuora__ServiceActivationDate__c
                                                 FROM Suivi_de_Souscription__c
                                                 WHERE SV_Code_Action__c = 'ACT001' LIMIT 1];

        System.assertEquals(date.today(), updatedSuivi.SV_Id_Souscription__r.Zuora__ServiceActivationDate__c, 'Subscription should be active');
    }
    @isTest
    static void ResumeSubscription(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, Quote__c, Zuora__Status__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Suivi_de_Souscription__c suivi = new Suivi_de_Souscription__c(SV_Id_Souscription__c = newSub.Id, SV_Code_Action__C = 'ACT007',
                                                                      SV_Reference_Externe__c = '1234', SV_Statut__c = 'STA002');
        insert suivi;
        Suivi_de_Souscription__c suivi1 = new Suivi_de_Souscription__c(SV_Id_Souscription__c = newSub.Id, SV_Code_Action__C = 'ACT007',
                                                                       SV_Reference_Externe__c = '1234', SV_Statut__c = 'STA002');
        insert suivi1;
        newSub.Zuora__Status__c = 'Suspended';
        update newSub;

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        Database.executeBatch(new Batch02_Installation(), 10);
        Test.stopTest();
    }
    @isTest
    static void testFailedInstallation(){
        Zuora__Subscription__c sub = [SELECT ID, Zuora__serviceActivationDate__c
                                      FROM Zuora__Subscription__c LIMIT 1];
        sub.Zuora__serviceActivationDate__c = null;
        update sub;

        Suivi_de_Souscription__c suivi = [ SELECT id, SV_Reference_Externe__c
                                           FROM Suivi_de_Souscription__c LIMIT 1];
        //change status to traite
        suivi.SV_Reference_Externe__c = '012332112';
        update suivi;

        // Test Scheduler and Batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StockMock(false, false, 400));

        BulkInstallationBatchScheduler sch = new BulkInstallationBatchScheduler();
        System.schedule('JobTestAt0', BulkInstallationBatchScheduler.CRON_EXP_0, sch);

        Test.stopTest();
        Suivi_de_Souscription__c updatedSuivi = [ SELECT id, SV_Date_activation__c,
                                                  SV_Id_Souscription__r.Zuora__Account__r.ACC_TechInstallation__c,
                                                  SV_Id_Souscription__r.Zuora__ServiceActivationDate__c
                                                  FROM Suivi_de_Souscription__c LIMIT 1];

        System.assertEquals(null, updatedSuivi.SV_Id_Souscription__r.Zuora__ServiceActivationDate__c, 'Subscription should not be active');

    }
}