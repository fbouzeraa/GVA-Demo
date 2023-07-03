/**
 * Classe permettant de tester les fonctionnalités de USSDOffers.
 * code coverage : 94 %
 * @author Jackie Abi Nassif
 * @date 23 / 05 / 2023
 */
@isTest
public with sharing class WS04_USSDMTNOffers_Test {
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
    // test with no param provided
    // test with upgrade and renew
    @isTest
    public static void doPOST_Test(){
        zqu__ProductRatePlan__c startPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'start' LIMIT 1];
        startPRP.Bandwidth__c = '10Mb/s';
            update startPRP;
        zqu__ProductRatePlan__c startPRPColab = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE category__c = 'Collaborator' LIMIT 1];
        Product2 pr = [SELECT Id FROM Product2 LIMIT 1];
        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        zqu__ProductRatePlanCharge__c startPRPCharge = TestUtils.createPRPCharge(startPRP.Id, 'Start', '572525352752538585896983');
        startPRPCharge.zqu__Type__c = 'Recurring';
            insert startPRPCharge;
        zqu__ProductRatePlanCharge__c startPRPCharge2 = TestUtils.createPRPCharge(startPRPColab.Id, 'collab', '57252765275253858589698344');
        startPRPCharge2.zqu__Type__c = 'Recurring';
            insert startPRPCharge2;
        zqu__productrateplanchargetier__c startChargePrice = TestUtils.createPRPChargePrice(startPRPCharge.Id);
            insert startChargePrice;
        zqu__productrateplanchargetier__c startChargePrice2 = new zqu__productrateplanchargetier__c(zqu__Price__c = 909, zqu__ProductRatePlanCharge__c = startPRPCharge2.Id, zqu__ZuoraId__c = '123321144', zqu__DiscountPercentage__c = 50);
            insert startChargePrice2;
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
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;

        Map<String, HttpCalloutMock> endpoint3TestResp = new Map<String, HttpCalloutMock>();
        endpoint3TestResp.put('callout:MTNAPIURL', new MTNMock());
        endpoint3TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

        //private static final String RESOURCE_PATH = '/services/apexrest' + RESOURCE_URL;
        RestRequest request = new RestRequest(); // request test 1
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/MTNOffers/*';
        request.requestURI = '/v1/MTNOffers/';
        RestContext.request = request;

        RestContext.Response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint3TestResp));
        Test.startTest();
        string response = WS04_USSDMTNOffers.handleGet();
        system.assertEquals(true, response.contains('false'), 'Parameter shoud be provided');

        request = new RestRequest(); // request test 2
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/MTNOffers/*';
        request.requestURI = '/v1/MTNOffers/';
        request.requestBody = Blob.valueOf('{"arguments": [{"key": {"value": "boxNumber"},"value": {"value": "ALCL:B"}}, {"key": {"value": "JOURNEY_CURRENT_STATUS"},"value": {"value": "PUBLISHED"}},{"key": {"value": "ACCOUNT_HOLDER_EMAIL"}, "value": {"value": ""}},{"key": {"value": "ACCOUNT_HOLDER_MSISDN"},"value": {"value": "242068207839"}}],"languageCode": "fr","sessionIdentifier": "38c32805-88e7-4d54-b183-e82afa1906b7","journeyIdentifier": "3cf37ed3-ff3a-4ba9-bf72-ce6dbda72417"}');
        RestContext.request = request;

        RestContext.Response = new RestResponse();
        response = WS04_USSDMTNOffers.handleGet();
        system.assertEquals(true, response.contains('false'), 'No subscription for this boxNumber');

        request = new RestRequest(); // request test 3
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/MTNOffers/*';
        request.requestURI = '/v1/MTNOffers/';
        request.requestBody = Blob.valueOf('{"arguments": [{"key": {"value": "boxNumber"},"value": {"value": "'+sub.BoxNumber__c+'"}}, {"key": {"value": "JOURNEY_CURRENT_STATUS"},"value": {"value": "PUBLISHED"}},{"key": {"value": "ACCOUNT_HOLDER_EMAIL"}, "value": {"value": ""}},{"key": {"value": "ACCOUNT_HOLDER_MSISDN"},"value": {"value": "242068207839"}}],"languageCode": "fr","sessionIdentifier": "38c32805-88e7-4d54-b183-e82afa1906b7","journeyIdentifier": "3cf37ed3-ff3a-4ba9-bf72-ce6dbda72417"}');
        RestContext.request = request;

        RestContext.Response = new RestResponse();
        response = WS04_USSDMTNOffers.handleGet();
        system.debug('verify response 1 '+response);
        system.assertEquals(true, response.contains('true'), 'subscription should be found  and 2 offers should be returned');

        Test.stopTest();
    }
    // test WS with downgrade
    @isTest
    public static void doPOST2_Test(){

        zqu__ProductRatePlan__c startPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'start' LIMIT 1];
        startPRP.Bandwidth__c = '10Mb/s';
        update startPRP;
        Product2 pr = [SELECT Id FROM Product2 LIMIT 1];
        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        zqu__ProductRatePlanCharge__c startPRPCharge = TestUtils.createPRPCharge(startPRP.Id, 'Start', '572525352752538585896983');
        startPRPCharge.zqu__Type__c = 'Recurring';
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
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subProduct;

        Map<String, HttpCalloutMock> endpoint3TestResp = new Map<String, HttpCalloutMock>();
        endpoint3TestResp.put('callout:MTNAPIURL', new MTNMock());
        endpoint3TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

        RestRequest request = new RestRequest(); // request test 4
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'POST';
        request.resourcePath = '/v1/MTNOffers/*';
        request.requestURI = '/v1/MTNOffers/';
        request.requestBody = Blob.valueOf('{"arguments": [{"key": {"value": "boxNumber"},"value": {"value": "'+sub.BoxNumber__c+'"}}, {"key": {"value": "JOURNEY_CURRENT_STATUS"},"value": {"value": "PUBLISHED"}},{"key": {"value": "ACCOUNT_HOLDER_EMAIL"}, "value": {"value": ""}},{"key": {"value": "ACCOUNT_HOLDER_MSISDN"},"value": {"value": "242068207839"}}],"languageCode": "fr","sessionIdentifier": "38c32805-88e7-4d54-b183-e82afa1906b7","journeyIdentifier": "3cf37ed3-ff3a-4ba9-bf72-ce6dbda72417"}');
        RestContext.request = request;

        RestContext.Response = new RestResponse();

        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint3TestResp));
        Test.startTest();

        String response = WS04_USSDMTNOffers.handleGet();
        system.debug('verify response 2 '+response);
        system.assertEquals(true, response.contains('true'), 'subscription should be found and 2 offers should be returned');

        Test.stopTest();
    }
}