@isTest
public with sharing class BizaoPaymentsCall_Test {

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

        Zuora__Product__c zpr = TestUtils.createZuoraProduct();
        insert zpr;

        Zuora__Subscription__c sub = [SELECT Id FROM Zuora__Subscription__c LIMIT 1];
        RenewSubscriptionData__c renewSubscriptionData = new RenewSubscriptionData__c();
        renewSubscriptionData.RSD_Amount__c = 100;
        renewSubscriptionData.RSD_OrderId__c = 'Test01';
        renewSubscriptionData.RSD_SubscriptionId__c = sub.Id;
        renewSubscriptionData.RSD_NumberOfPeriods__c = 1;     
        renewSubscriptionData.RSD_Payment_Method__c = 'Mobile_Money'; // modeDePaiement
        renewSubscriptionData.RSD_TransactionNumber__c = null;
        renewSubscriptionData.RSD_Operator__c = 'Moov';
        renewSubscriptionData.RSD_DollarPayment__c = null;
        renewSubscriptionData.RSD_CDFPayment__c = null;
        renewSubscriptionData.RSD_DollarRefund__c = null;
        renewSubscriptionData.RSD_CDFRefund__c = null;
        renewSubscriptionData.RSD_SelectedRenewOffer__c = 'REABO';
        renewSubscriptionData.RSD_IsOrderOpen__c = false;                                           
        insert renewSubscriptionData;
    }

    @isTest
    public static void mobileMoneyPaymentCall_SucceedTest(){
        Zuora__Subscription__c sub = [SELECT Id FROM Zuora__Subscription__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new BizaoMock());

         String order = 'Test01';    

        String mmPayment = BizaoPaymentsCall.callMobileMoneyPayment('Test01');
        System.assertEquals(true, mmPayment.contains('"status" : 201'), 'Mobile Money response should be succeed');
              Test.stopTest();
        RenewSubscriptionData__c  renewSubscriptionDataRetreive  = [SELECT Id, RSD_Amount__c, RSD_IsOrderOpen__c, RSD_OrderId__c
                                                            FROM RenewSubscriptionData__c
                                                            WHERE RSD_OrderId__c = :'Test01'
                                                            LIMIT 1];
        System.assertEquals(100, renewSubscriptionDataRetreive.RSD_Amount__c, 'The amount of the order should be save in the RenewSubscriptionData__c Object'); 
        System.assertEquals(true, renewSubscriptionDataRetreive.RSD_IsOrderOpen__c, 'The amount of the order should be save in the RenewSubscriptionData__c Object');
                                                   
    }

    @isTest
    public static void callBankPayment_SucceedTest(){
        Zuora__Subscription__c sub = [SELECT Id FROM Zuora__Subscription__c LIMIT 1];
        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new BizaoMock());
            String order = 'Test01';

            String mmPayment = BizaoPaymentsCall.callBankPayment(order);
            System.assertEquals(true, mmPayment.contains('"status" : 201'), 'Mobile Money response should be succeed');
              Test.stopTest();
        RenewSubscriptionData__c  renewSubscriptionDataRetreive  = [SELECT Id, RSD_Amount__c, RSD_IsOrderOpen__c
                                                            FROM RenewSubscriptionData__c
                                                            WHERE RSD_OrderId__c = :order
                                                            LIMIT 1];
        System.assertEquals(100, renewSubscriptionDataRetreive.RSD_Amount__c, 'The amount of the order should be save in the RenewSubscriptionData__c Object');
        System.assertEquals(true, renewSubscriptionDataRetreive.RSD_IsOrderOpen__c, 'The amount of the order should be save in the RenewSubscriptionData__c Object');                                               
    }

    @isTest
    public static void callRenewSubPreview_SucceedTest(){

        Zuora__Subscription__c sub = [SELECT Id, Zuora__Account__c
                                            FROM Zuora__Subscription__c
                                            LIMIT 1];
        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            String operator = 'moov';
            String order = 'Test01';
            Boolean withoutTax = false; 
            Integer nbPeriodes = 1;
            String modeDePaiement = 'Mobile_Money';
            Boolean fromUI = true;
            String transactionNumber = null;
            Double dollarPayment = null;
            Integer CDFPayment = null;
            Integer dollarRefund = null;                          
            Integer CDFRefund = null;
            String selectedRenewOffer = 'REABO';
            String PRPId = null;

            String callRenewSubPreviewJson = BizaoPaymentsCall.callRenewSubPreview(sub.Id, nbPeriodes, withoutTax, modeDePaiement, 
                                                                        fromUI, operator, transactionNumber,
                                                                        dollarPayment, CDFPayment, dollarRefund, 
                                                                        CDFRefund, selectedRenewOffer, PRPId);
        Test.stopTest();

        RenewSubPreviewResponse renewSubPreviewResponse = RenewSubPreviewResponse.parse(callRenewSubPreviewJson);
        RenewSubscriptionData__c  renewSubscriptionData  = [SELECT Id, RSD_Amount__c, RSD_OrderId__c 
                                                            FROM RenewSubscriptionData__c
                                                            WHERE RSD_OrderId__c = :renewSubPreviewResponse.bizaoOrderId
                                                            LIMIT 1];
        System.assertEquals(60000, renewSubscriptionData.RSD_Amount__c, 'The amount of the order should be save in the RenewSubscriptionData__c Object'); 
        System.assert(renewSubscriptionData.RSD_OrderId__c.contains('SUB1-'), 'The order Id start with A-S00000400-');                                                  
    }

    @isTest
    public Static void UpgradeProductSucceededRequest_test(){
        Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__status__c
                                         FROM Zuora__Subscription__c LIMIT 1];
        newSub.Zuora__Status__c = 'Active';
      //  newSub.isCollaborator__c = 'Y';
        update newSub;
        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
        insert subProduct;

        Integer nbPeriodes = 2;
        Boolean withoutTax = false; 
        String modeDePaiement = 'Mobile_Money'; 
        Boolean fromUI = true;
        String operator = 'Moov'; 
        String transactionNumber = null;
        Double dollarPayment = null;
        Integer CDFPayment = null;
        Integer dollarRefund = null; 
        Integer CDFRefund = null; 
        String selectedRenewOffer = 'REABO_UPG';

        Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            //with tax                                                
            String upgradeResponseJson = BizaoPaymentsCall.callUpgradeSubscriptionProductPreview(newSub.Id, nbPeriodes, modeDePaiement, 
                                                                                                operator, transactionNumber,
                                                                                                dollarPayment, CDFPayment, dollarRefund, 
                                                                                                CDFRefund, selectedRenewOffer);
        Test.stopTest();

        RenewSubPreviewResponse upgradeResponse = RenewSubPreviewResponse.parse(upgradeResponseJson); 
  
        RenewSubscriptionData__c  renewSubscriptionData  = [SELECT Id, RSD_Amount__c, RSD_OrderId__c 
                                                                FROM RenewSubscriptionData__c
                                                                WHERE RSD_OrderId__c = :upgradeResponse.bizaoOrderId
                                                                LIMIT 1];
        System.assertEquals(60000, renewSubscriptionData.RSD_Amount__c, 'The amount of the order should be save in the RenewSubscriptionData__c Object');
        System.assert(renewSubscriptionData.RSD_OrderId__c.contains('A-S00000400-'), 'The order Id start with A-S00000400-'); 
    }

}