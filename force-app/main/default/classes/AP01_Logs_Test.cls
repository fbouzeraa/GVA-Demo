/**
 * Classe test pour AP01_Logs
 * Couverture: 88%
 * @date 26 Janvier 2022
 */
@isTest
public with sharing class AP01_Logs_Test {

    @isTest
    public static void createFailedRequest_Test(){

        string body = '{"subscriptions" :[{"orderActions" :[{"type" : "CreateSubscription", "createSubscription" : {"terms" : {"initialTerm" : {"termType" : "EVERGREEN"}}, "subscribeToRatePlans" :[{"productRatePlanId" : "8adccb057e713659017e72b5d58948af"}, {"productRatePlanId" : "8adced107e71365d017e72fdd35646c7"}]}}], "customFields" : {"WarrantyEndDate_Reserved" : "2022-01-25", "Version_Reserved" : "1", "Type_Reserved" : "Standard", "SF_QuoteID_Reserved" : "0Q05r00000050TnCAI", "RenewalSequenceNumber_Reserved" : "0", "BoxNumber_Reserved" : "ALCL:B3BABC2C"}}], "orderNumber" : "DEV-250122-640", "orderDate" : "2022-01-25", "newAccount" : {"soldToContact" : {"workEmail" : "compte@rwanda.com", "personalEmail" : "compte@rwanda.com", "lastName" : "Rwanda", "firstName" : "Compte", "country" : "RW", "city" : "Rubavu"}, "name" : "Compte Rwanda", "customFields" : {"Type_Reserved" : "Prepaid", "Segment_Reserved" : "B2C", "Company_Reserved" : "GVA RWANDA"}, "currency_toReplace" : "RWF", "crmId" : "0015r00000OLxPzAAL", "billToContact" : {"workEmail" : "compte@rwanda.com", "personalEmail" : "compte@rwanda.com", "lastName" : "Rwanda", "firstName" : "Compte", "country" : "RW", "city" : "Rubavu"}, "billCycleDay" : 0, "autoPay" : false}, "customFields" : {"SourceOperator_Reserved" : "58692", "Source_Reserved" : "Shop", "OperatorAgent_Reserved" : "Yara Bourdoukan"}}';
        string response = '{"subscriptions" :[{"orderActions" :[{"type" : "CreateSubscription", "createSubscription" : {"terms" : {"initialTerm" : {"termType" : "EVERGREEN"}}, "subscribeToRatePlans" :[{"productRatePlanId" : "8adccb057e713659017e72b5d58948af"}, {"productRatePlanId" : "8adced107e71365d017e72fdd35646c7"}]}}], "customFields" : {"WarrantyEndDate_Reserved" : "2022-01-25", "Version_Reserved" : "1", "Type_Reserved" : "Standard", "SF_QuoteID_Reserved" : "0Q05r00000050TnCAI", "RenewalSequenceNumber_Reserved" : "0", "BoxNumber_Reserved" : "ALCL:B3BABC2C"}}], "orderNumber" : "DEV-250122-640", "orderDate" : "2022-01-25", "newAccount" : {"soldToContact" : {"workEmail" : "compte@rwanda.com", "personalEmail" : "compte@rwanda.com", "lastName" : "Rwanda", "firstName" : "Compte", "country" : "RW", "city" : "Rubavu"}, "name" : "Compte Rwanda", "customFields" : {"Type_Reserved" : "Prepaid", "Segment_Reserved" : "B2C", "Company_Reserved" : "GVA RWANDA"}, "currency_toReplace" : "RWF", "crmId" : "0015r00000OLxPzAAL", "billToContact" : {"workEmail" : "compte@rwanda.com", "personalEmail" : "compte@rwanda.com", "lastName" : "Rwanda", "firstName" : "Compte", "country" : "RW", "city" : "Rubavu"}, "billCycleDay" : 0, "autoPay" : false}, "customFields" : {"SourceOperator_Reserved" : "58692", "Source_Reserved" : "Shop", "OperatorAgent_Reserved" : "Yara Bourdoukan"}}';

        log__c lg = new log__c(LG_Body__c = body, LG_Response__c = response, LG_Method_URL__c = '/v1/orders/',
                               LG_Method_Type__c = 'POST', LG_Success__c = false, LG_Error_Solved__c = false);
        insert lg;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        AP01_Logs.retryLog(lg.Id);
        Test.stopTest();

    }
}