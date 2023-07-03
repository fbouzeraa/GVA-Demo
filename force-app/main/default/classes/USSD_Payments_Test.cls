/**
 * Classe test pour USSD_Payments
 * Couverture: 92%
 */
@isTest
public with sharing class USSD_Payments_Test {

    @TestSetup
    static void makeData(){
        //add Zuora Mock and Eligibility Mock to MultiMock class
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        TestUtils.createSub();
        Zuora__Product__c zpr = TestUtils.createZuoraProduct();
        insert zpr;
    }

    @isTest
    static void retryARenewPayment(){

        Profile p = [SELECT Id FROM Profile WHERE Name = :System.label.Administrator_Profile];
        user togoAdminUser = TestUtils.createUser('example1@test.com', 'lastName1', 'Jackie.AbiNassif@gva.africa', system.label.Distributor_Id, p.Id);
        insert(togoAdminUser);
        System.runAs(togoAdminUser){

            Zuora__Subscription__c sub = [SELECT id, Zuora__Account__c, Zuora__Status__c, ExpectedRenewalDate__c FROM Zuora__Subscription__c LIMIT 1];
            Account zAccount = [SELECT BillingCountryCode FROM Account WHERE Id =: sub.Zuora__Account__c ];
            zAccount.BillingCountryCode = 'TG';
            update  zAccount;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;
            sub.Zuora__Status__c = 'Active';
            update sub;
            Agregator_Transaction__c reCreateTransaction = new Agregator_Transaction__c();
            reCreateTransaction.AT_Subscription__c = sub.Id;
            reCreateTransaction.AT_Prepaid_Period__c = 1;
            reCreateTransaction.AT_renew_Type__c = 'Renew';
            reCreateTransaction.AT_Transaction_Reference__c = '1234-5678';
            reCreateTransaction.AT_Operator__c = 'HexaKomb';
            reCreateTransaction.AT_Payment_Method__c = System.Label.ModePaiement_MobileMoney;
            reCreateTransaction.error_message__c = 'an error message';
            reCreateTransaction.AT_SourceOfRequest__c = System.Label.USSD_Value;
            reCreateTransaction.AT_Status__c  = System.Label.NotTreated_Value;
            reCreateTransaction.Current_Expected_Renewal_Date__c = Date.today();
            insert reCreateTransaction;

            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
            USSD_Payments.retryPayment(new list<string> {reCreateTransaction.Id});
            Test.stopTest();
            list<Agregator_Transaction__c> transactions = [SELECT AT_Status__c FROM Agregator_Transaction__c LIMIT 1];
            system.assertEquals(true, transactions[0].AT_Status__c == 'Treated', 'Transaction shoud be treated');
        }
    }

    @isTest
    static void retryAnUpgradePayment(){

        Profile p = [SELECT Id FROM Profile WHERE Name = :System.label.Administrator_Profile];
        user togoAdminUser = TestUtils.createUser('example1@test.com', 'lastName1', 'Jackie.AbiNassif@gva.africa', system.label.Distributor_Id, p.Id);
        insert(togoAdminUser);
        System.runAs(togoAdminUser){

            Zuora__Subscription__c sub = [SELECT id, Zuora__Account__c, Zuora__Status__c FROM Zuora__Subscription__c LIMIT 1];
            Account zAccount = [SELECT BillingCountryCode FROM Account WHERE Id =: sub.Zuora__Account__c ];
            zAccount.BillingCountryCode = 'TG';
            update  zAccount;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Start', zpr.Id, 'Start');
            insert subProduct;
            sub.Zuora__Status__c = 'Active';
            update sub;
            Agregator_Transaction__c reCreateTransaction = new Agregator_Transaction__c();
            reCreateTransaction.AT_Subscription__c = sub.Id;
            reCreateTransaction.AT_Prepaid_Period__c = 1;
            reCreateTransaction.AT_renew_Type__c = System.Label.LWC_Renew_With_Upgrade_Type;
            reCreateTransaction.AT_Transaction_Reference__c = '1234-5678';
            reCreateTransaction.AT_Operator__c = 'HexaKomb';
            reCreateTransaction.AT_Payment_Method__c = System.Label.ModePaiement_MobileMoney;
            reCreateTransaction.error_message__c = 'an error message';
            reCreateTransaction.AT_SourceOfRequest__c = System.Label.USSD_Value;
            reCreateTransaction.AT_Status__c  = System.Label.NotTreated_Value;
            reCreateTransaction.Current_Expected_Renewal_Date__c = Date.today();
            insert reCreateTransaction;

            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
            USSD_Payments.retryPayment(new list<string> {reCreateTransaction.Id});
            Test.stopTest();
            list<Agregator_Transaction__c> transactions = [SELECT AT_Status__c FROM Agregator_Transaction__c LIMIT 1];
            system.assertEquals(true, transactions[0].AT_Status__c == 'Treated', 'Transaction shoud be treated');
        }
    }

    @isTest
    static void retryAnDowngradePayment(){

        Profile p = [SELECT Id FROM Profile WHERE Name = :System.label.Administrator_Profile];
        user togoAdminUser = TestUtils.createUser('example1@test.com', 'lastName1', 'Jackie.AbiNassif@gva.africa', system.label.Distributor_Id, p.Id);
        insert(togoAdminUser);
        System.runAs(togoAdminUser){

            Zuora__Subscription__c sub = [SELECT id, Zuora__Account__c, Zuora__Status__c FROM Zuora__Subscription__c LIMIT 1];
            Account zAccount = [SELECT BillingCountryCode FROM Account WHERE Id =: sub.Zuora__Account__c ];
            zAccount.BillingCountryCode = 'TG';
            update  zAccount;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;
            sub.Zuora__Status__c = 'Active';
            update sub;
            Agregator_Transaction__c reCreateTransaction = new Agregator_Transaction__c();
            reCreateTransaction.AT_Subscription__c = sub.Id;
            reCreateTransaction.AT_Prepaid_Period__c = 1;
            reCreateTransaction.AT_renew_Type__c = System.Label.LWC_Renew_With_Downgrade_Type;
            reCreateTransaction.AT_Transaction_Reference__c = '1234-5678';
            reCreateTransaction.AT_Operator__c = 'HexaKomb';
            reCreateTransaction.AT_Payment_Method__c = System.Label.ModePaiement_MobileMoney;
            reCreateTransaction.error_message__c = 'an error message';
            reCreateTransaction.AT_SourceOfRequest__c = System.Label.USSD_Value;
            reCreateTransaction.AT_Status__c  = System.Label.NotTreated_Value;
            reCreateTransaction.Current_Expected_Renewal_Date__c = Date.today();
            insert reCreateTransaction;

            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
            USSD_Payments.retryPayment(new list<string> {reCreateTransaction.Id});
            Test.stopTest();
            list<Agregator_Transaction__c> transactions = [SELECT AT_Status__c FROM Agregator_Transaction__c LIMIT 1];
            system.assertEquals(true, transactions[0].AT_Status__c == 'Treated', 'Transaction shoud be treated');
        }
    }

    @isTest
    private static void test_Wrappers(){
        String post = USSDObjects.post;
    }
}