@isTest
public with sharing class BizaoRest_Test {

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

            RenewSubscriptionData__c renewSubscriptionData = new RenewSubscriptionData__c();
            renewSubscriptionData.RSD_Amount__c = 30000;
            renewSubscriptionData.RSD_SubscriptionId__c = zuoraSubscription.Id;
            renewSubscriptionData.RSD_NumberOfPeriods__c = 1;
            renewSubscriptionData.RSD_Payment_Method__c = 'Mobile_Money';
            renewSubscriptionData.RSD_TransactionNumber__c = null;
            renewSubscriptionData.RSD_Operator__c = 'Moov';
            renewSubscriptionData.RSD_DollarPayment__c = null;
            renewSubscriptionData.RSD_CDFPayment__c = null;
            renewSubscriptionData.RSD_DollarRefund__c = null;
            renewSubscriptionData.RSD_CDFRefund__c = null;
            renewSubscriptionData.RSD_OrderId__c = 'Order-Id-0123456789';
            renewSubscriptionData.RSD_SelectedRenewOffer__c = 'REABO';
            renewSubscriptionData.RSD_IsOrderOpen__c = true;
            System.debug('renewSubscriptionData : ' + renewSubscriptionData);
            insert renewSubscriptionData;

        }
    }

    @isTest
    public static void renewActiveSubscriptionSucceededResponseWithTax_Test(){

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
        currentUser.CountryCode = 'CD';
        update currentUser;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String bizaoBodyRequest =  '{' +
        '"meta": {' +
        '   "type": "payment",' +
        '    "source": "orange",' +
        '    "channel": "tpe"' +
        '},' +
        '"status": "Successful",' +
        '"amount": "30000",' +
        '"order-id": "Order-Id-0123456789",' +
        '"currency": "XOF",' +
        '"reference": "Your-reference",' +
        '"date": "2020-09-29 09:34:32.0",' +
        '"state": "param1%3Dvalue1%26param2%3Dvalue2",' +
        '"country-code": "sn",' +
        '"intTransaction-id": "1601372072771",' +
        '"extTransaction-id ": "MP200929.0935.A64320"' +
        '}';

        req.requestURI = '/services/apexrest/bizaorest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bizaoBodyRequest); //Blob.valueOf(JSON.serializePretty(bodyRequest));

        RestContext.request = req;
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        Test.startTest();
        String bizaoRestResponse = BizaoRest.doPost();
        Test.stopTest();
        System.assertEquals('Subcription renew successful',  bizaoRestResponse, 'The response should be sucess');

        Zuora__Subscription__c zuoraSubscriptionUpdated = [SELECT Id, NbrJoursRestants__c, SUB_T_Payment_Number__c FROM Zuora__Subscription__c WHERE Zuora__SubscriptionNumber__c = 'A-S00000400' LIMIT 1];
        List<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                     FROM Suivi_de_Souscription__c
                                                     WHERE SV_Id_Souscription__c = :zuoraSubscriptionUpdated.Id
                                                     AND SV_Code_Action__c = 'ACT003'];
        System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');
        RenewSubscriptionData__c renewSubscriptionData = [SELECT Id, RSD_IsOrderOpen__c, RSD_LogBizaoRestApi__c
                                                          FROM RenewSubscriptionData__c
                                                          WHERE RSD_OrderId__c = 'Order-Id-0123456789'
                                                          LIMIT 1];
        System.assertEquals(false, renewSubscriptionData.RSD_IsOrderOpen__c, 'The order should be close');
        System.assert(renewSubscriptionData.RSD_LogBizaoRestApi__c.contains('Bizao notification status : Successful'), 'The RSD_LogBizaoRestApi__c should contains :  Bizao notification status : Successful');
    }

    @isTest
    public static void renewActiveSubscriptionFailedResponseIfBizaoResponseStatusIsNotSuccesfulWithTax_Test(){

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
        currentUser.CountryCode = 'CD';
        update currentUser;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String bizaoBodyRequest =  '{' +
        '"meta": {' +
        '   "type": "payment",' +
        '    "source": "orange",' +
        '    "channel": "tpe"' +
        '},' +
        '"status": "Pending",' +
        '"amount": "30000",' +
        '"order-id": "Order-Id-0123456789",' +
        '"currency": "XOF",' +
        '"reference": "Your-reference",' +
        '"date": "2020-09-29 09:34:32.0",' +
        '"state": "param1%3Dvalue1%26param2%3Dvalue2",' +
        '"country-code": "sn",' +
        '"intTransaction-id": "1601372072771",' +
        '"extTransaction-id ": "MP200929.0935.A64320"' +
        '}';

        req.requestURI = '/services/apexrest/bizaorest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bizaoBodyRequest); //Blob.valueOf(JSON.serializePretty(bodyRequest));

        RestContext.request = req;
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        Test.startTest();
        String bizaoRestResponse = BizaoRest.doPost();
        Test.stopTest();
        System.assertEquals('Unvalid status from Bizao',  bizaoRestResponse, 'Status in not success nor failed');

        Zuora__Subscription__c zuoraSubscriptionUpdated = [SELECT Id, NbrJoursRestants__c, SUB_T_Payment_Number__c FROM Zuora__Subscription__c WHERE Zuora__SubscriptionNumber__c = 'A-S00000400' LIMIT 1];
        List<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                     FROM Suivi_de_Souscription__c
                                                     WHERE SV_Id_Souscription__c = :zuoraSubscriptionUpdated.Id
                                                     AND SV_Code_Action__c = 'ACT003'];
        System.assertEquals(0, renewSuivi.size(), 'A suivi record should not be created');
    }

    @isTest
    public static void upgradeProductSucceededRequest_test(){
        RenewSubscriptionData__c renewSubscriptionData =  [SELECT Id FROM RenewSubscriptionData__c LIMIT 1];
        renewSubscriptionData.RSD_SelectedRenewOffer__c = 'REABO_UPG';
        update renewSubscriptionData;

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

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String bizaoBodyRequest =  '{' +
        '"meta": {' +
        '   "type": "payment",' +
        '    "source": "orange",' +
        '    "channel": "tpe"' +
        '},' +
        '"status": "Successful",' +
        '"amount": "30000",' +
        '"order-id": "Order-Id-0123456789",' +
        '"currency": "XOF",' +
        '"reference": "Your-reference",' +
        '"date": "2020-09-29 09:34:32.0",' +
        '"state": "param1%3Dvalue1%26param2%3Dvalue2",' +
        '"country-code": "sn",' +
        '"intTransaction-id": "1601372072771",' +
        '"extTransaction-id ": "MP200929.0935.A64320"' +
        '}';

        req.requestURI = '/services/apexrest/bizaorest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bizaoBodyRequest); //Blob.valueOf(JSON.serializePretty(bodyRequest));

        RestContext.request = req;
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        Test.startTest();
        String bizaoRestResponse = BizaoRest.doPost();
        Test.stopTest();
        System.assertEquals('Subcription renew successful',  bizaoRestResponse, 'The response should be sucess');

        Zuora__Subscription__c zuoraSubscription = [SELECT Id, NbrJoursRestants__c, SUB_T_Payment_Number__c FROM Zuora__Subscription__c WHERE Zuora__SubscriptionNumber__c = 'A-S00000400' LIMIT 1];
        List<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                     FROM Suivi_de_Souscription__c
                                                     WHERE SV_Id_Souscription__c = :zuoraSubscription.Id
                                                     AND SV_Code_Action__c = 'ACT003'];
        System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');
        renewSubscriptionData = [SELECT Id, RSD_IsOrderOpen__c, RSD_LogBizaoRestApi__c
                                 FROM RenewSubscriptionData__c
                                 WHERE RSD_OrderId__c = 'Order-Id-0123456789'
                                 LIMIT 1];
        System.assertEquals(false, renewSubscriptionData.RSD_IsOrderOpen__c, 'The order should be close');
        System.assert(renewSubscriptionData.RSD_LogBizaoRestApi__c.contains('successful'), 'The RSD_LogBizaoRestApi__c should contains :  Renew Subcription With Upgrade Status : Successful');

    }

    @isTest
    public static void renewActiveSubscriptionFailedResponseIfBizaoResponseStatusIsCandelAndOrderShouldBelosefulWithTax_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__status__c
                                         FROM Zuora__Subscription__c LIMIT 1];
        newSub.Zuora__Status__c = 'Active';
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

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String bizaoBodyRequest =  '{' +
        '"meta": {' +
        '   "type": "payment",' +
        '    "source": "orange",' +
        '    "channel": "tpe"' +
        '},' +
        '"status": "Failed",' +
        '"amount": "30000",' +
        '"order-id": "Order-Id-0123456789",' +
        '"currency": "XOF",' +
        '"reference": "Your-reference",' +
        '"date": "2020-09-29 09:34:32.0",' +
        '"state": "param1%3Dvalue1%26param2%3Dvalue2",' +
        '"country-code": "sn",' +
        '"intTransaction-id": "1601372072771",' +
        '"extTransaction-id ": "MP200929.0935.A64320"' +
        '}';

        req.requestURI = '/services/apexrest/bizaorest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bizaoBodyRequest); //Blob.valueOf(JSON.serializePretty(bodyRequest));

        RestContext.request = req;
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        Test.startTest();
        String bizaoRestResponse = BizaoRest.doPost();
        Test.stopTest();

        System.assertEquals('Subcription renew failed',  bizaoRestResponse, 'The response should be failed');

        RenewSubscriptionData__c renewSubscriptionData = [SELECT Id, RSD_IsOrderOpen__c, RSD_LogBizaoRestApi__c
                                                          FROM RenewSubscriptionData__c
                                                          WHERE RSD_OrderId__c = 'Order-Id-0123456789'
                                                          LIMIT 1];
        System.assertEquals(false, renewSubscriptionData.RSD_IsOrderOpen__c, 'The order should be close');
        System.assert(renewSubscriptionData.RSD_LogBizaoRestApi__c.contains('Bizao notification status : Failed'), 'The log should contains  Bizao notification status : Failed');
    }

    @isTest
    public static void renewActiveSubscriptionCreditCardSucceededResponseWithTax_Test(){

        RenewSubscriptionData__c renewSubscriptionData =  [SELECT Id FROM RenewSubscriptionData__c LIMIT 1];
        renewSubscriptionData.RSD_Payment_Method__c = 'Credit_Card';
        update renewSubscriptionData;

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
        currentUser.CountryCode = 'CD';
        update currentUser;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String bizaoBodyRequest =  '{' +
        '"meta": {' +
        '   "type": "payment",' +
        '    "source": "orange",' +
        '    "channel": "tpe"' +
        '},' +
        '"status": "Successful",' +
        '"amount": "30000",' +
        '"order-id": "Order-Id-0123456789",' +
        '"currency": "XOF",' +
        '"reference": "Your-reference",' +
        '"date": "2020-09-29 09:34:32.0",' +
        '"state": "param1%3Dvalue1%26param2%3Dvalue2",' +
        '"country-code": "sn",' +
        '"intTransaction-id": "1601372072771",' +
        '"extTransaction-id ": "MP200929.0935.A64320"' +
        '}';

        req.requestURI = '/services/apexrest/bizaorest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bizaoBodyRequest); //Blob.valueOf(JSON.serializePretty(bodyRequest));

        RestContext.request = req;
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        Test.startTest();
        String bizaoRestResponse = BizaoRest.doPost();
        Test.stopTest();
        System.assertEquals('Subcription renew successful',  bizaoRestResponse, 'The response should be sucess');

        Zuora__Subscription__c zuoraSubscriptionUpdated = [SELECT Id, NbrJoursRestants__c, SUB_T_Payment_Number__c FROM Zuora__Subscription__c WHERE Zuora__SubscriptionNumber__c = 'A-S00000400' LIMIT 1];
        List<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                     FROM Suivi_de_Souscription__c
                                                     WHERE SV_Id_Souscription__c = :zuoraSubscriptionUpdated.Id
                                                     AND SV_Code_Action__c = 'ACT003'];
        System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');
        renewSubscriptionData = [SELECT Id, RSD_IsOrderOpen__c
                                 FROM RenewSubscriptionData__c
                                 WHERE RSD_OrderId__c = 'Order-Id-0123456789'
                                 LIMIT 1];
        System.assertEquals(false, renewSubscriptionData.RSD_IsOrderOpen__c, 'The order should be close');
    }

    @isTest
    public static void downgradeProductNotPossible_test(){
        RenewSubscriptionData__c renewSubscriptionData =  [SELECT Id FROM RenewSubscriptionData__c LIMIT 1];
        renewSubscriptionData.RSD_SelectedRenewOffer__c = 'REABO_DOWN';
        update renewSubscriptionData;

        Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__status__c
                                         FROM Zuora__Subscription__c LIMIT 1];
        newSub.Zuora__Status__c = 'Active';
        newSub.isCollaborator__c = 'Y';
        update newSub;
        Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
        Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
        insert subProduct;
        Zuora__SubscriptionProductCharge__c subProduct1 = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, system.label.Rate_Plan_Timbre_Fiscal, zpr.Id, system.label.Rate_Plan_Timbre_Fiscal);
        insert subProduct1;
        Zuora__SubscriptionProductCharge__c collabProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Collaborator', zpr.Id, 'Collaborator');
        insert collabProduct;
        collabProduct.Zuora__OriginalProductRatePlanChargeId__c = '40289f4664641276016464740dd0001c';
        update collabProduct;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String bizaoBodyRequest =  '{' +
        '"meta": {' +
        '   "type": "payment",' +
        '    "source": "orange",' +
        '    "channel": "tpe"' +
        '},' +
        '"status": "Successful",' +
        '"amount": "30000",' +
        '"order-id": "Order-Id-0123456789",' +
        '"currency": "XOF",' +
        '"reference": "Your-reference",' +
        '"date": "2020-09-29 09:34:32.0",' +
        '"state": "param1%3Dvalue1%26param2%3Dvalue2",' +
        '"country-code": "sn",' +
        '"intTransaction-id": "1601372072771",' +
        '"extTransaction-id ": "MP200929.0935.A64320"' +
        '}';

        req.requestURI = '/services/apexrest/bizaorest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bizaoBodyRequest); //Blob.valueOf(JSON.serializePretty(bodyRequest));

        RestContext.request = req;
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        Test.startTest();
        String bizaoRestResponse = BizaoRest.doPost();
        Test.stopTest();
        System.assertEquals('Renew with downgrade is not possible',  bizaoRestResponse, 'The response should be : Renew with downgrade is not possible');

        renewSubscriptionData = [SELECT Id, RSD_IsOrderOpen__c, RSD_LogBizaoRestApi__c
                                 FROM RenewSubscriptionData__c
                                 WHERE RSD_OrderId__c = 'Order-Id-0123456789'
                                 LIMIT 1];
        System.assertEquals(true, renewSubscriptionData.RSD_IsOrderOpen__c, 'The order should not be closed since the payment is successful but renew action can\'t be done');
        System.assert(renewSubscriptionData.RSD_LogBizaoRestApi__c.contains('Renew with downgrade is not possible'), 'The RSD_LogBizaoRestApi__c should contains :  Renew with downgrade is not possible');

    }

    @isTest
    public static void notFoundInstanceOfRenewSubscriptionData(){

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
        currentUser.CountryCode = 'CD';
        update currentUser;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String bizaoBodyRequest =  '{' +
        '"meta": {' +
        '   "type": "payment",' +
        '    "source": "orange",' +
        '    "channel": "tpe"' +
        '},' +
        '"status": "Successful",' +
        '"amount": "30000",' +
        '"order-id": "Wrong-Order-Id",' +
        '"currency": "XOF",' +
        '"reference": "Your-reference",' +
        '"date": "2020-09-29 09:34:32.0",' +
        '"state": "param1%3Dvalue1%26param2%3Dvalue2",' +
        '"country-code": "sn",' +
        '"intTransaction-id": "1601372072771",' +
        '"extTransaction-id ": "MP200929.0935.A64320"' +
        '}';

        req.requestURI = '/services/apexrest/bizaorest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bizaoBodyRequest); //Blob.valueOf(JSON.serializePretty(bodyRequest));

        RestContext.request = req;
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        Test.startTest();
        String bizaoRestResponse = BizaoRest.doPost();
        Test.stopTest();
        System.assertEquals('No Renew Subscription Data was Found with the specific order Id',  bizaoRestResponse, 'No RenewSubscriptionData should be found');

    }

    @isTest
    public static void noRenewSucriptionWhenSecondCall(){

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
        currentUser.CountryCode = 'CD';
        update currentUser;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        String bizaoBodyRequest =  '{' +
        '"meta": {' +
        '   "type": "payment",' +
        '    "source": "orange",' +
        '    "channel": "tpe"' +
        '},' +
        '"status": "Successful",' +
        '"amount": "30000",' +
        '"order-id": "Order-Id-0123456789",' +
        '"currency": "XOF",' +
        '"reference": "Your-reference",' +
        '"date": "2020-09-29 09:34:32.0",' +
        '"state": "param1%3Dvalue1%26param2%3Dvalue2",' +
        '"country-code": "sn",' +
        '"intTransaction-id": "1601372072771",' +
        '"extTransaction-id ": "MP200929.0935.A64320"' +
        '}';

        req.requestURI = '/services/apexrest/bizaorest';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(bizaoBodyRequest); //Blob.valueOf(JSON.serializePretty(bodyRequest));

        RestContext.request = req;
        RestContext.response = res;

        Test.setMock(HttpCalloutMock.class, new ZuoraMock());
        Test.startTest();
        String bizaoRestResponse = BizaoRest.doPost();
        String bizaoRestResponseSecondCall = BizaoRest.doPost();
        Test.stopTest();
        System.assertEquals('Subcription renew successful',  bizaoRestResponse, 'The response should be : Successful');
        System.assertEquals('Bizao response has already been treated for this order',  bizaoRestResponseSecondCall, 'order is open = false');

        Zuora__Subscription__c zuoraSubscriptionUpdated = [SELECT Id, NbrJoursRestants__c, SUB_T_Payment_Number__c FROM Zuora__Subscription__c WHERE Zuora__SubscriptionNumber__c = 'A-S00000400' LIMIT 1];
        List<Suivi_de_Souscription__c> renewSuivi = [SELECT id
                                                     FROM Suivi_de_Souscription__c
                                                     WHERE SV_Id_Souscription__c = :zuoraSubscriptionUpdated.Id
                                                     AND SV_Code_Action__c = 'ACT003'];
        System.assertEquals(1, renewSuivi.size(), 'A suivi record should be created');
        RenewSubscriptionData__c renewSubscriptionData = [SELECT Id, RSD_IsOrderOpen__c, RSD_LogBizaoRestApi__c
                                                          FROM RenewSubscriptionData__c
                                                          WHERE RSD_OrderId__c = 'Order-Id-0123456789'
                                                          LIMIT 1];
        System.assertEquals(false, renewSubscriptionData.RSD_IsOrderOpen__c, 'The order should be close');
        System.assert(renewSubscriptionData.RSD_LogBizaoRestApi__c.contains('Bizao notification status : Successful'), 'The RSD_LogBizaoRestApi__c should contains :  Bizao notification status : Successful');
        System.assert(renewSubscriptionData.RSD_LogBizaoRestApi__c.contains('Response has already been treated for this order'), 'The RSD_LogBizaoRestApi__c should contains :  Response has already been treated for this order');
    }

}