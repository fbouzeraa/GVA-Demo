@isTest
public class Batch06_ApplyPayment_Test {
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
    static void addRenewalDateTest(){

        Zuora__Subscription__c sub = [SELECT Id, ExpectedRenewalDate__c, Zuora__Status__c, Zuora__ServiceActivationDate__c
                                      FROM Zuora__Subscription__c
                                      LIMIT 1];
        sub.ExpectedRenewalDate__c = null;
        sub.Zuora__ServiceActivationDate__c = date.today();
        sub.Zuora__Status__c = 'Active';
        update sub;
        // Test  Batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ApplyPaymentScheduler sch = new ApplyPaymentScheduler();
        System.schedule('Test', '0 0 23 * * ? *', sch);
        Database.executeBatch(new Batch06_ApplyPayment(), 1);
        Test.stopTest();

        list<Suivi_de_Souscription__c> listOfSuivi = [Select Id From Suivi_de_Souscription__c];
        system.assertEquals(3, listOfSuivi.size(), 'Suivi_de_Souscription__c Created');
        list<Suivi_de_Souscription__c> listOfSuiviActivation = [Select Id, SV_Code_Action__c From Suivi_de_Souscription__c Where SV_Code_Action__c = 'ACT011'];
        system.assertEquals(1, listOfSuiviActivation.size(), 'Suivi_de_Souscription__c activation Created');
    }
    @isTest
    static void createNewPaymentTest(){

        Zuora__Subscription__c sub = [SELECT createdDate, Quote__c, Id, ExpectedRenewalDate__c, Zuora__Status__c, Zuora__ServiceActivationDate__c
                                      FROM Zuora__Subscription__c
                                      LIMIT 1];
        sub.ExpectedRenewalDate__c = null;
        sub.Zuora__Status__c = 'Pending Activation';
        update sub;
        system.debug(sub.createdDate);
        Quote quo = new Quote();
        quo.Id = sub.Quote__c;
        quo.QUO_T_PaymentID__c = null;
        update quo;
        // Test  Batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock3());

        Database.executeBatch(new Batch06_ApplyPayment(), 100);
        Test.stopTest();
        sub = [SELECT Id, Quote__r.QUO_T_PaymentID__c
               FROM Zuora__Subscription__c
               LIMIT 1];
        system.assertEquals(false, sub.Quote__r.QUO_T_PaymentID__c == null, 'payment Id should be added');
    }
    @isTest
    static void addPaymentToQuoteTest(){

        Zuora__Subscription__c sub = [SELECT createdDate, Quote__c, Id, ExpectedRenewalDate__c, Zuora__Status__c, Zuora__ServiceActivationDate__c
                                      FROM Zuora__Subscription__c
                                      LIMIT 1];
        sub.ExpectedRenewalDate__c = null;
        sub.Zuora__Status__c = 'Pending Activation';
        update sub;
        system.debug(sub.createdDate);
        Quote quo = new Quote();
        quo.Id = sub.Quote__c;
        quo.QUO_T_PaymentID__c = null;
        update quo;
        // Test  Batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());

        Database.executeBatch(new Batch06_ApplyPayment(), 100);
        Test.stopTest();
        sub = [SELECT Id, Quote__r.QUO_T_PaymentID__c
               FROM Zuora__Subscription__c
               LIMIT 1];
        system.assertEquals(false, sub.Quote__r.QUO_T_PaymentID__c == null, 'payment Id should be added');
    }
    @isTest
    static void CreateinvoiceTest(){

        Zuora__Subscription__c sub = [SELECT Id, ExpectedRenewalDate__c, Zuora__Status__c, Zuora__ServiceActivationDate__c
                                      FROM Zuora__Subscription__c
                                      LIMIT 1];
        sub.ExpectedRenewalDate__c = null;
        sub.Zuora__ServiceActivationDate__c = date.today();
        sub.Zuora__Status__c = 'Active';
        update sub;
        // Test  Batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock1());

        Database.executeBatch(new Batch06_ApplyPayment(), 1);
        Test.stopTest();

        list<Suivi_de_Souscription__c> listOfSuivi = [Select Id From Suivi_de_Souscription__c];
        system.assertEquals(3, listOfSuivi.size(), 'Suivi_de_Souscription__c Created');
        list<Suivi_de_Souscription__c> listOfSuiviActivation = [Select Id, SV_Code_Action__c From Suivi_de_Souscription__c Where SV_Code_Action__c = 'ACT011'];
        system.assertEquals(1, listOfSuiviActivation.size(), 'Suivi_de_Souscription__c activation Created');
    }
    @isTest
    static void CreatePaymentTest(){

        Zuora__Subscription__c sub = [SELECT Id, ExpectedRenewalDate__c, Zuora__Status__c, Zuora__ServiceActivationDate__c
                                      FROM Zuora__Subscription__c
                                      LIMIT 1];
        sub.ExpectedRenewalDate__c = null;
        sub.Zuora__ServiceActivationDate__c = date.today();
        sub.Zuora__Status__c = 'Active';
        update sub;
        // Test  Batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock2());

        Database.executeBatch(new Batch06_ApplyPayment(), 1);
        Test.stopTest();

        list<Suivi_de_Souscription__c> listOfSuivi = [Select Id From Suivi_de_Souscription__c];
        system.assertEquals(3, listOfSuivi.size(), 'Suivi_de_Souscription__c Created');
        list<Suivi_de_Souscription__c> listOfSuiviActivation = [Select Id, SV_Code_Action__c From Suivi_de_Souscription__c Where SV_Code_Action__c = 'ACT011'];
        system.assertEquals(1, listOfSuiviActivation.size(), 'Suivi_de_Souscription__c activation Created');
    }
}