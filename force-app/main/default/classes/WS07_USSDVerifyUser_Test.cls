/**
 * Classe permettant de tester les fonctionnalités de USSDVerifyUser.
 *
 * @author Jackie abi NAssif
 * @date 06 / 10 / 2022
 */
@isTest
public with sharing class WS07_USSDVerifyUser_Test {
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
    public static void verifyUser_Test(){

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
        RestRequest request = new RestRequest(); // request test 1
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'GET';
        request.resourcePath = '/v1/VerifyUser/*';
        request.requestURI = '/v1/VerifyUser/';
        RestContext.request = request;

        RestContext.Response = new RestResponse();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint3TestResp));
        Test.startTest();
        string response = WS07_USSDVerifyUser.verifyUser();
        system.assertEquals(true, response.contains('false'), 'Parameter shoud be provided');


        request = new RestRequest(); // request test 2
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'GET';
        request.resourcePath = '/v1/VerifyUser/*';
        request.requestURI = '/v1/VerifyUser/';
        request.addParameter('phoneNumber', '12345678');
        RestContext.request = request;

        RestContext.Response = new RestResponse();
        response = WS07_USSDVerifyUser.verifyUser();
        system.assertEquals(true, response.contains('false'), 'No subscription for this phoneNumber');

        request = new RestRequest(); // request test 3
        request.addHeader('Content-Type', 'application/json');
        request.httpMethod = 'GET';
        request.resourcePath = '/v1/VerifyUser/*';
        request.requestURI = '/v1/VerifyUser/';
        request.addParameter('routerNumber', 'ALCL:B34AF4A3');
        RestContext.request = request;

        RestContext.Response = new RestResponse();
        response = WS07_USSDVerifyUser.verifyUser();
        system.assertEquals(true, response.contains('true'), 'Subscription for this boxNumbr');

        Test.stopTest();
    }
}