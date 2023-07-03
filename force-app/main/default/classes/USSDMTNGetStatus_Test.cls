/**
 * Classe permettant de tester les fonctionnalités de web service du call back de l'appel request to pay MTN COngo.
 * code coverage : 84 %
 * @author Jackie Abi Nassif
 * @date 23 / 05 / 2023
 */
@isTest
public with sharing class USSDMTNGetStatus_Test {
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

        requestToPayDemand__c demand = new requestToPayDemand__c();
        demand.externalId__c = sub.BoxNumber__c;
        demand.Request_Stage__c = 'Successful_RequestToPay';
        demand.financialTransactionId__c = '23503452';
        demand.Amount__c = 100;
        demand.Subscription__c = sub.Id;
        demand.Currency__c =  'XOF';
        demand.baseProductToAdd__c = 'Start';
        demand.prepaidPeriod__c = 1;
        demand.Source_operator__c = 'MTN';
        insert demand;

        Map<String, HttpCalloutMock> endpoint3TestResp = new Map<String, HttpCalloutMock>();
        endpoint3TestResp.put('callout:MTNAPIURL', new MTNMock());
        endpoint3TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint3TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint3TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint3TestResp.put('callout:All_My_Sms', new SMSMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint3TestResp));

        Test.startTest();
        USSDMTNGetStatus.getStatus(new list<Id>{demand.Id});
        Test.stopTest();
    }
    // test WS with downgrade/upgrade
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

        requestToPayDemand__c demand = new requestToPayDemand__c();
        demand.externalId__c = sub.BoxNumber__c;
        demand.Request_Stage__c = 'Failed_renewal';
        demand.financialTransactionId__c = '23503452';
        demand.Amount__c = 100;
        demand.Subscription__c = sub.Id;
        demand.Currency__c =  'XOF';
        demand.baseProductToAdd__c = 'Premium';
        demand.prepaidPeriod__c = 1;
        demand.Source_operator__c = 'MTN';
        demand.Current_Expected_Renewal_Date__c = sub.ExpectedRenewalDate__c;
        insert demand;

        Map<String, HttpCalloutMock> endpoint3TestResp = new Map<String, HttpCalloutMock>();
        endpoint3TestResp.put('callout:MTNAPIURL', new MTNMock());
        endpoint3TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint3TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint3TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint3TestResp.put('callout:All_My_Sms', new SMSMock());

        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint3TestResp));
        Test.startTest();

        USSDMTNGetStatus.getStatus(new list<Id>{demand.Id});
        Test.stopTest();
    }

    @isTest
    public static void doPOST3_Test(){
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

        requestToPayDemand__c demand = new requestToPayDemand__c();
        demand.externalId__c = sub.BoxNumber__c;
        demand.Request_Stage__c = 'Successful_RequestToPay';
        demand.financialTransactionId__c = '23503452';
        demand.Amount__c = 200;
        demand.Subscription__c = sub.Id;
        demand.Currency__c =  'XOF';
        demand.baseProductToAdd__c = 'Start';
        demand.prepaidPeriod__c = 1;
        demand.Source_operator__c = 'MTN';
        insert demand;

        Map<String, HttpCalloutMock> endpoint3TestResp = new Map<String, HttpCalloutMock>();
        endpoint3TestResp.put('callout:MTNAPIURL', new MTNMock());
        endpoint3TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint3TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint3TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint3TestResp.put('callout:All_My_Sms', new SMSMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint3TestResp));

        Test.startTest();
        USSDMTNGetStatus.getStatus(new list<Id>{demand.Id});
        Test.stopTest();
    }
}