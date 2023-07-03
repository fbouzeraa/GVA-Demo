@isTest
public class VFC02_InvoiceController_Test {
    @TestSetup
    static void makeData(){
        //Get a successful response from mock
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
    public static void sendRenewInvoiceByEmailSuccessfulRequest_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_T_Payment_Number__c, Zuora__Account__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        newSub.SUB_T_Payment_Number__c = 'P-00000014';
        update newSub;
        Zuora__ZInvoice__c zInv = new Zuora__ZInvoice__c(Zuora__Account__c = newSub.Zuora__Account__c, Zuora__ZuoraId__c = '134543wew', Zuora__BillingAccount__c = newSub.Zuora__CustomerAccount__c);
        insert zInv;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        string mailResult = VFC02_InvoiceController.sendInvoiceByEmail(newSub.Id, false);
        boolean isSent = mailResult.contains(system.label.Email_Is_Sent);

        System.assertEquals(true, isSent, 'Mail should be sent');
        Test.stopTest();
    }
    @isTest
    public static void sendInvoiceByEmailFromInvoiceId_Test(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());

        VFC02_InvoiceController.sendInvoiceByEmailFromInvoiceId('134543wew', 'email@test.com');
        Test.stopTest();
    }
    @isTest
    public static void sendRenewInvoiceByEmailFailedRequest_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_T_Payment_Number__c, Zuora__Account__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        newSub.SUB_T_Payment_Number__c = 'P-0000001';
        update newSub;
        Zuora__ZInvoice__c zInv = new Zuora__ZInvoice__c(Zuora__Account__c = newSub.Zuora__Account__c, Zuora__ZuoraId__c = '134543wew', Zuora__BillingAccount__c = newSub.Zuora__CustomerAccount__c);
        insert zInv;
        Account acc = [SELECT Id, PersonEmail
                       FROM Account
                       WHERE id = :newSub.Zuora__Account__c
                       LIMIT 1];
        acc.PersonEmail = null;
        update acc;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        string mailResult = VFC02_InvoiceController.sendInvoiceByEmail(newSub.Id, false);

        boolean isSent = mailResult.contains(system.label.Empty_Email_Address);
        System.assertEquals(true, isSent, 'Mail should not be sent');
        Test.stopTest();
    }
    @isTest
    public static void sendOriginalInvoiceByEmail_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_T_Payment_Number__c, Zuora__Account__c, Zuora__ServiceActivationDate__c, Zuora__Status__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];

        Account acc = [SELECT id, name
                       FROM Account
                       WHERE id =:newSub.Zuora__Account__c];
        newSub.Zuora__ServiceActivationDate__c = Date.newInstance(2021, 02, 17);
        newSub.Zuora__Status__c = 'Active';
        update newSub;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        string mailResult = VFC02_InvoiceController.sendInvoiceByEmail(acc.Id, true);
        boolean isSent = mailResult.contains(system.label.Email_Is_Sent);
        System.assertEquals(true, isSent, 'Mail should be sent');
        Test.stopTest();
    }
    @isTest
    public static void sendOriginalInvoiceByEmailFailedRequest_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_T_Payment_Number__c, Zuora__Account__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        string mailResult = VFC02_InvoiceController.sendInvoiceByEmail(newSub.Zuora__Account__c, true);
        boolean isSent = mailResult.contains(system.label.Bill_Not_Found);
        System.assertEquals(true, isSent, 'Mail should not be sent');
        Test.stopTest();
    }
    @isTest
    public static void sendOriginalInvoiceByEmailFailedRequest1_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_T_Payment_Number__c, Zuora__Account__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 401));
        string mailResult = VFC02_InvoiceController.sendInvoiceByEmail(newSub.Zuora__Account__c, true);
        boolean isSent = mailResult.contains(system.label.Bill_Not_Found);
        System.assertEquals(true, isSent, 'Mail should not be sent');
        Test.stopTest();
    }
    @isTest
    public static void showRenewInvoiceSuccessfulRequest_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_T_Payment_Number__c, Zuora__Account__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        newSub.SUB_T_Payment_Number__c = 'P-00000014';
        update newSub;
        Zuora__ZInvoice__c zInv = new Zuora__ZInvoice__c(Zuora__Account__c = newSub.Zuora__Account__c, Zuora__ZuoraId__c = '134543wew', Zuora__BillingAccount__c = newSub.Zuora__CustomerAccount__c);
        insert zInv;
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ApexPages.currentPage().getParameters().put('id', String.valueOf(newSub.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(newSub);
        VFC02_InvoiceController testInvoice = new VFC02_InvoiceController(sc);
        Test.StopTest();
    }
    @isTest
    public static void showRenewInvoiceFailedRequest_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_T_Payment_Number__c, Zuora__Account__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        newSub.SUB_T_Payment_Number__c = 'P-00000014';
        update newSub;
        /* Zuora__ZInvoice__c zInv = new Zuora__ZInvoice__c(Zuora__Account__c = newSub.Zuora__Account__c, Zuora__ZuoraId__c = '134543wew');
           insert zInv;*/
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 401));
        ApexPages.currentPage().getParameters().put('id', String.valueOf(newSub.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(newSub);
        VFC02_InvoiceController testInvoice = new VFC02_InvoiceController(sc);
        boolean result = testInvoice.toString().contains(system.label.Invoice_Id_Not_Found);
        system.assertEquals(True, result, 'No  renewal Subscription available');
        Test.StopTest();
    }
    @isTest
    public static void showOriginalInvoiceSuccessfulRequest_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__ServiceActivationDate__c, SUB_T_Payment_Number__c, Zuora__Account__c, Zuora__Status__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Zuora__ZInvoice__c zInv = new Zuora__ZInvoice__c(Zuora__Account__c = newSub.Zuora__Account__c, Zuora__ZuoraId__c = '134543wew', Zuora__BillingAccount__c = newSub.Zuora__CustomerAccount__c);
        insert zInv;
        Account acc = [SELECT id, name
                       FROM Account
                       WHERE id =:newSub.Zuora__Account__c];

        newSub.Zuora__Status__c = 'Active';
        newSub.Zuora__ServiceActivationDate__c = Date.newInstance(2021, 02, 17);
        update newSub;
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ApexPages.currentPage().getParameters().put('id', String.valueOf(acc.Id));
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        VFC02_InvoiceController testInvoice = new VFC02_InvoiceController(sc);

        Test.StopTest();
    }
    @isTest
    public static void showOriginalInvoiceFailedRequest_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_T_Payment_Number__c, Zuora__Account__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Zuora__ZInvoice__c zInv = new Zuora__ZInvoice__c(Zuora__Account__c = newSub.Zuora__Account__c, Zuora__ZuoraId__c = '134543wew', Zuora__BillingAccount__c = newSub.Zuora__CustomerAccount__c);
        insert zInv;
        Account acc = [SELECT id, name
                       FROM Account
                       WHERE id =:newSub.Zuora__Account__c];
        Test.StartTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        ApexPages.currentPage().getParameters().put('id', String.valueOf(newSub.Zuora__Account__c));
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        VFC02_InvoiceController testInvoice = new VFC02_InvoiceController(sc);
        boolean result = testInvoice.toString().contains(system.label.Bill_Not_Found);
        system.assertEquals(True, result, 'Subscription should be active to show invoice');
        pageReference accountPage = testInvoice.doCancel();
        result = string.valueOf(accountPage).contains(acc.id);

        Test.StopTest();
    }
}