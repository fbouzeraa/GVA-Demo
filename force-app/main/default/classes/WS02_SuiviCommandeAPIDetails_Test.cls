@isTest
public with sharing class WS02_SuiviCommandeAPIDetails_Test {
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
    public static void testGet(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EligMock());
        Account currentAccount = [SELECT id, ACC_ChampCompteParent__c
                                  FROM Account
                                  WHERE RecordType.DeveloperName = 'ACC_ComptePersonnel'];

        Account acc  = TestUtils.createPersonAccount('Compte Parent');
        insert acc;

        // add parent account
        currentAccount.ACC_ChampCompteParent__c = acc.Id;
        update currentAccount;
        Test.stopTest();

        //get available suivi
        List<Suivi_de_Souscription__c> listSuivis = [SELECT Id, SV_details__c, SV_Code_Action__c, SV_Id_Souscription__r.Zuora__Account__c, SV_Id_Souscription__c,
                                                     SV_Id_Souscription__r.Zuora__SubscriptionNumber__c, SV_Id_Souscription__r.Quote__c
                                                     FROM Suivi_de_Souscription__c lIMIT 1];

        quote currentQuote = new quote(id = listSuivis[0].SV_Id_Souscription__r.Quote__c, QUO_T_Produit_De_Base__c = 'Start');
        update currentQuote;

        Zuora__Product__c zpr = TestUtils.createZuoraProduct();
        insert zpr;

        Zuora__SubscriptionProductCharge__c subPr = TestUtils.createSubscriptionProduct(listSuivis[0].SV_Id_Souscription__c,
                                                                                        listSuivis[0].SV_Id_Souscription__r.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subPr;

        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/suivis/details';

        RestRequest request = new RestRequest();
        request.requestUri = restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');

        request.requestBody = Blob.valueOf('{"id":["a123","' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        List<string> listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(2, listRequestedSuivis.size(), 'Expected Suivi record not found');

        // request for valid id but details field is empty
        listSuivis[0].SV_details__c = null;
        update listSuivis[0];
        request.requestBody = Blob.valueOf('{"id":["' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();

        System.assertEquals(1, listSuivis.size(), 'Response should includes onlu fixed values');
        System.assertEquals(true, listRequestedSuivis[0].contains('true'));

        // request for create action
        listSuivis[0].SV_Code_Action__c = 'ACT001';
        update listSuivis[0];
        request.requestBody = Blob.valueOf('{"id":["' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(true, listRequestedSuivis[0].contains('true'), 'Response should includes updated values');

        // request for suspend action
        listSuivis[0].SV_Code_Action__c = 'ACT002';
        update listSuivis[0];
        request.requestBody = Blob.valueOf('{"id":["' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(true, listRequestedSuivis[0].contains('true'), 'Response should includes updated values');

        // request for upgrade action
        listSuivis[0].SV_Code_Action__c = 'ACT004';
        update listSuivis[0];
        request.requestBody = Blob.valueOf('{"id":["' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(true, listRequestedSuivis[0].contains('true'), 'Response should includes updated values');

        // request for change box action
        listSuivis[0].SV_Code_Action__c = 'ACT005';
        listSuivis[0].SV_Reference_Externe__c = '122443';
        update listSuivis[0];
        request.requestBody = Blob.valueOf('{"id":["' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(true, listRequestedSuivis[0].contains('true'), 'Response should includes updated values');

    }

    @isTest
    public static void testGet2(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EligMock());
        Account currentAccount = [SELECT id, ACC_ChampCompteParent__c
                                  FROM Account
                                  WHERE RecordType.DeveloperName = 'ACC_ComptePersonnel'];

        Account acc  = TestUtils.createPersonAccount('Compte Parent');
        insert acc;

        // add parent account
        currentAccount.ACC_ChampCompteParent__c = acc.Id;
        update currentAccount;
        Test.stopTest();

        //get available suivi
        List<Suivi_de_Souscription__c> listSuivis = [SELECT Id, SV_details__c, SV_Code_Action__c, SV_Id_Souscription__r.Zuora__Account__c, SV_Id_Souscription__c,
                                                     SV_Id_Souscription__r.Zuora__SubscriptionNumber__c, SV_Id_Souscription__r.Quote__c
                                                     FROM Suivi_de_Souscription__c lIMIT 1];

        quote currentQuote = new quote(id = listSuivis[0].SV_Id_Souscription__r.Quote__c, QUO_T_Produit_De_Base__c = 'Start');
        update currentQuote;

        Zuora__Product__c zpr = TestUtils.createZuoraProduct();
        insert zpr;

        Zuora__SubscriptionProductCharge__c subPr = TestUtils.createSubscriptionProduct(listSuivis[0].SV_Id_Souscription__c,
                                                                                        listSuivis[0].SV_Id_Souscription__r.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subPr;

        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/suivis/details';

        RestRequest request = new RestRequest();
        request.requestUri = restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');

        // request for renew action
        listSuivis[0].SV_Code_Action__c = 'ACT003';
        update listSuivis[0];
        request.requestBody = Blob.valueOf('{"id":["' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        List<string> listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(true, listRequestedSuivis[0].contains('true'), 'Response should includes updated values');

        // request for complementary prod
        listSuivis[0].SV_Code_Action__c = 'ACT008';
        update listSuivis[0];
        request.requestBody = Blob.valueOf('{"id":["' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(true, listRequestedSuivis[0].contains('true'), 'Response should includes updated values');

        // request for resilier action
        listSuivis[0].SV_Code_Action__c = 'ACT009';
        update listSuivis[0];
        request.requestBody = Blob.valueOf('{"id":["' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(true, listRequestedSuivis[0].contains('true'), 'Response should includes updated values');

        // request for activation
        listSuivis[0].SV_Code_Action__c = 'ACT011';
        update listSuivis[0];
        request.requestBody = Blob.valueOf('{"id":["' + listSuivis[0].Id + '"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(true, listRequestedSuivis[0].contains('true'), 'Response should includes updated values');

        // request for invalid ids only
        request.requestBody = Blob.valueOf('{"id":["a123d432e","2121212eee"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(false, listRequestedSuivis[0].contains('true'), 'any record should be found');

        // request for valid id but different object
        request.requestBody = Blob.valueOf('{"id":["a0S1l000001gczjEAA"]}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(0, listRequestedSuivis.size(), 'any record should be found');

        // request = empty array
        request.requestBody = Blob.valueOf('{}');
        RestContext.request = request;
        listRequestedSuivis = WS02_SuiviCommandeAPIDetails.doGet();
        System.assertEquals(false, listRequestedSuivis[0].contains('true'), 'any record should be found');

    }
}