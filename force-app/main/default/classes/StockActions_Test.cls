/**
 * Classe test pour StockActions
 * Couverture:
 */
@isTest
public with sharing class StockActions_Test {
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
    public static void getBoxInStock_Test() {
        Quote currentQuote = [SELECT Id FROM Quote LIMIT 1];

        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        // get Boxes from Stock
        string response = StockActions.getBoxesInStock('NONONK-240-F');

        CanalBoxObjects.stockListingResponse boxesInStock = (CanalBoxObjects.stockListingResponse) System.JSON.deserialize(
            response, CanalBoxObjects.stockListingResponse.class);

        system.assertNotEquals(null, boxesInStock.articles, 'Should find Boxes in Stock');
    }
    @isTest
    public static void reserveBox_Test() {
        Quote currentQuote = [SELECT Id FROM Quote LIMIT 1];
        user currentUser = [SELECT CountryCode FROM User WHERE Id = :UserInfo.getUserId()];
        currentQuote.QUO_Pays__c = currentUser.CountryCode;
        update currentQuote;
        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        //select a box

        string selectedBox = '[{"serial":"ALCL:B34AF4A3"}]';
        string response = StockActions.reserveBox(selectedBox, currentQuote.Id, null, 'NONNOK1G-240W-A');

        CanalBoxObjects.stockReservingResponse boxReservation = (CanalBoxObjects.stockReservingResponse) System.JSON.deserialize(
            response, CanalBoxObjects.stockReservingResponse.class);

        System.assertEquals(true, boxReservation.reservation_expiry_date != null, 'Box should be reserved');
        Test.stopTest();
    }
    @isTest
    public static void getBoxFailedResponse_Test() {
        Quote currentQuote = [SELECT Id, QUO_Pays__c FROM Quote LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StockMock(false, false, 400));

        // get Boxes from Stock
        string response = StockActions.getBoxesInStock('NONONK-240-F');

        CanalBoxObjects.stockListingResponse boxesInStock = (CanalBoxObjects.stockListingResponse) System.JSON.deserialize(
            response, CanalBoxObjects.stockListingResponse.class);

        system.assertEquals(null, boxesInStock.articles, 'Any Box should be found in the Stock');

    }
    @isTest
    public static void liberateBox_Test(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StockMock());
        // liberate a reserved box
        string liberate = StockActions.liberateBox('[{"serial":"ALCL:B34AF4A3"}]', null, 'NONONK-240-F');

        //    System.assertEquals(true, string.isblank(liberate), 'Box should be liberated');
        Test.stopTest();
    }
    @isTest
    public static void liberateBoxFailedResponse_Test(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new StockMock(false, false, 400));
        // liberate a reserved box
        string liberate = StockActions.liberateBox('[{"serial":"ALCL:B34AF4A3"}]', null, 'NONONK-240-F');

        CanalBoxObjects.stockReservingResponse boxLiberation = (CanalBoxObjects.stockReservingResponse) System.JSON.deserialize(
            liberate, CanalBoxObjects.stockReservingResponse.class);
        System.assertEquals(false, boxLiberation.success, 'Box should not be liberated');
        Test.stopTest();
    }
    @isTest
    public static void changeBox_Test() {
        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

        Zuora__Subscription__c sub = [SELECT Id, boxNumber__c
                                      FROM Zuora__Subscription__c
                                      LIMIT 1];
        sub.boxNumber__c = '123321';
        update sub;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));

        //change box
        string response = StockActions.reserveBox('[{"serial":"ALCL:B34AF4A3"}]', null, sub.Id, 'NONONK-240-F');
        system.debug(response);
        CanalBoxObjects.stockReservingResponse boxReservation = (CanalBoxObjects.stockReservingResponse) System.JSON.deserialize(
            response, CanalBoxObjects.stockReservingResponse.class);

        System.assertEquals(true, boxReservation.reservation_expiry_date != null, 'Box should be reserved');

        list<Suivi_de_Souscription__c> suivi = [SELECT id, SV_Statut__c, SV_Reference_Externe__c
                                                FROM Suivi_de_Souscription__c
                                                WHERE SV_Code_Action__c = 'ACT006'];
        System.assertEquals(1, suivi.size(), 'A new record for \'echange de materiel \' should be created');

        Suivi_de_Souscription__c sv = new Suivi_de_Souscription__c();
        sv.Id = suivi[0].Id;
        sv.SV_Statut__c = 'STA002';
        sv.SV_Reference_Externe__c = '1122';
        update sv;

    }
}