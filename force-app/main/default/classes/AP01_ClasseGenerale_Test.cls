@isTest
public with sharing class AP01_ClasseGenerale_Test {
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
    @isTest
    public static void AP01_ClasseGenerale_Test(){

        Test.startTest();
        String profile = AP01_ClasseGenerale.userProfile();
        String code = AP01_ClasseGenerale.userCountryCode();
        Boolean isPartner = AP01_ClasseGenerale.isPartnerUser();
        Test.stopTest();
    }
    @isTest
    public static void handleSimplePreview_Test(){

        Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
        FROM Zuora__Subscription__c
        LIMIT 1];

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        Test.startTest();
        String previewResponse = AP01_ClasseGenerale.handleAllPreviews('Renew', newSub.Id, 1, true, 'cash', true, '10GVAAC|ACDD', new list<string>(), 'Access', null, null, null, null, null, null,null);
        Test.stopTest();
    }
    @isTest
    public static void handleDOWNPreview_Test(){

        Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
        FROM Zuora__Subscription__c
        LIMIT 1];

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        Test.startTest();
        String previewResponse = AP01_ClasseGenerale.handleAllPreviews('Downgrade', newSub.Id, 2, true,'cash', true, '10GVAAC|ACDD', new list<string>(), 'Access', null, null, null, null, null, null,null);
        Test.stopTest();
    }
    @isTest
    public static void handleUPGPreview_Test(){

        Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
        FROM Zuora__Subscription__c
        LIMIT 1];

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        Test.startTest();
        String previewResponse = AP01_ClasseGenerale.handleAllPreviews('Upgrade', newSub.Id, 3, true, 'cash', true, '10GVAAC|ACDD', new list<string>(), 'Access', null, null, null, null, null, null,null);
        Test.stopTest();
    }
}