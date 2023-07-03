@isTest
public class BizaoPayment_Test {
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
    public static void mobileMoneyPayment_SucceedTest(){
        Zuora__Subscription__c sub = [SELECT Id FROM Zuora__Subscription__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new BizaoMock());
        boolean isFranco = BizaoPayments.isFrancophone();
        System.assertEquals(false, isFranco, 'Current Country not related to BIZAO ');
        string mmPayment = BizaoPayments.mobileMoneyPayment(100, 'moov', 'Test01', sub.Id);
        System.assertEquals(true, mmPayment.contains('"status" : 201'), 'Mobile Money response should be succeed');
        string paymentStatus = BizaoPayments.mobileMoneyStatus('moov', 'Test-01', 'TG');
        System.assertEquals(true, paymentStatus.contains('"status" : "Successful"'), 'Mobile Money transction should be succeed');
        Test.stopTest();
    }
    @isTest
    public static void bankPayment_SucceedTest(){
        Zuora__Subscription__c sub = [SELECT Id FROM Zuora__Subscription__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new BizaoMock());
        string bankPayment = BizaoPayments.bankPayment(100, 'Test01', sub.Id);
        System.assertEquals(true, bankPayment.contains('"status" : 201'), 'Credit response should be succeed');
        string paymentStatus = BizaoPayments.bankPaymentStatus('Test01', sub.Id);
        System.assertEquals(true, paymentStatus.contains('"status" : "Successful"'), 'Credit transction should be succeed');
        Test.stopTest();
    }
    @isTest
    public static void retrySimpleRenewPayment(){
        Zuora__Subscription__c sub = [SELECT Id, Zuora__Account__c, Zuora__Status__c FROM Zuora__Subscription__c LIMIT 1];
        sub.Zuora__Status__c = 'Active';
        update sub;
        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;
        RenewSubscriptionData__c renewData = new RenewSubscriptionData__c();
        renewData.RSD_SubscriptionId__c = sub.id;
        renewData.RS_Status__c = 'ST002';
        renewData.RSD_SelectedRenewOffer__c = 'REABO';
        renewData.RSD_Payment_Method__c = 'Mobile_Money';
        renewData.RSD_OrderId__c = 'A-S00000541-2022961515';
        renewData.RSD_NumberOfPeriods__c = 2;
        renewData.RSD_Operator__c = 'Orange';
        insert renewData;
        list<Id> listOfRenewdataId = new list<Id> {renewData.Id};

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:BizaoApiUrl',  new BizaoMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        BizaoPayments.retryPayment(listOfRenewdataId);
        Test.stopTest();

        RenewSubscriptionData__c renewInfo = [SELECT Id, RS_Status__c FROM RenewSubscriptionData__c WHERE id = :renewData.Id LIMIT 1];
        System.assertEquals('ST001', renewInfo.RS_Status__c, 'renew should be created');
        /* renewData.RSD_SelectedRenewOffer__c = 'REABO_UPG';
           update renewData;
           BizaoPayments.retryPayment(listOfRenewdataId[0]);
           renewData.RSD_SelectedRenewOffer__c = 'REABO_UPG';
           update renewData;
           BizaoPayments.retryPayment(listOfRenewdataId[0]);
         */
    }
    @isTest
    public static void retryUpgradeRenewPayment(){
        Zuora__Subscription__c sub = [SELECT Id, Zuora__Account__c, Zuora__Status__c FROM Zuora__Subscription__c LIMIT 1];
        sub.Zuora__Status__c = 'Active';
        update sub;
        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subProduct;
        RenewSubscriptionData__c renewData = new RenewSubscriptionData__c();
        renewData.RSD_SubscriptionId__c = sub.id;
        renewData.RS_Status__c = 'ST002';
        renewData.RSD_SelectedRenewOffer__c = 'REABO_UPG';
        renewData.RSD_Payment_Method__c = 'Mobile_Money';
        renewData.RSD_OrderId__c = 'A-S00000541-2022961515';
        renewData.RSD_NumberOfPeriods__c = 2;
        renewData.RSD_Operator__c = 'Orange';
        insert renewData;
        list<Id> listOfRenewdataId = new list<Id> {renewData.Id};

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:BizaoApiUrl',  new BizaoMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        BizaoPayments.retryPayment(listOfRenewdataId);
        Test.stopTest();

        RenewSubscriptionData__c renewInfo = [SELECT Id, RS_Status__c FROM RenewSubscriptionData__c WHERE id = :renewData.Id LIMIT 1];
        System.assertEquals('ST001', renewInfo.RS_Status__c, 'renew should be created');

    }
    @isTest
    public static void retryDowngradeRenewPayment(){
        Zuora__Subscription__c sub = [SELECT Id, Zuora__Account__c, Zuora__Status__c FROM Zuora__Subscription__c LIMIT 1];
        sub.Zuora__Status__c = 'Active';
        update sub;
        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;
        RenewSubscriptionData__c renewData = new RenewSubscriptionData__c();
        renewData.RSD_SubscriptionId__c = sub.id;
        renewData.RS_Status__c = 'ST002';
        renewData.RSD_SelectedRenewOffer__c = 'REABO_DOWN';
        renewData.RSD_Payment_Method__c = 'Mobile_Money';
        renewData.RSD_OrderId__c = 'A-S00000541-2022961515';
        renewData.RSD_NumberOfPeriods__c = 2;
        renewData.RSD_Operator__c = 'Orange';
        insert renewData;
        list<Id> listOfRenewdataId = new list<Id> {renewData.Id};

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:BizaoApiUrl',  new BizaoMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        BizaoPayments.retryPayment(listOfRenewdataId);
        Test.stopTest();

        RenewSubscriptionData__c renewInfo = [SELECT Id, RS_Status__c FROM RenewSubscriptionData__c WHERE id = :renewData.Id LIMIT 1];
        System.assertEquals('ST001', renewInfo.RS_Status__c, 'renew should be created');
    }
}