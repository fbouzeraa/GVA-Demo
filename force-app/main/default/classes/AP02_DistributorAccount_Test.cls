@isTest
public with sharing class AP02_DistributorAccount_Test {
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
    public static void createDistributorSubscription_Test(){
        id distributorProfileId = [SELECT Id FROM Profile WHERE Name = :System.label.Distributor_Profile].Id;

        id distAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(System.label.Distributor_RecordType).getRecordTypeId();

        Account dist = new Account ( name = 'Distributor', ACC_BuildingID__c = 'KIG_12343', ACC_LatLong__Latitude__s = 2, ACC_Eligible__c = false,
                                     ACC_LatLong__Longitude__s = 1.2, ACC_NumeroDEtage__c = 2, phone = '+01212121', ACC_PresencePTO_cc__c = 'non',
                                     ACC_MaturiteProspect__c = 'Chaud', ACC_CategorisationProspect__c = 'prix', BillingCountry = 'Togo', BillingCountryCode = 'TG',
                                     CurrencyIsoCode = 'XOF', recordtypeId = distAccountId);
        insert dist;
        contact con = TestUtils.createContact(dist.Id, 'conName');
        insert con;
        string JSONString = '[{"Id":"8adcd9eb76dba24601","Name":"Start","zqu__ZuoraId__c":"8adcd9eb76dba2460176dd6162cb5095","Type__c":"Base","ProductName":"CanalBox - Togo"}]';
        ZuoraResponseObjects.ZuoraCreateOrderResponse OrderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
        Test.startTest();
        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));

        List<zqu__ProductRatePlan__c> listDistributorPRP = AP02_DistributorAccount.getDistributorProductRatePlansList();
        system.assertEquals(0, listDistributorPRP.size(), 'Any Distributor product are created');
        string JSONResponse = AP02_DistributorAccount.createDistributorSubscription(dist.Id, JSONString);
        system.debug(JSONResponse);
        orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse)JSON.deserialize(JSONResponse, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
        System.assertEquals(true, orderResponse.success, 'Subscription should be created');
        User usr = [SELECT id, countryCode FROM User WHERE profileId =:distributorProfileId LIMIT 1];
        try {
            usr.countryCode = 'RW';
            update usr;
        }
        catch(exception e) {
            system.debug(e.getMessage());
        }
        Test.stopTest();

    }
    @isTest
    public static void transferCredit_Test(){
        id distAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePartenaire').getRecordTypeId();

        Account dist = new Account ( name = 'Distributor', ACC_BuildingID__c = 'KIG_12343', ACC_LatLong__Latitude__s = 2, ACC_Eligible__c = false,
                                     ACC_LatLong__Longitude__s = 1.2, ACC_NumeroDEtage__c = 2, phone = '+01212121', ACC_PresencePTO_cc__c = 'non',
                                     ACC_MaturiteProspect__c = 'Chaud', ACC_CategorisationProspect__c = 'prix', BillingCountry = 'Togo', BillingCountryCode = 'TG',
                                     CurrencyIsoCode = 'XOF', recordtypeId = distAccountId);
        insert dist;

        Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, Zuora__CustomerAccount__c
                                         FROM Zuora__Subscription__c LIMIT 1];

        Account sousDIst = new Account ( name = 'Sub-Distributor', ACC_BuildingID__c = 'KIG_12343', ACC_LatLong__Latitude__s = 2, ACC_Eligible__c = false,
                                         ACC_LatLong__Longitude__s = 1.2, ACC_NumeroDEtage__c = 2, phone = '+01212121', ACC_PresencePTO_cc__c = 'non',
                                         ACC_MaturiteProspect__c = 'Chaud', ACC_CategorisationProspect__c = 'prix', BillingCountry = 'Togo', BillingCountryCode = 'TG',
                                         CurrencyIsoCode = 'XOF', recordtypeId = distAccountId, parentId = dist.Id);
        insert sousDIst;

        Zuora__CustomerAccount__c zAcc = new Zuora__CustomerAccount__c(Id = newSub.Zuora__CustomerAccount__c, Zuora__Account__c = dist.Id, Zuora__Balance__c = 30);

        update zAcc;

        Zuora__CustomerAccount__c billingAccount = new Zuora__CustomerAccount__c(Name = 'Sub-Distributor', Zuora__Account__c = sousDIst.Id, Zuora__Zuora_Id__c = '1234554321',
                                                                                 Zuora__AccountNumber__c = 'A00000600',  Zuora__BillToWorkEmail__c = 'test@test.com', Zuora__Parent__c = zAcc.Id);
        insert billingAccount;

        Test.startTest();
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        list<Account> listSousDist = AP02_DistributorAccount.getListDistributors('Sub', dist.Id);
        list<Account> listDist = AP02_DistributorAccount.getListParentDistributors('Distributor', dist.Id);
        AP02_DistributorAccount.checkAvailableAmount(dist.Id, 100);
        System.assertEquals(1, listSousDist.size(), 'A distributor should be found');
        string transferStatus = AP02_DistributorAccount.handleCreditTransfer(dist.Id, sousDIst.Id, 100);
        ZuoraResponseObjects.ZuoraRefund refundInfo = (ZuoraResponseObjects.ZuoraRefund)System.JSON.deserialize(
            transferStatus, ZuoraResponseObjects.ZuoraRefund.class);
        System.assertEquals(true, refundInfo.success, 'Transfer should be succeed');
        Test.stopTest();

    }
}