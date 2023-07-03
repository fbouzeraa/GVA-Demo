/**
 * Classe test pour AP01_ProductRatePlanHelper
 * Couverture:
 * @author Yara Bourdoukan
 * @date 1 Decembre 2020
 */
@isTest
public class AP01_ProductRatePlanHelper_Test {
    @TestSetup
    static void makeData(){
        //Get a successful response from mock
        //Test.setMock(HttpCalloutMock.class, new EligMock());
        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));

        // Create test subscription
        TestUtils.createSub();
    }
    id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
    @isTest
    public static void insertSMEQuoteLineItemsSuccess_Test(){
        id smeAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_CompteSME').getRecordTypeId();

        zqu__ProductRatePlan__c startPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'start' LIMIT 1];
        zqu__ProductRatePlan__c canalPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'canalBox' LIMIT 1];
        Product2 pr = [SELECT Id FROM Product2 LIMIT 1];
        zqu__ProductRatePlanCharge__c startPRPCharge = TestUtils.createPRPCharge(startPRP.Id, 'Start', '572525352752538585896983');
        insert startPRPCharge;
        zqu__productrateplanchargetier__c startChargePrice = TestUtils.createPRPChargePrice(startPRPCharge.Id);
        insert startChargePrice;

        Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c
                                         FROM Zuora__Subscription__c LIMIT 1];
        // Account Acc = new Account( id = newSub.Zuora__Account__c, RecordTypeId = smeAccountId);
        // update acc;
        list<QuoteLineItem> listQLI = [SELECT id FROM QuoteLineItem WHERE QuoteId = :newSub.Quote__c];
        delete listQLI;

        string JSONString = '[{"Id":"' + startPRP.Id + '","Name":"Start","zqu__Product__c":"' + pr.Id + '","zqu__ZuoraId__c":"8adcd9eb76dba2460176dd6162cb5095","Type__c":"Base","zqu__Product__r":{"Name":"CanalBox - Togo","Id":"01t5r0000002d8XAAQ"},"ProductName":"CanalBox - Togo"}]';
        string JSONProd = '[{"Id":"' + canalPRP.Id + '","Name":"Canalbox","zqu__Product__c":"' + pr.Id + '","zqu__ZuoraId__c":"8adcd9eb76dba2460176bb6162cb5095","Type__c":"AddOn","Category__c":"Equipment","zqu__Product__r":{"Name":"CanalBox - Togo","Id":"01t5r0000002d8XAAQ"},"ProductName":"CanalBox - Togo"}]';
        Test.startTest();
        List<zqu__ProductRatePlan__c> listAddOnPRP = AP01_ProductRatePlanHelper.getBaseProductRatePlansList(newSub.Quote__c);
        string verify = AP01_ProductRatePlanHelper.verifySelectedProducts(newSub.Quote__c, JSONString, true);
        System.assertEquals(null, verify, 'Should have only one base product');

        List<zqu__ProductRatePlan__c> listBasePRP = AP01_ProductRatePlanHelper.getAddOnProductRatePlansList(newSub.Quote__c);
        verify = AP01_ProductRatePlanHelper.verifySelectedProducts(newSub.Quote__c, JSONProd, false);
        System.assertEquals(null, verify, 'Should have a canalbox product');

        system.debug(AP01_ProductRatePlanHelper.insertQuoteLineItems(newSub.Quote__c, JSONString, 'Cash', '2', null, null, null, null, null, null, null, null, null));
        list<QuoteLineItem> listNewQLI = [SELECT id FROM QuoteLineItem];
        System.assertEquals(1, listNewQLI.size(), 'Product should be added to QLI');
        Test.stopTest();
    }

    @isTest
    public static void insertQuoteLineItemsSuccess_Test(){
        zqu__ProductRatePlan__c startPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'start' LIMIT 1];
        zqu__ProductRatePlan__c canalPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'canalBox' LIMIT 1];
        Product2 pr = [SELECT Id FROM Product2 LIMIT 1];
        zqu__ProductRatePlanCharge__c startPRPCharge = TestUtils.createPRPCharge(startPRP.Id, 'Start', '572525352752538585896983');
        insert startPRPCharge;
        zqu__productrateplanchargetier__c startChargePrice = TestUtils.createPRPChargePrice(startPRPCharge.Id);
        insert startChargePrice;
        Equipment__c eq = new Equipment__c();
        eq.Equipment_Id__c = 'aaa111';
        eq.Equipment_Type__c = 'eqip 1';
        eq.Country_Code__c = 'BF';
        insert eq;
        string equip = ' [{"Equipment_Id__c" : "21100009173037", "Equipment_Type__c" : "G11A", "EQ_Decodeur__c" : true, "EQ_Have_Decoder__c" : false, "Id" : "' + eq.Id + '", "Equipment" : "21100009173037", "Type" : "G11A"}]';

        Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId
                                         FROM Zuora__Subscription__c LIMIT 1];

        list<QuoteLineItem> listQLI = [SELECT id FROM QuoteLineItem WHERE QuoteId = :newSub.Quote__c];
        delete listQLI;

        string JSONString = '[{"Id":"' + startPRP.Id + '","Name":"Start","zqu__Product__c":"' + pr.Id + '","zqu__ZuoraId__c":"8adcd9eb76dba2460176dd6162cb5095","Type__c":"Base","zqu__Product__r":{"Name":"CanalBox - Togo","Id":"01t5r0000002d8XAAQ"},"ProductName":"CanalBox - Togo"}]';
        string JSONProd = '[{"Id":"' + canalPRP.Id + '","Name":"Canalbox","zqu__Product__c":"' + pr.Id + '","zqu__ZuoraId__c":"8adcd9eb76dba2460176bb6162cb5095","Type__c":"AddOn","Category__c":"Equipment","zqu__Product__r":{"Name":"CanalBox - Togo","Id":"01t5r0000002d8XAAQ"},"ProductName":"CanalBox - Togo"}]';
        Test.startTest();
        string verify = AP01_ProductRatePlanHelper.verifySelectedProducts(newSub.Quote__c, JSONString, true);
        System.assertEquals(null, verify, 'Should have only one base product');

        verify = AP01_ProductRatePlanHelper.verifySelectedProducts(newSub.Quote__c, JSONProd, false);
        System.assertEquals(null, verify, 'Should have a canalbox product');

        system.debug(AP01_ProductRatePlanHelper.insertQuoteLineItems(newSub.Quote__c, JSONString, 'Cash', '2', null, null, null, null, null, 'offerName', new list<string> {'ASD', 'AEA'}, equip, 'Access'));
        list<QuoteLineItem> listNewQLI = [SELECT id FROM QuoteLineItem];
        System.assertEquals(1, listNewQLI.size(), 'Product should be added to QLI');
        Test.stopTest();
    }
    @isTest
    public static void insertQuoteLineItemsFailed_Test(){
        Opportunity opp = [SELECT Id, Name, PriceBook2Id FROM Opportunity LIMIT 1];
        opp.PriceBook2Id = null;
        Update opp;
        zqu__ProductRatePlan__c startPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'start' LIMIT 1];
        zqu__ProductRatePlan__c premiumPRP = [SELECT Id, Type__c FROM zqu__ProductRatePlan__c WHERE Name = 'Premium' LIMIT 1];
        Product2 pr = [SELECT Id FROM Product2 LIMIT 1];
        zqu__ProductRatePlanCharge__c prpCharge = TestUtils.createPRPCharge(premiumPRP.Id, 'Premium', '572525352752538585896983');
        insert prpCharge;
        zqu__productrateplanchargetier__c chargePrice = TestUtils.createPRPChargePrice(prpCharge.Id);
        insert chargePrice;

        Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId
                                         FROM Zuora__Subscription__c LIMIT 1];

        string JSONString = '[{"Id":"' + startPRP.Id + '","Name":"Start","zqu__Product__c":"' + pr.Id + '","zqu__ZuoraId__c":"8adcd9eb76dba2460176dd6162cb5095","Type__c":"Base","zqu__Product__r":{"Name":"CanalBox - Togo","Id":"01t5r0000002d8XAAQ"},"ProductName":"CanalBox - Togo"},' +
        '{"Id":"' + premiumPRP.Id + '","Name":"Premium","zqu__Product__c":"' + pr.Id + '","zqu__ZuoraId__c":"8adcd9eb76dba2460176dd6162cb5095","Type__c":"Base","zqu__Product__r":{"Name":"CanalBox - Togo","Id":"01t5r0000002d8XAAQ"},"ProductName":"CanalBox - Togo"}]';
        Test.startTest();
        string verify = AP01_ProductRatePlanHelper.verifySelectedProducts(newSub.Quote__c, JSONString, true);
        System.assertEquals(system.label.Base_Product_Selection, verify, 'Should have only one base product');

        verify = AP01_ProductRatePlanHelper.verifySelectedProducts(newSub.Quote__c, JSONString, false);
        System.assertEquals(system.label.AddOn_Product_Selection, verify, 'Should have a canalbox product');

        AP01_ProductRatePlanHelper.insertQuoteLineItems(newSub.Quote__c, JSONString, 'Cash', '2',  null, null, null, null, null, null, null, null, null);
        list<QuoteLineItem> listQLI = [SELECT id FROM QuoteLineItem];
        System.assertEquals(1, listQLI.size(), 'Quote Should Have PriceBook to add product to the QuoteLineItem');
        Test.stopTest();
    }
    @isTest
    public static void insertQuoteLineItemsFailed2_Test(){
        Opportunity opp = [SELECT Id, Name, PriceBook2Id FROM Opportunity LIMIT 1];
        list<QuoteLineItem> QLI = [SELECT Id FROM QuoteLineItem];
        delete QLI;
        list<OpportunityLineItem> OLI = [SELECT Id FROM OpportunityLineItem];
        delete OLI;
        Product2 pr = [SELECT Id FROM Product2 LIMIT 1];
        delete pr;
        Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId
                                         FROM Zuora__Subscription__c LIMIT 1];

        string JSONString = '[{"Id":"' + null + '","Name":"Canalbox standalone","zqu__Product__c":"' + pr.Id + '","zqu__ZuoraId__c":"8adcd9eb759733000175bcd6e5c23257","zqu__Product__r":{"Name":"CanalBox - Togo (use this one)","Id":"01t1l000004JkplAAC"},"ProductName":"CanalBox - Togo (use this one)"}]';
        Test.startTest();
        map<string, list<string>> mapFieldPLV = AP01_ProductRatePlanHelper.getDependentPicklistValues(new list<string> {'QUO_Mode_De_Paiement__c'});
        AP01_ProductRatePlanHelper.insertQuoteLineItems(newSub.Quote__c, JSONString, 'Cash', '2',  null, null, null, null, null, null, null, null, null);
        list<QuoteLineItem> listQLI = [SELECT id FROM QuoteLineItem];
        System.assertEquals(0, listQLI.size(), 'list PriceBookEntry should have products');
        Test.stopTest();
    }
    @isTest
    public static void getProductRatePlansList_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId
                                         FROM Zuora__Subscription__c LIMIT 1];

        /**
         * we have 4 PRP : start, Premium, Timbre fiscal,canalBox,canalBox1
         * we have 3 categories : offer, other,equipment
         * sub have only 1 prod ==>  Premium
         **/

        Test.startTest();
        System.assertEquals(1, AP01_ProductRatePlanHelper.getQuoteLineItemProductRatePlansList(newSub.Quote__c).size(), 'Incorrect number of rate plans');
        System.assertEquals(1, AP01_ProductRatePlanHelper.getQuoteProductRatePlansList(newSub.Quote__c).size(), 'Incorrect number of rate plans');
        System.assertEquals(1, AP01_ProductRatePlanHelper.getBaseProductRatePlansList(newSub.Quote__c).size(), 'Duplicate Base PRP are found');
        System.assertEquals(3, AP01_ProductRatePlanHelper.getAddOnProductRatePlansList(newsub.Quote__c).size(), 'Duplicate AddOn PRP are found');
        System.assertEquals(3, AP01_ProductRatePlanHelper.getCategoryValues(newsub.Quote__c).size(), 'Duplicate categories are found');
        Test.stopTest();
    }

}