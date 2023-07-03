@isTest
public with sharing class OffreAbonnementController_Test {

    @TestSetup
    static void makeData(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);

        System.runAs(togoAdminUser){
            Account acc = TestDataFactory.createPersonAccount('test', 'TG');
            acc.personMobilePhone = '06799944284';
            insert acc;
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription; // The user is created  when insert a subsctription

            Zuora__Product__c zpr = TestUtils.createZuoraProduct();
            insert zpr;

            zuoraSubscription.CompensationDaysAtNextRenewal__c = '15';
            zuoraSubscription.Zuora__Status__c = 'Active';
            zuoraSubscription.isCollaborator__c = 'Y';
            update zuoraSubscription;
        }
    }

    @isTest
    public static void shouldGetTheAvailableSubscriptionsPlanPremium(){
        Zuora__Subscription__c zuoraSubscription = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__status__c
                                                    FROM Zuora__Subscription__c LIMIT 1];

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(zuoraSubscription.Id, zuoraSubscription.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;

        Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(zuoraSubscription.Id, zuoraSubscription.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
        insert subProduct1;
        Zuora__SubscriptionProductCharge__c collabProduct = TestUtils.createSubscriptionProduct(zuoraSubscription.Id, zuoraSubscription.Zuora__Account__c, 'Collaborator', zpr.Id, 'Collaborator');
        insert collabProduct;
        collabProduct.Zuora__OriginalProductRatePlanChargeId__c = '40289f4664641276016464740dd0001c';
        update collabProduct;
        User currentUser = [SELECT Id, CountryCode
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1 ];
        currentUser.CountryCode = 'TG';
        update currentUser;
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        System.runAs(currentUser){
            Test.startTest();
            List<OffreAbonnementController.ProductRatePlanWrapperResponse> productRatePlanWrapperResponses
                = OffreAbonnementController.getAvailableProductRatePlans(zuoraSubscription.Id);
            Test.stopTest();
            System.debug('productRatePlanWrapperResponses : ' + productRatePlanWrapperResponses);
            System.assertNotEquals(null, productRatePlanWrapperResponses, 'ProductRatePlanWrapperResponses should not be null');
            //  System.assertEquals(5, productRatePlanWrapperResponses.size(), 'ProductRatePlanWrapperResponses should not be a list of 5');
        }
    }

    @isTest
    public static void shouldGetTheAvailableSubscriptionsPlanStart(){
        Zuora__Subscription__c zuoraSubscription = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__status__c
                                                    FROM Zuora__Subscription__c LIMIT 1];

        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(zuoraSubscription.Id, zuoraSubscription.Zuora__Account__c, 'Start', zpr.Id, 'Start');
        insert subProduct;

        Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(zuoraSubscription.Id, zuoraSubscription.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
        insert subProduct1;
        Zuora__SubscriptionProductCharge__c collabProduct = TestUtils.createSubscriptionProduct(zuoraSubscription.Id, zuoraSubscription.Zuora__Account__c, 'Collaborator', zpr.Id, 'Collaborator');
        insert collabProduct;
        collabProduct.Zuora__OriginalProductRatePlanChargeId__c = '40289f4664641276016464740dd0001c';
        update collabProduct;
        User currentUser = [SELECT Id, CountryCode
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1 ];
        currentUser.CountryCode = 'TG';
        update currentUser;

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());

        System.runAs(currentUser){
            Test.startTest();
            List<OffreAbonnementController.ProductRatePlanWrapperResponse> productRatePlanWrapperResponses
                = OffreAbonnementController.getAvailableProductRatePlans(zuoraSubscription.Id);
            Test.stopTest();
            System.debug('productRatePlanWrapperResponses : ' + productRatePlanWrapperResponses);
            System.assertNotEquals(null, productRatePlanWrapperResponses, 'ProductRatePlanWrapperResponses should not be null');
            //      System.assertEquals(5, productRatePlanWrapperResponses.size(), 'ProductRatePlanWrapperResponses should not be a list of 5');
        }
    }

    private static HttpCalloutMock getMultimockCallOut(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

        return multiCalloutMock;
    }

}