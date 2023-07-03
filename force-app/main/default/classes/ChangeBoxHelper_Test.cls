@isTest
public with sharing class ChangeBoxHelper_Test {

    @TestSetup
    static void makeData(){

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        String subId = TestUtils.createSub();
            }

    @isTest
    public static void ChangeBoxHelper_Test() {

        Zuora__Subscription__c newSub = [SELECT Id, Name, Quote__c, Quote__r.OpportunityId, Zuora__Status__c, Quote__r.Opportunity.priceBook2Id
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
                                         
        newSub.Zuora__Status__c = 'Active';
        update newSub;
        system.debug('newSub'+newSub);

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        Test.startTest();
        list<zqu__productRatePlan__c> listOfProduct =  ChangeBoxHelper.getProducts();
        list<String> reponses = ChangeBoxHelper.getSubscriptionInfo(newSub.Id,listOfProduct[0].zqu__ZuoraId__c);
        string techSubsResonse = ChangeBoxHelper.createTechnicalSubscription(newSub.Id,listOfProduct[0].zqu__ZuoraId__c,'Cash','','','',null,null,null,null,null);
        Test.stopTest();
    }
}