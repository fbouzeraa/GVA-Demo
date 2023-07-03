/**
 * Classe permettant de tester les fonctionnalités de USSDTransaction.
 * code coverage : 94%
 * @author Jackie Abi Nassif
 * @date 06 / 10 / 2022
 */
@isTest
public with sharing class WS08_USSDTransaction_Test {
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
    public static void transaction_Test(){
        zqu__ProductRatePlan__c startPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'start' LIMIT 1];
        zqu__ProductRatePlan__c canalPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'canalBox' LIMIT 1];
        Product2 pr = [SELECT Id FROM Product2 LIMIT 1];
        zqu__ProductRatePlanCharge__c startPRPCharge = TestUtils.createPRPCharge(startPRP.Id, 'Start', '572525352752538585896983');
        insert startPRPCharge;
        zqu__productrateplanchargetier__c startChargePrice = TestUtils.createPRPChargePrice(startPRPCharge.Id);
        insert startChargePrice;
        Zuora__Subscription__c sub = [SELECT Id, Zuora__Status__c,Zuora__Account__c,Name, BoxNumber__c,ExpectedRenewalDate__c,Zuora__Account__r.Name 
                                        FROM Zuora__Subscription__c WHERE Zuora__SubscriptionNumber__c = 'A-S00000401' LIMIT 1];
        sub.Zuora__Status__c = 'Active';
        sub.SUB_T_Produit_De_Base__c = 'Start';
        sub.isCollaborator__c = 'Y';
        try {
            update sub;
        } catch (Exception e) {
            system.debug('update sub error '+ e);
        }

        Map<String, HttpCalloutMock> endpoint3TestResp = new Map<String, HttpCalloutMock>();
        endpoint3TestResp.put('callout:DPOApiUrl', new DPOMock());
        endpoint3TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

        //private static final String RESOURCE_PATH = '/services/apexrest' + RESOURCE_URL;
        RestRequest request = new RestRequest(); // request test 1 with no body
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"":""}');

        RestContext.Response = new RestResponse();

        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint3TestResp));
        Test.startTest();
        string response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('false'), 'body should be provided');

        request = new RestRequest(); // request test 2 invalid boxNumber
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"routerNumber":"ALCL:B34AE1B4","transactionNumber":"134-976867","prepaidPeriod":2,"operator":"test","referenceNumber":"01"}');
        RestContext.Response = new RestResponse();
        response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('false'), 'No subscription for this boxNumber');

        request = new RestRequest(); // request test 2.1 missing transactionNumber
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"routerNumber":"ALCL:B34AE1B4","prepaidPeriod":2,"operator":"test","referenceNumber":"01"}');
        RestContext.Response = new RestResponse();
        response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('false'), 'empty required field');

        request = new RestRequest(); // request test 2.2 missing prepaidPeriod
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"routerNumber":"ALCL:B34AE1B4","transactionNumber":"134-976867","operator":"test","referenceNumber":"01"}');
        RestContext.Response = new RestResponse();
        response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('false'), 'empty required field');

        request = new RestRequest(); // request test 2.3 missing operator
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"routerNumber":"ALCL:B34AE1B4","transactionNumber":"134-976867","prepaidPeriod":2,"referenceNumber":"01"}');
        RestContext.Response = new RestResponse();
        response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('false'), 'empty required field');

        request = new RestRequest(); // request test 2.4 missing reference Number
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"routerNumber":"ALCL:B34AE1B4","transactionNumber":"134-976867","prepaidPeriod":2,"operator":"test"}');
        RestContext.Response = new RestResponse();
        response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('false'), 'empty required field');

        request = new RestRequest(); // request test 3 with renew
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"routerNumber":"ALCL:B34AF4A3","transactionNumber":"134-976867","prepaidPeriod":2,"operator":"test","referenceNumber":"Start"}');
        RestContext.Response = new RestResponse();
        response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('true'), 'transaction successful');

        request = new RestRequest(); // request test 4 with invalid refreneceNumber
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"routerNumber":"ALCL:B34AF4A3","transactionNumber":"134-976867","prepaidPeriod":2,"operator":"test","referenceNumber":"base"}');
        RestContext.Response = new RestResponse();
        response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('false'), 'transaction successful');

        String objectTest = USSDObjects.post;

        Test.stopTest();
    }

    @isTest
    public static void transactionPremium_Test(){

        zqu__ProductRatePlan__c startPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'start' LIMIT 1];
        zqu__ProductRatePlan__c canalPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'canalBox' LIMIT 1];
        Product2 pr = [SELECT Id FROM Product2 LIMIT 1];
        zqu__ProductRatePlanCharge__c startPRPCharge = TestUtils.createPRPCharge(startPRP.Id, 'Start', '572525352752538585896983');
        insert startPRPCharge;
        zqu__productrateplanchargetier__c startChargePrice = TestUtils.createPRPChargePrice(startPRPCharge.Id);
        insert startChargePrice;
        Zuora__Subscription__c sub = [SELECT Id, Zuora__Status__c,Zuora__Account__c,Name, BoxNumber__c,ExpectedRenewalDate__c,Zuora__Account__r.Name 
                                        FROM Zuora__Subscription__c WHERE Zuora__SubscriptionNumber__c = 'A-S00000401' LIMIT 1];
        sub.Zuora__Status__c = 'Active';
        sub.SUB_T_Produit_De_Base__c = 'Premium';
        try {
            update sub;
        } catch (Exception e) {
            system.debug('update sub error 2 '+ e);
        }

        Map<String, HttpCalloutMock> endpoint3TestResp = new Map<String, HttpCalloutMock>();
        endpoint3TestResp.put('callout:DPOApiUrl', new DPOMock());
        endpoint3TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint3TestResp));
        Test.startTest();

        RestRequest request = new RestRequest(); // request test 3 with douwngrade
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"routerNumber":"ALCL:B34AF4A3","transactionNumber":"134-976867","prepaidPeriod":2,"operator":"test","referenceNumber":"Start"}');
        RestContext.Response = new RestResponse();
        String response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('true'), 'transaction successful');
        
        Test.stopTest();
    }
    
    @isTest
    public static void upgradeTransaction_Test(){

        zqu__ProductRatePlan__c startPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'start' LIMIT 1];
        zqu__ProductRatePlan__c canalPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'canalBox' LIMIT 1];
        Product2 pr = [SELECT Id FROM Product2 LIMIT 1];
        zqu__ProductRatePlanCharge__c startPRPCharge = TestUtils.createPRPCharge(startPRP.Id, 'Start', '572525352752538585896983');
        insert startPRPCharge;
        zqu__productrateplanchargetier__c startChargePrice = TestUtils.createPRPChargePrice(startPRPCharge.Id);
        insert startChargePrice;
        Zuora__Subscription__c sub = [SELECT Id, Zuora__Status__c,Zuora__Account__c,Name, BoxNumber__c,ExpectedRenewalDate__c,Zuora__Account__r.Name 
                                        FROM Zuora__Subscription__c WHERE Zuora__SubscriptionNumber__c = 'A-S00000401' LIMIT 1];
        sub.Zuora__Status__c = 'Active';
        sub.SUB_T_Produit_De_Base__c = 'Start';
        try {
            update sub;
        } catch (Exception e) {
            system.debug('update sub error 2 '+ e);
        }

        Map<String, HttpCalloutMock> endpoint3TestResp = new Map<String, HttpCalloutMock>();
        endpoint3TestResp.put('callout:DPOApiUrl', new DPOMock());
        endpoint3TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint3TestResp));
        Test.startTest();

        RestRequest request = new RestRequest(); // request test with upgrade
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/Transaction/*';
        request.requestURI = '/v1/Transaction/';
        RestContext.request = request;
        request.requestBody = Blob.valueOf('{"routerNumber":"ALCL:B34AF4A3","transactionNumber":"134-976867","prepaidPeriod":2,"operator":"test","referenceNumber":"Premium"}');
        RestContext.Response = new RestResponse();
        String response = WS08_USSDTransaction.postTransaction();
        system.assertEquals(true, response.contains('true'), 'transaction successful');
        
        Test.stopTest();
    }
}