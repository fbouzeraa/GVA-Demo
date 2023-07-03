/**
 * Classe test pour DPOPayments
 * Couverture: 97%
 */
@isTest
public with sharing class DPOPayments_Test {
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
    static void createToken(){

        Profile p = [SELECT Id FROM Profile WHERE Name = :System.label.Administrator_Profile];
        user togoAdminUser = TestUtils.createUser('example1@test.com', 'lastName1', 'Jackie.AbiNassif@gva.africa', system.label.Distributor_Id, p.Id);
        insert(togoAdminUser);
        System.runAs(togoAdminUser){

            Zuora__Subscription__c sub = [SELECT id, Zuora__Account__c FROM Zuora__Subscription__c LIMIT 1];

            Account zAccount = [SELECT BillingCountryCode FROM Account WHERE Id =: sub.Zuora__Account__c ];
            zAccount.BillingCountryCode = 'TG';
            update  zAccount;
    
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new DPOMock());
            DPOPayments.createToken(sub.Id, 30000, '2', 'Start', 'Downgrade');
            Test.stopTest();
            list<Agregator_Transaction__c> transactions = [SELECT id FROM Agregator_Transaction__c];
            system.assertEquals(true, transactions.size() > 0, 'Transaction shoud be created');
        }
    }

    @isTest
    static void retryRenewPayment_Test(){

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
            Agregator_Transaction__c aggTransaction = new Agregator_Transaction__c();
            aggTransaction.AT_Subscription__c = sub.Id;
            aggTransaction.AT_Renew_Type__c = 'Renew';
            aggTransaction.AT_Status__c = 'Not_Treated';
            aggTransaction.AT_Company_Reference__c = '8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3';
            aggTransaction.AT_Prepaid_Period__c = 2;
            aggTransaction.AT_Transaction_Token__c = '8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3';
            aggTransaction.AT_SourceOfRequest__c = 'DPO';
            aggTransaction.AT_Payment_Method__c = System.Label.ModePaiement_MobileMoney;
            insert aggTransaction;

            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:DPOApiUrl', new DPOMock());
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
            DPOPayments.retryPayment(new list<string> {aggTransaction.Id});
            Test.stopTest();
            list<Agregator_Transaction__c> transactions = [SELECT AT_Status__c FROM Agregator_Transaction__c LIMIT 1];
            system.assertEquals(true, transactions[0].AT_Status__c == 'Treated', 'Transaction shoud be treated');
        }
    }
    @isTest
    static void retryUpgradePayment_Test(){
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
            system.debug('the sub ID '+sub.Id);
            Agregator_Transaction__c aggTransaction = new Agregator_Transaction__c();
            aggTransaction.AT_Subscription__c = sub.Id;
            aggTransaction.AT_Renew_Type__c = System.Label.LWC_Renew_With_Upgrade_Type;
            aggTransaction.AT_Status__c = 'Not_Treated';
            aggTransaction.AT_Company_Reference__c = '8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3';
            aggTransaction.AT_Prepaid_Period__c = 2;
            aggTransaction.AT_Transaction_Token__c = '8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3';
            aggTransaction.AT_SourceOfRequest__c = 'DPO';
            aggTransaction.AT_Payment_Method__c = System.Label.ModePaiement_MobileMoney;
            insert aggTransaction;

            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:DPOApiUrl', new DPOMock());
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
            DPOPayments.retryPayment(new list<string> {aggTransaction.Id});
            Test.stopTest();
            list<Agregator_Transaction__c> transactions = [SELECT AT_Status__c FROM Agregator_Transaction__c LIMIT 1];
            system.assertEquals(true, transactions[0].AT_Status__c == 'Treated', 'Transaction shoud be treated');
        }
    }
    @isTest
    static void retryDowngradePayment_Test(){
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
            Agregator_Transaction__c aggTransaction = new Agregator_Transaction__c();
            aggTransaction.AT_Subscription__c = sub.Id;
            aggTransaction.AT_Renew_Type__c = 'Downgrade';
            aggTransaction.AT_Status__c = 'Not_Treated';
            aggTransaction.AT_Company_Reference__c = '8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3';
            aggTransaction.AT_Prepaid_Period__c = 2;
            aggTransaction.AT_Transaction_Token__c = '8D3DA73D-9D7F-4E09-96D4-3D44E7A83EA3';
            aggTransaction.AT_SourceOfRequest__c = 'DPO';
            aggTransaction.AT_Payment_Method__c = System.Label.ModePaiement_MobileMoney;
            insert aggTransaction;

            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:DPOApiUrl', new DPOMock());
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
            DPOPayments.retryPayment(new list<string> {aggTransaction.Id});
            Test.stopTest();
            list<Agregator_Transaction__c> transactions = [SELECT AT_Status__c FROM Agregator_Transaction__c LIMIT 1];
            system.assertEquals(true, transactions[0].AT_Status__c == 'Treated', 'Transaction shoud be treated');
        }
    }
}