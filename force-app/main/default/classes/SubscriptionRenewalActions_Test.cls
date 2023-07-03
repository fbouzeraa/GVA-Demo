/**
 * Classe test pour SubscriptionRenewalActions
 * Couverture: 82%
 */
@isTest
public with sharing class SubscriptionRenewalActions_Test {
    @TestSetup
    static void makeData(){
        //add Zuora Mock and Eligibility Mock to MultiMock class
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        Profile p = [SELECT Id FROM Profile WHERE Name = :System.label.Administrator_Profile];
        user togoAdminUser = TestUtils.createUser('example1@test.com', 'lastName1', 'y.bourdoukan@gva.africa', system.label.Distributor_Id, p.Id);
        insert(togoAdminUser);

        System.runAs(togoAdminUser){
            TestUtils.createSub();
            Zuora__Product__c zpr = TestUtils.createZuoraProduct();
            insert zpr;
        }
    }

    @isTest
    public static void renewActiveSubscriptionSucceededResponseWithTax_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;
            Zuora__SubscriptionProductCharge__c collabProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Collaborator', zpr.Id, 'Collaborator');
            insert collabProduct;
            collabProduct.Zuora__OriginalProductRatePlanChargeId__c = '40289f4664641276016464740dd0001c';
            update collabProduct;
            User currentUser = [SELECT Id, CountryCode
                                FROM User
                                WHERE Id = :UserInfo.getUserId()
                                LIMIT 1 ];
            currentUser.CountryCode = 'CD';
            update currentUser;

            newSub.CompensationDaysAtNextRenewal__c = '15';
            newSub.Zuora__Status__c = 'Active';
            newSub.isCollaborator__c = 'Y';
            //newSub.Coupon__c = 0;
            update newSub;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());

            string paymentResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 1, 'Cash', '123321', null, 200, 0, 50, 0, null, null, null, null);
            ZuoraResponseObjects.ZuoraPayment deserializedPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
            deserializedPaymentResponse = (ZuoraResponseObjects.ZuoraPayment)JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);
            // System.assertEquals(true, deserializedPaymentResponse.success, 'Payment should not be created');
            SubscriptionRenewalActions.addPaymentNumberToSubscription(newSub.Id, deserializedPaymentResponse.number_toReplace);
            Zuora__Subscription__c updatedSub = [SELECT SUB_T_Payment_Number__c, Zuora__Status__c
                                                 FROM Zuora__Subscription__c
                                                 LIMIT 1];
            System.assertEquals(deserializedPaymentResponse.number_toReplace, updatedSub.SUB_T_Payment_Number__c, 'Payment Number should be added');
            list<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                         FROM Suivi_de_Souscription__c
                                                         WHERE SV_Id_Souscription__c = :newSub.Id AND SV_Code_Action__c = 'ACT003' ];
            //  System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');

            Test.stopTest();
        }
    }
    @isTest
    public static void renewActiveSubscriptionSucceededWithCoupon_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            zqu__ZProduct__c zProd = [SELECT Id, zqu__Product__c FROM zqu__ZProduct__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            zqu__productrateplan__c coupon = TestUtils.createProductRatePlan('Coupon',  zProd.Id, zProd.zqu__Product__c, '12344324', 'AddOn', 'Coupon');
            insert coupon;
            zqu__ProductRatePlanCharge__c couponCharge = TestUtils.createPRPCharge(coupon.Id, 'Coupon', '572525352752538585896983');
            insert couponCharge;

            zqu__productrateplan__c bundleProd = TestUtils.createProductRatePlan('CHR',  zProd.Id, zProd.zqu__Product__c, '123455324', 'AddOn', 'Bundle C');
            insert bundleProd;
            zqu__ProductRatePlanCharge__c bundleCharge = TestUtils.createPRPCharge(bundleProd.Id, 'CHR', '572525352752538585896923');
            insert bundleCharge;
            zqu__productrateplanchargetier__c bundleChargePrice = TestUtils.createPRPChargePrice(bundleCharge.Id);
            insert bundleChargePrice;
            string bundleCharges = [SELECT zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c FROM zqu__productrateplanchargetier__c WHERE Id =:bundleChargePrice.Id].zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c;
            Zuora__SubscriptionProductCharge__c bundleProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'CHR', zpr.Id, 'Bundle C');
            insert bundleProduct;
            bundleProduct.Zuora__OriginalProductRatePlanChargeId__c = bundleCharges;
            bundleProduct.Zuora__Type__c = 'Recurring';
            update bundleProduct;

            newSub.CompensationDaysAtNextRenewal__c = '0';
            newSub.Zuora__Status__c = 'Active';
            newSub.Coupon__c = 400;
            update newSub;
            Test.startTest();

            //add Zuora Mock and canal Mock Mock to MultiMock class
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
            endpoint2TestResp.put('callout:CGAWeb', new CBundeMock());
            HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

            Test.setMock(HttpCalloutMock.class, multiCalloutMock);

            string paymentResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 1, 'Cash', '123321', null, 200, 0, 50, 0, null, 'Test', new list<string> {'CHR'}, null);
            ZuoraResponseObjects.ZuoraPayment deserializedPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
            deserializedPaymentResponse = (ZuoraResponseObjects.ZuoraPayment)JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);
            //  System.assertEquals(true, deserializedPaymentResponse.success, 'Payment should not be created');
            SubscriptionRenewalActions.addPaymentNumberToSubscription(newSub.Id, deserializedPaymentResponse.number_toReplace);
            Zuora__Subscription__c updatedSub = [SELECT SUB_T_Payment_Number__c, Zuora__Status__c
                                                 FROM Zuora__Subscription__c
                                                 LIMIT 1];
            System.assertEquals(deserializedPaymentResponse.number_toReplace, updatedSub.SUB_T_Payment_Number__c, 'Payment Number should be added');
            list<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                         FROM Suivi_de_Souscription__c
                                                         WHERE SV_Id_Souscription__c = :newSub.Id AND SV_Code_Action__c = 'ACT003' ];
            //   System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');

            Test.stopTest();
        }
    }

    @isTest
    public static void renewActiveSubscriptionSucceededResponse_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            newSub.CompensationDaysAtNextRenewal__c = '15';
            newSub.Zuora__Status__c = 'Active';
            update newSub;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string paymentResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 2, 'Credit_Card', null, null, null, null, null, null, 'O-123432', null, null, null);
            ZuoraResponseObjects.ZuoraPayment deserializedPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
            deserializedPaymentResponse = (ZuoraResponseObjects.ZuoraPayment)JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);
            System.assertEquals(true, deserializedPaymentResponse.success, 'Payment should not be created');
            SubscriptionRenewalActions.addPaymentNumberToSubscription(newSub.Id, deserializedPaymentResponse.number_toReplace);
            Zuora__Subscription__c updatedSub = [SELECT SUB_T_Payment_Number__c, Zuora__Status__c
                                                 FROM Zuora__Subscription__c
                                                 LIMIT 1];
            System.assertEquals(deserializedPaymentResponse.number_toReplace, updatedSub.SUB_T_Payment_Number__c, 'Payment Number should be added');
            list<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                         FROM Suivi_de_Souscription__c
                                                         WHERE SV_Id_Souscription__c = :newSub.Id AND SV_Code_Action__c = 'ACT003' ];
            System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');

            Test.stopTest();
        }
    }
    @isTest
    public static void renewSubscriptionConversionRateSucceededResponse_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            newSub.Zuora__Status__c = 'Active';
            update newSub;

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string paymentResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 2, 'Credit_Card', null, null, 50, 1000, 5, 1000, null, null, null, null);
            ZuoraResponseObjects.ZuoraPayment deserializedPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
            deserializedPaymentResponse = (ZuoraResponseObjects.ZuoraPayment)JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);
            System.assertEquals(true, deserializedPaymentResponse.success, 'Payment should not be created');
            SubscriptionRenewalActions.addPaymentNumberToSubscription(newSub.Id, deserializedPaymentResponse.number_toReplace);
            Zuora__Subscription__c updatedSub = [SELECT SUB_T_Payment_Number__c, Zuora__Status__c
                                                 FROM Zuora__Subscription__c
                                                 LIMIT 1];
            System.assertEquals(deserializedPaymentResponse.number_toReplace, updatedSub.SUB_T_Payment_Number__c, 'Payment Number should be added');
            list<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                         FROM Suivi_de_Souscription__c
                                                         WHERE SV_Id_Souscription__c = :newSub.Id AND SV_Code_Action__c = 'ACT003' ];
            System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');

            Test.stopTest();
        }
    }

    @isTest
    public static void renewSubscriptionWithFailedPayment_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            newSub.Zuora__Status__c = 'Active';
            update newSub;

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock1(true, false, 400));
            string paymentResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 2, 'Credit_Card', null, null, 50, 1000, 5, 1000, null, null, null, null);
            ZuoraResponseObjects.ZuoraPayment deserializedPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
            deserializedPaymentResponse = (ZuoraResponseObjects.ZuoraPayment)JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);
            System.assertEquals(false, deserializedPaymentResponse.success, 'Payment should not be created');
            Test.stopTest();
        }
    }

    @isTest
    public static void retryFailedPayment_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c, Zuora__CustomerAccount__r.Zuora__Zuora_Id__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string paymentResponse = SubscriptionRenewalActions.retryPayment(newSub.Zuora__CustomerAccount__r.Zuora__Zuora_Id__c, 2, 200, null,
                                                                             null, null, '123432234', 'XOF', 'cash', null, null, null,
                                                                             null, null, false, newSub.Zuora__Account__c);
            SubscriptionRenewalActions.sleepAfterBCD();
            ZuoraResponseObjects.ZuoraPayment deserializedPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
            deserializedPaymentResponse = (ZuoraResponseObjects.ZuoraPayment)JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);
            System.assertEquals(true, deserializedPaymentResponse.success, 'Payment should not be created');
            Test.stopTest();
        }
    }
    @isTest
    public static void renewSuspendedSubscriptionSucceededResponseWithTax_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;

            newSub.Zuora__Status__c = 'Suspended';
            newSub.CompensationDaysAtNextRenewal__c = '15';
            update newSub;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string paymentResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 2, 'Cash', null, null, null, null, null, null, null, null, null, null);
            ZuoraResponseObjects.ZuoraPayment deserializedPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
            deserializedPaymentResponse = (ZuoraResponseObjects.ZuoraPayment)JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);
            //System.assertEquals(true, deserializedPaymentResponse.success, 'Payment should not be created');
            SubscriptionRenewalActions.addPaymentNumberToSubscription(newSub.Id, deserializedPaymentResponse.number_toReplace);
            Zuora__Subscription__c updatedSub = [SELECT SUB_T_Payment_Number__c, Zuora__Status__c
                                                 FROM Zuora__Subscription__c
                                                 LIMIT 1];
            System.assertEquals(deserializedPaymentResponse.number_toReplace, updatedSub.SUB_T_Payment_Number__c, 'Payment Number should be added');
            list<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                         FROM Suivi_de_Souscription__c
                                                         WHERE SV_Id_Souscription__c = :newSub.Id AND SV_Code_Action__c = 'ACT003' ];
            //  System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');
            Test.stopTest();
        }
    }
    @isTest
    public static void renewSuspendedSubscriptionSucceededResponse_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, CompensationDaysAtNextRenewal__c, ExpectedRenewalDate__c, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            newSub.Zuora__Status__c = 'Suspended';
            newSub.ExpectedRenewalDate__c = date.today();
            update newSub;

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string paymentResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 2, 'Mobile_Money', '9999999', null, null, null, null, null, null, null, null, null);
            ZuoraResponseObjects.ZuoraPayment deserializedPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
            deserializedPaymentResponse = (ZuoraResponseObjects.ZuoraPayment)JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);
            System.assertEquals(true, deserializedPaymentResponse.success, 'Payment should not be created');
            SubscriptionRenewalActions.addPaymentNumberToSubscription(newSub.Id, deserializedPaymentResponse.number_toReplace);
            Zuora__Subscription__c updatedSub = [SELECT SUB_T_Payment_Number__c, Zuora__Status__c
                                                 FROM Zuora__Subscription__c
                                                 LIMIT 1];
            System.assertEquals(deserializedPaymentResponse.number_toReplace, updatedSub.SUB_T_Payment_Number__c, 'Payment Number should be added');
            list<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                         FROM Suivi_de_Souscription__c
                                                         WHERE SV_Id_Souscription__c = :newSub.Id AND SV_Code_Action__c = 'ACT003' ];
            System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');
            Test.stopTest();
        }
    }
    @isTest
    public static void renewSubscriptionErrorResponse_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            newSub.Zuora__Status__c = 'Cancelled';
            update newSub;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string renewResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 2, 'Cash', null, null, null, null, null, null, null, null, null, null);
            System.assertEquals(system.label.Impossible_Action, renewResponse, 'Subscription should not be renewed');
            renewResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, null, 'Cash', null, null, null, null, null, null, null, null, null, null);
            System.assertEquals(system.label.Empty_Number_Of_Periodes, renewResponse, 'Number of renewed periods should not be null');
            Test.stopTest();
        }
    }
    @isTest
    public static void renewSubscriptionFailedResponse_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, CompensationDaysAtNextRenewal__c, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            newSub.Zuora__Status__c = 'Suspended';
            update newSub;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 300));
            string renewResponse = SubscriptionRenewalActions.renewSubscription(newSub.Id, 2, 'Cash', null, null, null, null, null, null, null, null, null, null);
            System.assertEquals(true, renewResponse.contains('"success" : false'), 'Subscription should not be renewed');
            Test.stopTest();
        }
    }

    @isTest
    public Static void UpgradeProductSucceededRequest_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__status__c
                                             FROM Zuora__Subscription__c LIMIT 1];
            newSub.Zuora__Status__c = 'Active';
            newSub.isCollaborator__c = 'Y';
            update newSub;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;
            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;
            Zuora__SubscriptionProductCharge__c collabProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Collaborator', zpr.Id, 'Collaborator');
            insert collabProduct;
            collabProduct.Zuora__OriginalProductRatePlanChargeId__c = '40289f4664641276016464740dd0001c';
            update collabProduct;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            //with tax
            string upgradeResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, false, false, true, 'Cash', null, null, 150, 1000, 20, 1000, null, null, null, null);
            Boolean result = upgradeResponse.contains('"success": true');
            System.assertEquals(true, result, 'Product should be upgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void UpgradeProductWithFailedOrder_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__status__c
                                             FROM Zuora__Subscription__c LIMIT 1];
            newSub.Zuora__Status__c = 'Active';
            newSub.isCollaborator__c = 'Y';
            update newSub;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;
            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;
            Zuora__SubscriptionProductCharge__c collabProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Collaborator', zpr.Id, 'Collaborator');
            insert collabProduct;
            collabProduct.Zuora__OriginalProductRatePlanChargeId__c = '40289f4664641276016464740dd0001c';
            update collabProduct;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock1(true, false, 400));
            //with tax
            string upgradeResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, false, false, true, 'Cash', null, null, 150, 1000, 20, 1000, null, null, null, null);
            Boolean result = upgradeResponse.contains('"success": false');
            System.assertEquals(true, result, 'Product should not be upgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void UpgradeProductSucceededRequestWithCoupon_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__status__c
                                             FROM Zuora__Subscription__c LIMIT 1];
            newSub.Zuora__Status__c = 'Active';
            newSub.Coupon__c = 400;
            update newSub;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            zqu__ZProduct__c zProd = [SELECT Id, zqu__Product__c FROM zqu__ZProduct__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;
            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;
            zqu__productrateplan__c coupon = TestUtils.createProductRatePlan('Coupon',  zProd.Id, zProd.zqu__Product__c, '12344324', 'AddOn', 'Coupon');
            insert coupon;
            zqu__ProductRatePlanCharge__c couponCharge = TestUtils.createPRPCharge(coupon.Id, 'Coupon', '572525352752538585896983');
            insert couponCharge;
            zqu__productrateplan__c bundleProd = TestUtils.createProductRatePlan('CHR',  zProd.Id, zProd.zqu__Product__c, '123455324', 'AddOn', 'Bundle C');
            insert bundleProd;
            zqu__ProductRatePlanCharge__c bundleCharge = TestUtils.createPRPCharge(bundleProd.Id, 'CHR', '572525352752538585896923');
            insert bundleCharge;
            zqu__productrateplanchargetier__c bundleChargePrice = TestUtils.createPRPChargePrice(bundleCharge.Id);
            insert bundleChargePrice;
            string bundleCharges = [SELECT zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c FROM zqu__productrateplanchargetier__c WHERE Id =:bundleChargePrice.Id].zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c;
            Zuora__SubscriptionProductCharge__c bundleProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'CHR', zpr.Id, 'Bundle C');
            insert bundleProduct;
            bundleProduct.Zuora__OriginalProductRatePlanChargeId__c = bundleCharges;
            bundleProduct.Zuora__Type__c = 'Recurring';
            update bundleProduct;

            Test.startTest();
            //add Zuora Mock and canal Mock Mock to MultiMock class
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
            endpoint2TestResp.put('callout:CGAWeb', new CBundeMock());
            HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            //with tax
            string upgradeResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, false, false, true, 'Cash', null, null, 150, 1000, 20, 1000, null, 'test', new list<string> {'CHR', 'SHR'}, null);
            Boolean result = upgradeResponse.contains('"success": true');
            System.assertEquals(true, result, 'Product should be upgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void UpgradeProductSucceededRequestWithoutTax_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__status__c
                                             FROM Zuora__Subscription__c LIMIT 1];

            newSub.Zuora__Status__c = 'Active';
            update newSub;

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            //with tax
            // string previewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, null, true, false, true, 'Credit_Card', null, null, null, null, null);
            string upgradeResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, null, false, false, true, 'Credit_Card', null, null, null, null, null, null, null, null, null, null);
            Boolean result = upgradeResponse.contains('"success": true');
            System.assertEquals(true, result, 'Product should be upgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void ImmediatUpgradeProductWithRenewSucceededRequestWithTax_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c
                                             FROM Zuora__Subscription__c LIMIT 1];
            newSub.Zuora__Status__c = 'Active';
            update newSub;
            Quote addProdQuote = new Quote(Name = 'add Product Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert addProdQuote;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;
            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            //string previewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, true, true, true, 'Cash', null, null, null, null, null);

            string upgradeResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, false, true, true, 'Cash', null, null, null, null, null, null, null, null, null, null);
            Boolean result = upgradeResponse.contains('"success": true');
            System.assertEquals(true, result, 'Product should be upgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void ImmediatUpgradeProductWithRenewSucceededRequest_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, ExpectedRenewalDate__c
                                             FROM Zuora__Subscription__c LIMIT 1];
            newSub.Zuora__Status__c = 'Active';
            newSub.ExpectedRenewalDate__c = date.today();
            update newSub;

            Quote addProdQuote = new Quote(Name = 'add Product Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert addProdQuote;

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            //string previewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, true, true, true, 'Credit_Card', '12221212', null, null, null, null);

            string upgradeResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, false, true, true, 'Mobile_Money', '12221212', null, null, null, null, null, 'O-123233', null, null, null);

            Boolean result = upgradeResponse.contains('"success": true');
            System.assertEquals(true, result, 'Product should be upgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void UpgradeProductWithRenewSuspendedRequestWithTax_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c,
                                             Zuora__Status__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                             CompensationDaysAtNextRenewal__c
                                             FROM Zuora__Subscription__c LIMIT 1];

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];

            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;

            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;

            newSub.Zuora__Status__c = 'Suspended';
            newSub.CompensationDaysAtNextRenewal__c = '3';
            update newSub;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            //string previewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, true, true, false, 'Cash', null, null, null, null, null);
            string upgradeResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, false, true, false, 'Cash', null, null, null, null, null, null, null, null, null, null);
            Boolean result = upgradeResponse.contains('"success": true');
            System.assertEquals(true, result, 'Product should be upgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void UpgradeProductWithRenewSuspendedRequest_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__Status__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c
                                             FROM Zuora__Subscription__c LIMIT 1];
            newSub.Zuora__Status__c = 'Suspended';
            update newSub;

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            //string previewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, true, true, false, 'Credit_Card', null, null, null, null, null);
            string upgradeResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 2, false, true, false, 'Credit_Card', null, null, null, null, null, null, null, null, null, null);
            Boolean result = upgradeResponse.contains('"success": true');
            System.assertEquals(true, result, 'Product should be upgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void upgradeProductToSubscriptionFailedRequest_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Status__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c LIMIT 1];
            newSub.Zuora__Status__c = 'Suspended';
            update newSub;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 400));
            string JSONResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(newSub.Id, 1, false, true, true, 'Cash', null, null, null, null, null, null, null, null, null, null);
            Boolean result = JSONResponse.contains('"success" : true');
            System.assertEquals(false, result, 'Product should not be added');
            Test.stopTest();
        }
    }
    @isTest
    public Static void downgradeProductWithRenewSucceededRequestWithCoupon_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__Status__c, CompensationDaysAtNextRenewal__c
                                             FROM Zuora__Subscription__c LIMIT 1];

            Quote addProdQuote = new Quote(Name = 'add Product Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert addProdQuote;

            Zuora__Product__c zprod = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            zqu__ZProduct__c zPr = [SELECT Id, zqu__Product__c FROM zqu__ZProduct__c LIMIT 1];

            product2 pr = new Product2 (Name = 'CanalBox - Togo');
            insert pr;

            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zprod.Id, 'Premium');
            insert subProduct;

            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zprod.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;
            zqu__productrateplan__c coupon = TestUtils.createProductRatePlan('Coupon',  zPr.Id, zPr.zqu__Product__c, '12344324', 'AddOn', 'Coupon');
            insert coupon;
            zqu__ProductRatePlanCharge__c couponCharge = TestUtils.createPRPCharge(coupon.Id, 'Coupon', '572525352752538585896983');
            insert couponCharge;

            zqu__productrateplan__c bundleProd = TestUtils.createProductRatePlan('CHR',  zPr.Id, zPr.zqu__Product__c, '123455324', 'AddOn', 'Bundle C');
            insert bundleProd;
            zqu__ProductRatePlanCharge__c bundleCharge = TestUtils.createPRPCharge(bundleProd.Id, 'CHR', '572525352752538585896923');
            insert bundleCharge;
            zqu__productrateplanchargetier__c bundleChargePrice = TestUtils.createPRPChargePrice(bundleCharge.Id);
            insert bundleChargePrice;
            string bundleCharges = [SELECT zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c FROM zqu__productrateplanchargetier__c WHERE Id =:bundleChargePrice.Id].zqu__ProductRatePlanCharge__r.zqu__ZuoraId__c;
            Zuora__SubscriptionProductCharge__c bundleProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'CHR', zprod.Id, 'Bundle C');
            insert bundleProduct;
            bundleProduct.Zuora__OriginalProductRatePlanChargeId__c = bundleCharges;
            bundleProduct.Zuora__Type__c = 'Recurring';
            update bundleProduct;
            newSub.Zuora__Status__c = 'Active';
            newSub.CompensationDaysAtNextRenewal__c = '0';
            newSub.Coupon__c = 200;
            update newSub;

            Test.startTest();
            //add Zuora Mock and canal Mock Mock to MultiMock class
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
            endpoint2TestResp.put('callout:CGAWeb', new CBundeMock());
            HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            string downgradeResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(newSub.Id, string.valueOf(addProdQuote.Id), 2, false, 'Cash', null, null, 120, 1000, 10, 1000, null, 'test', new list<string> {'CHR'}, null);
            Boolean result = downgradeResponse.contains('"success": true');
            // System.assertEquals(true, result, 'Product should be downgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void downgradeProductWithRenewSucceededRequestWithTax_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__Status__c, CompensationDaysAtNextRenewal__c
                                             FROM Zuora__Subscription__c LIMIT 1];

            Quote addProdQuote = new Quote(Name = 'add Product Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert addProdQuote;

            Zuora__Product__c zprod = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zqu__ZProduct__c zpr = new Zqu__ZProduct__c(Name = 'Test');
            insert zpr;

            product2 pr = new Product2 (Name = 'CanalBox - Togo');
            insert pr;

            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zprod.Id, 'Premium');
            insert subProduct;

            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zprod.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1; Zuora__SubscriptionProductCharge__c collabProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Collaborator', zprod.Id, 'Collaborator');
            insert collabProduct;
            collabProduct.Zuora__OriginalProductRatePlanChargeId__c = '40289f4664641276016464740dd0001c';
            update collabProduct;

            newSub.Zuora__Status__c = 'Active';
            newSub.CompensationDaysAtNextRenewal__c = '2';
            newSub.isCollaborator__c = 'Y';
            update newSub;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string downgradeResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(newSub.Id, string.valueOf(addProdQuote.Id), 2, false, 'Cash', null, null, 120, 1000, 10, 1000, null, null, null, null);
            Boolean result = downgradeResponse.contains('"success": true');
            System.assertEquals(true, result, 'Product should be downgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void downgradeProductPreviewtWithTax_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__Status__c, CompensationDaysAtNextRenewal__c
                                             FROM Zuora__Subscription__c LIMIT 1];

            Quote addProdQuote = new Quote(Name = 'add Product Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert addProdQuote;

            Zuora__Product__c zprod = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zqu__ZProduct__c zpr = new Zqu__ZProduct__c(Name = 'Test');
            insert zpr;

            product2 pr = new Product2 (Name = 'CanalBox - Togo');
            insert pr;

            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zprod.Id, 'Premium');
            insert subProduct;

            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zprod.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;

            newSub.Zuora__Status__c = 'Active';
            newSub.CompensationDaysAtNextRenewal__c = '2';
            update newSub;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string previewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(newSub.Id, string.valueOf(addProdQuote.Id), 2, true, 'Cash', null, null, null, null, null, null, null, null, null, null);
            ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                previewResponse, ZuoraResponseObjects.ZuoraPreviewResponse.class);
            System.assertEquals(true, preview.success, 'Preview should be successed');
            Test.stopTest();
        }
    }
    @isTest
    public Static void downgradeProductPreviewtWithoutTax_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__Status__c, CompensationDaysAtNextRenewal__c
                                             FROM Zuora__Subscription__c LIMIT 1];

            Quote addProdQuote = new Quote(Name = 'add Product Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert addProdQuote;

            Zuora__Product__c zprod = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zqu__ZProduct__c zpr = new Zqu__ZProduct__c(Name = 'Test');
            insert zpr;

            product2 pr = new Product2 (Name = 'CanalBox - Togo');
            insert pr;

            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zprod.Id, 'Premium');
            insert subProduct;

            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zprod.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;

            newSub.Zuora__Status__c = 'Active';
            newSub.CompensationDaysAtNextRenewal__c = '2';
            update newSub;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string previewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(newSub.Id, string.valueOf(addProdQuote.Id), 2, true, 'Credit_Card', null, null, null, null, null, null, null, null, null, null);
            ZuoraResponseObjects.ZuoraPreviewResponse preview = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                previewResponse, ZuoraResponseObjects.ZuoraPreviewResponse.class);
            System.assertEquals(true, preview.success, 'Preview should be successed');

            Test.stopTest();
        }
    }
    @isTest
    public Static void downgradeProductWithRenewSucceededRequest_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, ExpectedRenewalDate__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__Status__c, CompensationDaysAtNextRenewal__c
                                             FROM Zuora__Subscription__c LIMIT 1];

            Quote addProdQuote = new Quote(Name = 'add Product Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert addProdQuote;

            Zuora__Product__c zprod = [SELECT Id FROM Zuora__Product__c LIMIT 1];

            Zqu__ZProduct__c zpr = new Zqu__ZProduct__c(Name = 'Test');
            insert zpr;

            product2 pr = new Product2 (Name = 'CanalBox - Togo');
            insert pr;

            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zprod.Id, 'Premium');
            insert subProduct;

            newSub.Zuora__Status__c = 'Suspended';
            newSub.CompensationDaysAtNextRenewal__c = '2';
            newSub.ExpectedRenewalDate__c = date.today();
            update newSub;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string downgradeResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(newSub.Id, string.valueOf(addProdQuote.Id), 2, false, 'Mobile_Money', '1212121', null, null, null, null, null, 'O-123432', null, null, null);
            ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
            orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(
                downgradeResponse, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

            System.assertEquals(true, orderResponse.success, 'Product not should be downgraded');
            Test.stopTest();
        }
    }
    @isTest
    public Static void renewWithDowngradeFailedRequest_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__Status__c, CompensationDaysAtNextRenewal__c
                                             FROM Zuora__Subscription__c LIMIT 1];

            Quote addProdQuote = new Quote(Name = 'add Product Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert addProdQuote;

            Zuora__Product__c zprod = [SELECT Id FROM Zuora__Product__c LIMIT 1];

            Zqu__ZProduct__c zpr = new Zqu__ZProduct__c(Name = 'Test');
            insert zpr;

            product2 pr = new Product2 (Name = 'CanalBox - Togo');
            insert pr;

            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zprod.Id, 'Premium');
            insert subProduct;

            newSub.Zuora__Status__c = 'Suspended';
            newSub.CompensationDaysAtNextRenewal__c = '2';
            update newSub;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 400));

            string downgradeResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(newSub.Id, string.valueOf(addProdQuote.Id), 2, false, 'Mobile_Money', '1212121', null, null, null, null, null, 'O-0987', null, null, null);

            ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();
            orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse) JSON.deserialize(
                downgradeResponse, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

            System.assertEquals(false, orderResponse.success, 'Product not should be downgraded');
            Test.stopTest();
        }
    }

    @isTest
    public Static void downgradeProductWithRenewFailedRequest_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__Status__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c
                                             FROM Zuora__Subscription__c LIMIT 1];
            newSub.Zuora__Status__c = 'Suspended';
            update newSub;
            Quote addProdQuote = new Quote(Name = 'add Product Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert addProdQuote;
            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'start', zpr.Id, 'Start');
            insert subProduct;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string downgradeResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(newSub.Id, string.valueOf(addProdQuote.Id), 2, false, 'Cash', null, null, null, null, null, null, null, null, null, null);
            Boolean result = downgradeResponse.contains(System.label.Upgrade_Product_Failure);
            System.assertEquals(true, result, System.label.Upgrade_Product_Failure);
            Test.stopTest();
        }
    }
    @isTest
    public static void renewSubPreviewWithTax_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c sub = [SELECT Id, Zuora__Account__c
                                          FROM Zuora__Subscription__c
                                          LIMIT 1];

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
            insert subProduct1;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            SubscriptionRenewalActions.renewSubPreview(sub.Id, 2, true, 'Cash', true, null, null, null, null);
            Test.stopTest();
        }
    }
    @isTest
    public static void renewSubPreview_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c sub = [SELECT Id, Zuora__Account__c
                                          FROM Zuora__Subscription__c
                                          LIMIT 1];

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(sub.Id, sub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            // SubscriptionRenewalActions.renewSubPreview(sub.Id, 2, false, 'Credit_Card', true, null);
            SubscriptionRenewalActions.renewSubPreview(sub.Id, 2, false, 'Cash', true, null, null, null, null);
            Test.stopTest();
        }
    }

    @isTest
    public static void createErrorLog_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            string zLog = '{"zuoraLog":[{"LG_Interface__c":"Zuora","LG_Success__c":true,"LG_Error_Message__c":null,"LG_Method_Type__c":"POST"}],"message":"List index out of bounds: 0"}';
            SubscriptionRenewalActions.createErrorLog(zLog);
            list<Log__c> listLog = [SELECT ID FROM log__c];
            system.assertEquals(true, listLog.size() > 0, 'Log should be created');
        }
    }

    @isTest
    public static void isPartnerUser_Test(){
        Test.startTest();
        Boolean isPartnerUser = AP01_ClasseGenerale.isPartnerUser();
        Test.stopTest();
        System.assertEquals(false, isPartnerUser);
    }
    @isTest
    public static void calculateNewRenewalDate_Test(){
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 01, 15), 1, 15);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 01, 13), 1, 15);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 01, 18), 1, 15);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 01, 29), 1, 29);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 02, 28), 1, 29);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 01, 29), 1, 31);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 01, 29), 1, 31);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 01, 31), 2, 29);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 04, 30), 1, 29);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 05, 30), 1, 31);
        SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2022, 05, 30), 1, 29);
        date nextDate =  SubscriptionRenewalActions.calculateNewRenewalDate(Date.newInstance(2021, 02, 28), 1, 29);
        System.assertEquals(nextDate, Date.newInstance(2021, 03, 29));
    }

}