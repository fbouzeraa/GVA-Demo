/**
 * Classe test pour WS06_DPOAPI
 * Couverture: 81
 * @author Yara Bourdoukan
 * @date 2021-12-07
 */

@isTest
public with sharing class WS06_DPOAPI_Test {
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

        Zuora__Product__c zpr = TestUtils.createZuoraProduct();
        insert zpr;
        user currentUser = [SELECT USR_DistributeurID__c, Profile.Name
                            FROM User
                            WHERE id = :UserInfo.getUserId()];

        list<Account> listAccount = [SELECT id
                                     FROM Account
                                     WHERE ACC_Distributor_Number__c  = :currentUser.USR_DistributeurID__c];
        if(listAccount.size() > 0 && listAccount != null) {
            delete listAccount;
        }

    }

    @isTest
    public static void DowngradeRenewSuccessful_Test(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:DPOApiUrl', new DPOMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        Zuora__Subscription__c sub = [SELECT Zuora__Status__c, id, Zuora__Account__c
                                      FROM Zuora__Subscription__c LIMIT 1];

        sub.Zuora__Status__c = 'Active';
        update sub;

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];

        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/getPayment/';

        RestRequest request = new RestRequest();
        request.requestUri = restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST TEST","CustomerCountry":"Togo","TransactionRef":"ALCL:B34AF4A3","CompanyToken":"A025-4B8B-989B-A8921DD31094","TransactionAmount":60000}');
        RestContext.request = request;
        string response = WS06_DPOAPI.doGet();
        system.debug(response);
        system.assertEquals(true, response.contains(System.label.Successful_Response), 'Renew with downgrade request should be succeeded');

        //exception error
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST TEST","CustomerCountry":"Togo","TransactionRef":"ALCL:B34AF4A3","CompanyToken":"A025-4B8B-989B-A8921DD31094","TransactionAmount":6000}');
        RestContext.request = request;
        response = WS06_DPOAPI.doGet();
        test.stopTest();

    }

    @isTest
    public static void DowngradeRenewFailed2_Test(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:DPOApiUrl', new DPOMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock(false, false, 300));
        Zuora__Subscription__c sub = [SELECT Zuora__Status__c, id, Zuora__Account__c
                                      FROM Zuora__Subscription__c LIMIT 1];

        sub.Zuora__Status__c = 'Active';
        update sub;

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];

        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;
        Suivi_de_Souscription__c sv1 = new Suivi_de_Souscription__c();
        DPObjects.SuiviDetails svDetail = new DPObjects.SuiviDetails();
        svDetail.IDSouscription = Sub.Id;
        svDetail.ModeDePaiement = 'Mobile_Money';
        svDetail.NumeroDeTransaction = 'frfsd';
        svDetail.Periode = 2;
        svDetail.operateur = 'DPO';
        svDetail.typeOperation = 1;
        sv1.SV_Id_Souscription__c = Sub.Id;
        // dest SF
        sv1.SV_Destination__c = 'DST002';
        // reabo simple
        sv1.SV_Code_Action__c = 'ACT003';
        sv1.SV_Details__c = JSON.serialize(svDetail, true);

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/getPayment/';

        RestRequest request = new RestRequest();
        request.requestUri = restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');
        //failed request
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST EST","TransactionRef":"ALCL:B34AF4A3","CompanyToken":"A025-4B8B-989B-A8921DD31094","TransactionAmount":6000}');
        RestContext.request = request;
        string response = WS06_DPOAPI.doGet();

        system.debug('response 2 '+response);
        System.assertEquals(true, response.contains(System.label.Country_Required), 'Subscription Should not be found');
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST TEST","CustomerCountry":"Togo","TransactionRef":"ALCL:B34AF4A3","CompanyToken":"A025-4B8B-989B-A8921DD31094","TransactionAmount":6000}');
        RestContext.request = request;
        response = WS06_DPOAPI.doGet();
        insert sv1;
        test.stopTest();

    }
    @isTest
    public static void UpgradeRenew_Test(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:DPOApiUrl', new DPOMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        Zuora__Subscription__c sub = [SELECT Zuora__Status__c, id, Zuora__Account__c
                                      FROM Zuora__Subscription__c LIMIT 1];

        sub.Zuora__Status__c = 'Active';
        update sub;

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];

        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subProduct;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/getPayment/';

        RestRequest request = new RestRequest();
        request.requestUri = restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST TEST","CustomerCountry":"Togo","TransactionRef":"ALCL:B34AF4A3","CompanyToken":"A025-4B8B-989B-A8921DD31094","TransactionAmount":60000}');
        RestContext.request = request;
        string response = WS06_DPOAPI.doGet();
        system.assertEquals(true, response.contains(System.label.Successful_Response), 'Renew request should be succeeded');
        test.stopTest();

    }
    @isTest
    public static void UpgradeRenewFailed_Test(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:DPOApiUrl', new DPOMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock(false, false, 400));
        Zuora__Subscription__c sub = [SELECT Zuora__Status__c, id, Zuora__Account__c
                                      FROM Zuora__Subscription__c LIMIT 1];

        sub.Zuora__Status__c = 'Active';
        update sub;

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];

        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subProduct;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/getPayment/';

        RestRequest request = new RestRequest();
        request.requestUri = restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');
        //failed request
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST EST","CustomerCountry":"Togo","TransactionRef":"ALCL:B34AF4A7","CompanyToken":"A025-4B8B-989B-A8921DD31094","TransactionAmount":6000}');
        RestContext.request = request;
        string response = WS06_DPOAPI.doGet();
        system.debug('response 3 '+response);
        System.assertEquals(true, response.contains(System.label.Subscription_Not_Found), 'Subscription Should not be found');
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST TEST","CustomerCountry":"Togo","TransactionRef":"ALCL:B34AF4A3","CompanyToken":"A025-4B8B-989B-A8921DD31094","TransactionAmount":6000}');
        RestContext.request = request;
        response = WS06_DPOAPI.doGet();
    }
    @isTest
    public static void SimpleRenewSucccessful_Test(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        // status code = 400 is used in this case to pay Premium product
        endpoint2TestResp.put('callout:DPOApiUrl', new DPOMock(false, false, 400));
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        Zuora__Subscription__c sub = [SELECT Zuora__Status__c, id, Zuora__Account__c
                                      FROM Zuora__Subscription__c LIMIT 1];

        sub.Zuora__Status__c = 'Active';
        update sub;

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];

        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subProduct;

        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/getPayment/';

        RestRequest request = new RestRequest();
        request.requestUri = restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST TEST","CustomerCountry":"Togo","TransactionRef":"ALCL:B34AF4A3","CompanyToken":"A025-4B8B-989B-A8921DD31094","TransactionAmount":60000}');
        RestContext.request = request;

        string response = WS06_DPOAPI.doGet();
        system.assertEquals(true, response.contains(System.label.Successful_Response), 'Renew request should be succeeded');

        test.stopTest();

    }

    @isTest
    public static void SimpleRenewFailed_Test(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        // status code = 400 in DPO is used in this case to pay Premium product
        endpoint2TestResp.put('callout:DPOApiUrl', new DPOMock(false, false, 400));

        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock(false, false, 300));
        Zuora__Subscription__c sub = [SELECT Zuora__Status__c, id, Zuora__Account__c
                                      FROM Zuora__Subscription__c LIMIT 1];

        sub.Zuora__Status__c = 'Active';
        update sub;

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];

        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subProduct;
        Suivi_de_Souscription__c sv = new Suivi_de_Souscription__c();
        DPObjects.SuiviDetails svDetail = new DPObjects.SuiviDetails();

        svDetail.IDSouscription = Sub.Id;
        svDetail.ModeDePaiement = 'Mobile_Money';
        svDetail.NumeroDeTransaction = '3ewd';
        svDetail.Periode = 2;
        svDetail.operateur = 'DPO';
        svDetail.typeOperation = 2;
        sv.SV_Id_Souscription__c = Sub.Id;
        // dest SF
        sv.SV_Destination__c = 'DST002';
        sv.SV_Code_Action__c = 'ACT004';
        sv.SV_Details__c = JSON.serialize(svDetail, true);
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/getPayment/';

        RestRequest request = new RestRequest();
        request.requestUri = restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');
        //failed request
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST EST","CustomerCountry":"Togo","TransactionRef":"ALCL:B34AF4A3","CompanyToken":"A025-4B8B-989B-A8921DD31094"}');
        RestContext.request = request;
        string response = WS06_DPOAPI.doGet();
        system.debug('response 1 '+response);
        System.assertEquals(true, response.contains(System.label.Amount_Required), 'Subscription Should not be found');
        request.requestBody = Blob.valueOf('{"CustomerName":"TEST TEST","CustomerCountry":"Togo","TransactionRef":"ALCL:B34AF4A3","CompanyToken":"A025-4B8B-989B-A8921DD31094","TransactionAmount":6000}');
        RestContext.request = request;
        response = WS06_DPOAPI.doGet();
        insert sv;
    }
}