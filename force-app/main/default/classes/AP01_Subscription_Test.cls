@isTest
public with sharing class AP01_Subscription_Test {

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
        Product2 pr = TestUtils.createProduct('CanalBox - Togo');
        insert pr;
        zqu__ZProduct__c zProd = [SELECT Id FROM zqu__ZProduct__c LIMIT 1];
        zqu__ProductRatePlan__c PRP = TestUtils.createProductRatePlan('YouScribe', zProd.Id, pr.Id, '8adc8f9975c030020175c0e3a49c7f9b', 'Base', 'other');
        insert PRP;
        zqu__productrateplancharge__c prpCharge = TestUtils.createPRPCharge(PRP.Id, 'YouScribe', '8adc8f9975c030080175c0875437858');
        insert prpCharge;
        
        list<Zuora__Subscription__c> sub = [SELECT Id, Name, Quote__c, Zuora__CustomerAccount__c,Zuora__Account__c
                                                FROM Zuora__Subscription__c];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub[0].Id, sub[0].Zuora__Account__c, 'YouScribe', zpr.Id, 'YouScribe');
        insert subProduct;
    }

    @isTest
    public static void AP01_Preview_Test() {

        list<Zuora__Subscription__c> sub = [SELECT Id, Name, Quote__c, Zuora__CustomerAccount__c,Zuora__Account__c
                                                FROM Zuora__Subscription__c];

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];

        Test.startTest();
        // AP01_Subscription.getCurrentSubFields test
        Zuora__Subscription__c subInfo = AP01_Subscription.getCurrentSubFields(sub[0].Id);

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());

        String previewResponse = AP01_Subscription.createYSPaymentAndOrder(sub[0].Id,'2022-9-21', '2022-12-12', null, null, null, null,
                                                                    '1',null ,null , null, null, null, null, false, true);

        ZuoraResponseObjects.ZuoraPreviewResponse orderPreviewResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(previewResponse, ZuoraResponseObjects.ZuoraPreviewResponse.class);

        System.assertEquals(true, orderPreviewResponse.success, 'Preview should be successful');

        Test.stopTest();
    }

    @isTest
    public static void AP01_Order_Test() {

        list<Zuora__Subscription__c> sub = [SELECT Id, Name, Quote__c, Zuora__CustomerAccount__c,Zuora__Account__c
                                                FROM Zuora__Subscription__c];

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];

        Test.startTest();
        // AP01_Subscription.getCurrentSubFields test
        Zuora__Subscription__c subInfo = AP01_Subscription.getCurrentSubFields(sub[0].Id);

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());

        String response = AP01_Subscription.createYSPaymentAndOrder(sub[0].Id,'2022-9-21', '2022-12-12', '4000','cash', null, null,
                                                                    '1',null ,null , null, null, null, null, false, false);

        ZuoraResponseObjects.ZuoraCreateOrderResponse OrderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();

        orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse)JSON.deserialize(response, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
    
        System.assertEquals(true, orderResponse.success, 'Product should be added');

        Test.stopTest();
    }
}