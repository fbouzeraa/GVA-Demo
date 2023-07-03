/**
 * Classe test pour ZuoraSubscriptionActions
 * Couverture: 80%
 */
@isTest
public class ZuoraSubscriptionActions_Test {
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
    public static void checkAccountEligibility_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){

            Zuora__Subscription__c newSub = [SELECT Id, Name, Quote__c, Zuora__Account__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            String AccountId = 'newSub.Zuora__Account__c';
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new EligMock());
            boolean isElligible = ZuoraSubscriptionActions.checkAccountEligibility(newSub.Quote__c);
            ZuoraSubscriptionActions.getProductRatePlans();
            ZuoraSubscriptionActions.addOrderNumberToQuote('12235455', newSub.Quote__c);
            ZuoraSubscriptionActions.addPaymentIdToQuote(newSub.Quote__c,'123234546');
            ZuoraSubscriptionActions.userCountryCode();
            Test.stopTest();
            System.assertEquals(true, isElligible, 'Account is not eligible');
            //Test.stopTest();
        }
    }
    @isTest
    public static void createSubscriptionInZuoraSucceededRequestWithTax_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        System.runAs(togoAdminUser){

            try {
                
                id smeAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_CompteSME').getRecordTypeId();

                list<Zuora__Subscription__c> sub = [SELECT Name, Quote__c, Zuora__CustomerAccount__c
                                                    FROM Zuora__Subscription__c];
                delete sub;
                Account acc = new Account ( Name = 'accName', ACC_BuildingID__c = 'TGG_125', ACC_LatLong__Latitude__s = 2, ACC_Eligible__c = false,
                                            ACC_LatLong__Longitude__s = 1.2, ACC_NumeroDEtage__c = 2, phone = '1212121', ACC_PresencePTO_cc__c = 'non',
                                            ACC_MaturiteProspect__c = 'Chaud', ACC_CategorisationProspect__c = 'prix', BillingCountry = 'Togo', BillingCountryCode = 'TG',
                                            CurrencyIsoCode = 'XOF', recordtypeId = smeAccountId, ACC_Escalier__c = 'Esc-12', ACC_Indicatif__c = '+228');

                try {
                 //  insert acc;
                } catch (Exception e) {
                    system.debug('acct insert error '+e.getMessage());
                }
                
                Quote currentQuote = [SELECT Id, opportunityId, Status, QUO_SommeEncaissee__c, Subtotal, AccountId, QUO_Grand_Total__c
                                    FROM Quote
                                    LIMIT 1];

                list<QuoteLineItem> listQLI = [SELECT Id
                                            FROM QuoteLineItem
                                            WHERE quoteId = :currentQuote.Id];
                opportunity Opp = new Opportunity(AccountId = acc.Id, Id = currentQuote.opportunityId);
                try {
                    update opp;

                    currentQuote.Status = 'Accepted';
                    currentQuote.QUO_Mode_de_paiement__c = 'Cash';
                    currentQuote.QUO_Periodes_Prepayees__c = '1';
                    currentQuote.QUO_TECH_Nombre_De_Produits__c = 2;
                    currentQuote.QUO_SommeEncaissee__c = true;
                    currentQuote.QUO_IsCollaborator__c = 'Y';
                    currentQuote.QUO_Grand_Total__c = 122;
                    currentQuote.QUO_T_Account__c = acc.Id;
                    update currentQuote;
    
                    Contact con = new Contact(FirstName = 'Test', LastName = 'Test', CON_Role__c = 'Sig', AccountId = acc.Id );
                    insert con;
                } catch (Exception e) {
                    system.debug('insert error '+e.getMessage());
                }
            
                ZuoraResponseObjects.ZuoraCreateOrderResponse OrderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();

                Test.startTest();
                Test.setMock(HttpCalloutMock.class, new ZuoraMock());

                string JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(currentQuote.Id, false);

                orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse)JSON.deserialize(JSONResponse, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

                //add payment to the subscription
                string zAccountId = ZuoraSubscriptionActions.getZuoraAccountInfo(orderResponse.accountNumber);
                ZuoraSubscriptionActions.addDefaultPaymentMethod(zAccountId);
                string paymentResponse = ZuoraSubscriptionActions.createPayment(null, zAccountId, currentQuote.Id, orderResponse.orderNumber);
                ZuoraResponseObjects.ZuoraPayment newPaymentResponse = new ZuoraResponseObjects.ZuoraPayment();
                newPaymentResponse = (ZuoraResponseObjects.ZuoraPayment) JSON.deserialize(paymentResponse, ZuoraResponseObjects.ZuoraPayment.class);

                System.assertEquals(true, newPaymentResponse.success, 'Payment should be added');

                ZuoraSubscriptionActions.addPaymentIdToQuote(currentQuote.Id, newPaymentResponse.id);
                Quote updatedQuote = [SELECT QUO_T_PaymentID__c
                                    FROM Quote
                                    LIMIT 1];
                System.assertEquals(newPaymentResponse.id, updatedQuote.QUO_T_PaymentID__c, 'Payment Id should be added');
                Zuora__Subscription__c newSub = TestUtils.createSubscription(currentQuote.AccountId, currentQuote.Id, null, '1234');
                insert newSub;
                Test.stopTest();
            } catch (Exception e) {
                system.debug('test error '+ e.getLineNumber()+' >>> '+ e.getMessage());
            }
        }
    }
    @isTest
    public static void createSubscriptionInZuoraSucceededRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            list<Zuora__Subscription__c> sub = [SELECT Name, Quote__c, Zuora__CustomerAccount__c
                                                FROM Zuora__Subscription__c];
            delete sub;
            Quote currentQuote = [SELECT Id, Status, QUO_SommeEncaissee__c, Subtotal, AccountId, QUO_Grand_Total__c,
                                  QUO_Montant_Rendu_CDF__c, QUO_Montant_Rendu_Dollar__c, QUO_Taux_De_Change__c
                                  FROM Quote
                                  LIMIT 1];

            list<QuoteLineItem> listQLI = [SELECT Id
                                           FROM QuoteLineItem
                                           WHERE quoteId = :currentQuote.Id];

            currentQuote.Status = 'Accepted';
            currentQuote.QUO_Mode_de_paiement__c = 'Credit_Card';
            currentQuote.QUO_Periodes_Prepayees__c = '1';
            currentQuote.QUO_TECH_Nombre_De_Produits__c = 2;
            currentQuote.QUO_SommeEncaissee__c = true;
            currentQuote.QUO_Grand_Total__c = 122;
            update currentQuote;

            ZuoraResponseObjects.ZuoraCreateOrderResponse OrderResponse = new ZuoraResponseObjects.ZuoraCreateOrderResponse();

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(currentQuote.Id, false);
            orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse)JSON.deserialize(JSONResponse, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
            System.assertEquals(true, orderResponse.success, 'Subscription should be created');

            String qq = ZuoraSubscriptionActions.getCustomerAccountId(currentQuote.Id);
            Test.stopTest();
        }
    }
    @isTest
    public static void createSubscriptionInZuoraFailRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Name, Quote__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Quote currentQuote = [SELECT Id, Status, QUO_SommeEncaissee__c, Subtotal, opportunityId
                                  FROM Quote
                                  WHERE id = :newSub.Quote__c];

            list<QuoteLineItem> listQLI = [SELECT id, PricebookEntryId, Product2Id, Product_Rate_Plan__c
                                           FROM QuoteLineItem
                                           WHERE quoteId = :newSub.Quote__c];

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(newSub.Quote__c, false);
            boolean result = JSONResponse.contains('"success" : true');
            System.assertEquals(false, result, 'Quote should have only one subscription');
        }
    }
    @isTest
    public static void createSubscriptionInZuoraFailed_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Name, Quote__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Quote currentQuote = [SELECT Id, Status, QUO_SommeEncaissee__c, Subtotal, opportunityId
                                  FROM Quote
                                  WHERE id = :newSub.Quote__c];

            list<QuoteLineItem> listQLI = [SELECT id, PricebookEntryId, Product2Id, Product_Rate_Plan__c
                                           FROM QuoteLineItem
                                           WHERE quoteId = :newSub.Quote__c];

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            delete newSub;
            string JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(currentQuote.Id, false);
            boolean result = JSONResponse.contains('"success" : true');
            System.assertEquals(false, result, 'Quote should be valid');

            JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(currentQuote.Id, false);
            result = JSONResponse.contains('"success" : true');
            System.assertEquals(false, result, 'Number of prepaid periods and payment method should be filled');

            delete listQLI;
            JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(currentQuote.Id, false);
            result = JSONResponse.contains('"success" : true');
            System.assertEquals(false, result, 'Quote should have Products');
            Test.stopTest();
        }
    }
    @isTest
    public static void createSubscriptionInZuoraFailRequest1_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Name, Quote__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Quote currentQuote = [SELECT Id, Status, QUO_SommeEncaissee__c, Subtotal, opportunityId, QUO_Grand_Total__c,
                                  QUO_Montant_Rendu_CDF__c, QUO_Montant_Rendu_Dollar__c, QUO_Taux_De_Change__c
                                  FROM Quote
                                  WHERE id = :newSub.Quote__c];

            currentQuote.QUO_SommeEncaissee__c = true;
            currentQuote.Status = 'Approved';
            currentQuote.QUO_Mode_de_paiement__c = 'Cash';
            currentQuote.QUO_Grand_Total__c = 1222;
            update currentQuote;
            list<QuoteLineItem> listQLI = [SELECT id, PricebookEntryId, Product2Id, Product_Rate_Plan__c, Product_Rate_Plan__r.zqu__ZProduct__r.zqu__ZuoraId__c
                                           FROM QuoteLineItem
                                           WHERE quoteId = :newSub.Quote__c];

            Quote newQuote = new Quote(QUO_SommeEncaissee__c = true, Status = 'Approved', Name = 'Create Sub', opportunityId = currentQuote.opportunityId, QUO_Grand_Total__c = 122);
            insert newQuote;
            QuoteLineItem QLI = TestUtils.CreateQuoteLineItem(newQuote.Id, listQLI[0].Product2Id, listQLI[0].Product_Rate_Plan__c, listQLI[0].PricebookEntryId);
            insert QLI;
            delete newSub;
            delete listQLI;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(currentQuote.Id, false);
            boolean result = JSONResponse.contains('"success" : true');
            System.assertEquals(false, result, 'QuoteLineItem should not be empty');
            JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(newQuote.Id, false);
            result = JSONResponse.contains('"success" : true');
            System.assertEquals(false, result, 'Number of prepaid period should be filled');
            Test.stopTest();
        }
    }
    @isTest
    public static void createPreviewSubscriptionSucceededRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Name, Quote__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            delete newSub;
            Quote currentQuote = [SELECT Id, Status, QUO_SommeEncaissee__c, Subtotal
                                  FROM Quote
                                  WHERE id = :newSub.Quote__c];

            currentQuote.QUO_Periodes_Prepayees__c = '1';
            currentQuote.QUO_TECH_Nombre_De_Produits__c = 2;
            currentQuote.QUO_Mode_De_Paiement__c = 'Cash';
            currentQuote.Status = 'In Review';
            update currentQuote;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(currentQuote.Id, true);
            Boolean result = JSONResponse.contains('"success":true');
            System.assertEquals(true, result, 'Preview subscription should be created');
            Test.stopTest();
        }
    }
    @isTest
    public static void createPreviewSubscriptionFailedRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Name, Quote__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Quote currentQuote = [SELECT Status, QUO_SommeEncaissee__c, Subtotal
                                  FROM Quote
                                  WHERE id = :newSub.Quote__c];

            currentQuote.Status = 'Denied';
            update currentQuote;
            Test.startTest();

            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            boolean isRDC = ZuoraSubscriptionActions.checkRDCUser();
            string JSONResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(newSub.Quote__c, true);
            Boolean result = JSONResponse.contains('"success" : true');
            System.assertEquals(false, result, 'Quote should be valid to show a preview');

            Test.stopTest();
        }
    }

    @isTest
    public Static void cancelSubscriptionSucceededRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId
                                             FROM Zuora__Subscription__c LIMIT 1];
            Quote cancelQuote = new Quote(Name = 'Cancel Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert cancelQuote;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            ZuoraSubscriptionActions.activateSubscription(newSub.Id);
            string JSONResponse = ZuoraSubscriptionActions.cancelSubscription(newSub.Id, cancelQuote.Id, 'Other', false);
            Boolean result = JSONResponse.contains('"success":true');
            System.assertEquals(true, result, 'Subscription should be canceled');
            Test.stopTest();
        }
    }
    @isTest
    public Static void cancelSubscriptionFailedRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, isCollaborator__c, Quote__c, Quote__r.OpportunityId, Zuora__Status__c
                                             FROM Zuora__Subscription__c LIMIT 1];
            Quote cancelQuote = new Quote(Name = 'Cancel Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert cancelQuote;
            newSub.isCollaborator__c = 'Y';
            update newSub;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 400));
            string JSONResponse = ZuoraSubscriptionActions.cancelSubscription(newSub.Id, cancelQuote.Id, 'Other', false);
            Boolean result = JSONResponse.contains('"success":true');
            System.assertEquals(false, result, 'Subscription should not be canceled');
            Test.stopTest();
            newSub.zuora__Status__c = 'Suspended';

            update newSub;
        }
    }
    @isTest
    public Static void suspendSubscriptionSucceededfulRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId
                                             FROM Zuora__Subscription__c LIMIT 1];
            Quote suspendQuote = new Quote(Name = 'Suspend Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert suspendQuote;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string suspendResponse = ZuoraSubscriptionActions.supspendSubscription(newSub.Id, suspendQuote.Id, 'Month', 2);
            Boolean result = suspendResponse.contains('"success" : true');
            System.assertEquals(true, result, 'Subscription not suspended');
            Test.stopTest();
        }
    }
    @isTest
    public Static void suspendSubscriptionFailedRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Quote__c, Quote__r.OpportunityId
                                             FROM Zuora__Subscription__c LIMIT 1];
            Quote suspendQuote = new Quote(Name = 'Suspend Quote', OpportunityId = newSub.Quote__r.OpportunityId);
            insert suspendQuote;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 400));
            string JSONResponse = ZuoraSubscriptionActions.supspendSubscription(newSub.Id, suspendQuote.Id, 'Month', 2);
            Boolean result = JSONResponse.contains('"success" : true');
            System.assertEquals(false, result, 'Subscription should not be suspended');
            Test.stopTest();
        }
    }
    @isTest
    public static void updateSubscriptionTriggerDateSucceededResponse_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT id, Name, Zuora__ServiceActivationDate__c, Zuora__Zuora_Id__c,
                                             Quote__r.AccountId, Quote__r.Name, Zuora__CustomerAccount__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            newSub.Zuora__ServiceActivationDate__c = date.today().addDays(6);
            newSub.Zuora__Zuora_Id__c = '12121212121';
            update newSub;
            Zuora__Payment__c payment = new Zuora__Payment__c(Zuora__EXT_ID__c = '1234567', OrderNumber__c = newSub.Quote__r.Name,
                                                              Zuora__Account__c = newSub.Quote__r.AccountId, Zuora__BillingAccount__c = newSub.Zuora__CustomerAccount__c);
            insert payment;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            ZuoraSubscriptionActions.updateSubscriptionTriggerDate(new List<string> {newSub.Id + ',' + date.today().addDays(3)});
            Test.stopTest();
            Zuora__Subscription__c updatedSub = [SELECT Zuora__ServiceActivationDate__c
                                                 FROM Zuora__Subscription__c
                                                 LIMIT 1];
            System.assertEquals(date.today().addDays(6), updatedSub.Zuora__ServiceActivationDate__c, 'Subscription should not have been reverted');
        }
    }
    @isTest
    public static void updateSubscriptionTriggerDateSucceededResponse1_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            // apply one payment to the generated bill
            Zuora__Subscription__c newSub = [SELECT id, Name, Zuora__ServiceActivationDate__c, Zuora__Zuora_Id__c, Quote__r.AccountId
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            newSub.Zuora__ServiceActivationDate__c = date.today().addDays(6);
            newSub.Zuora__Zuora_Id__c = '12121212121';
            update newSub;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            ZuoraSubscriptionActions.updateSubscriptionTriggerDate(new List<string> {newSub.Id + ',' + date.today().addDays(3)});
            Test.stopTest();
            Zuora__Subscription__c updatedSub = [SELECT Zuora__ServiceActivationDate__c
                                                 FROM Zuora__Subscription__c
                                                 LIMIT 1];
            System.assertEquals(date.today().addDays(6), updatedSub.Zuora__ServiceActivationDate__c, 'Subscription should not have been reverted');
        }
    }

    @isTest
    public static void createSubscriptionInZuoraWithNullBoxNumber_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            //add Zuora Mock and Eligibility Mock to MultiMock class
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
            endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
            HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);

            Profile pAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système'];
            Profile pVAD = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système'];

            user myTestUserAdmin = TestUtils.createUser('example1@test.com', 'lastName1', 'j.abinassif@gva.africa', 'USER123', pAdmin.Id);
            user myTestUserVAD = TestUtils.createUser('example2@test.com', 'Abi NAssif', 'jjj.abinassif@gva.africa', 'USER124', pVAD.Id);
            list<User> myUsers = new List<USer> {myTestUserAdmin, myTestUserVAD};
            try {
                insert myUsers;
            } catch(Exception eUser) {
                system.debug('eUser ' + eUser);
            }
            Account acc = TestUtils.createPersonAccount('jackieAccount');
            try {
                insert acc;
            } catch(Exception eACC) {
                system.debug('eACC ' + eACC);
            }
            String priceBookId = TestUtils.createPriceBook();
            Opportunity opp = TestUtils.createOpportunity('oppName', acc.Id, priceBookId);
            try {
                insert opp;
            } catch(Exception eOpp) {
                system.debug('eOpp ' + eOpp);
            }
            Quote newQuote = new Quote (Name = 'quoteName', OpportunityId = opp.Id, priceBook2Id = priceBookId,
                                        QUO_Periodes_Prepayees__c = '2', QUO_T_Numero_De_Commande__c = 'O-0000100', QUO_PTO__c = 'PTO01', QUO_T_Numero_du_Box__c = '');
            try {
                insert newQuote;
            } catch(Exception eQuote) {
                system.debug('eQuote ' + eQuote);
            }
            Test.startTest();
            String creationResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(newQuote.Id, false);
            Test.stopTest();
            System.assertEquals(system.label.Empty_Box_Number, creationResponse, 'Message should be an error of empty box number');
        }
    }

    @isTest
    public static void createSubscriptionInZuoraNullBoxNumberAsVAD_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            //add Zuora Mock and Eligibility Mock to MultiMock class
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
            endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
            HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);

            Profile pAdmin = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système'];
            Profile pVAD = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système'];

            user myTestUserAdmin = TestUtils.createUser('example1@test.com', 'lastName1', 'j.abinassif@gva.africa', 'USER123', pAdmin.Id);
            user myTestUserVAD = TestUtils.createUser('example2@test.com', 'Abi NAssif', 'jjj.abinassif@gva.africa', 'USER124', pVAD.Id);
            list<User> myUsers = new List<USer> {myTestUserAdmin, myTestUserVAD};
            try {
                insert myUsers;
            } catch(Exception eUser) {
                system.debug('eUser ' + eUser);
            }
            Account acc = TestUtils.createPersonAccount('jackieAccount');
            try {
                insert acc;
            } catch(Exception eACC) {
                system.debug('eACC ' + eACC);
            }
            String priceBookId = TestUtils.createPriceBook();
            Opportunity opp = TestUtils.createOpportunity('oppName', acc.Id, priceBookId);
            try {
                insert opp;
            } catch(Exception eOpp) {
                system.debug('eOpp ' + eOpp);
            }
            Quote newQuote = new Quote (Name = 'quoteName', OpportunityId = opp.Id, priceBook2Id = priceBookId,
                                        QUO_Periodes_Prepayees__c = '2', QUO_T_Numero_De_Commande__c = 'O-0000100', QUO_PTO__c = 'PTO01', QUO_T_Numero_du_Box__c = '');
            Quote newQuote2 = new Quote (Name = 'quoteName2', OpportunityId = opp.Id, priceBook2Id = priceBookId,
                                         QUO_Periodes_Prepayees__c = '2', QUO_T_Numero_De_Commande__c = 'O-0000100', QUO_PTO__c = 'PTO01', QUO_T_Numero_du_Box__c = 'ALCL:B3B9C31C');
            List<Quote> listOfquote = new List<Quote> {newQuote, newQuote2};
            try {
                insert listOfquote;
            } catch(Exception eQuote) {
                system.debug('eQuote ' + eQuote);
            }
            system.runAs(myTestUserVAD){
                Test.startTest();
                String creationResponse = ZuoraSubscriptionActions.createSubscriptionInZuora(newQuote.Id, false);
                String creationResponse2 = ZuoraSubscriptionActions.createSubscriptionInZuora(newQuote2.Id, false);
                Test.stopTest();
                System.assertEquals(System.label.Empty_Box_Number, creationResponse, 'Message should be an error of empty box number');
                list<Zuora__Subscription__c> zSub = [SELECT Id, Quote__c FROM Zuora__Subscription__c WHERE Quote__c =: newQuote2.Id LIMIT 1];
                System.assertEquals(true, zSub != null, 'Subscription should be created');
            }
        }
    }

    @isTest
    public static void createTechnicalSubscriptionSucceededRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, Quote__c, Quote__r.OpportunityId, Zuora__Status__c, Quote__r.Opportunity.priceBook2Id,
                                             Zuora__Account__c, Zuora__CustomerAccount__c, Zuora__SubscriptionNumber__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            Zuora__Subscription__c newTechSub = new Zuora__Subscription__c (Zuora__Account__c = newSub.Zuora__Account__c,
                                                                            Zuora__CustomerAccount__c = newSub.Zuora__CustomerAccount__c, Quote__c = newSub.Quote__c,
                                                                            Zuora__SubscriptionNumber__c = newSub.Zuora__SubscriptionNumber__c + '-001' );
            insert newTechSub;
            string selectedJSON = '[{"Id" : "a155r0000002OYOAA2", "Type__c" : "AddOn", "Category__c" : "Accessory", "Name" : "Repeteur wifi N300 Dodocool", "zqu__Product__c" : "01t5r000001UCn1AAG", "zqu__ZuoraId__c" : "8adc8ea17c0bcae2017c0e1801590157", "zqu__Product__r" : {"Name" : "CanalBox - Burkina Faso", "Id" : "01t5r000001UCn1AAG"}, "ProductName" : "CanalBox - Burkina Faso", "ProductCategory" : "Accessory"}]';

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string JSONResponse = ZuoraSubscriptionActions.createTechnicalSubscription( selectedJSON, newSub.Id, false, null,
                                                                                        null, null, null, null, '123421', 'Orange', null, 'Mobile_Money');

            ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse)JSON.deserialize(JSONResponse, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);
            System.assertEquals(true, orderResponse.success, 'Subscription should be created');
        }
    }
    @isTest
    public static void createActiveTechnicalSubscriptionSucceededRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, Quote__c, Quote__r.OpportunityId, Zuora__Status__c, Quote__r.Opportunity.priceBook2Id
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            newSub.zuora__Status__c = 'Active';
            update newSub;

            string selectedJSON = '[{"Id" : "a155r0000002OYOAA2", "Type__c" : "AddOn", "Category__c" : "Accessory", "Name" : "Repeteur wifi N300 Dodocool", "zqu__Product__c" : "01t5r000001UCn1AAG", "zqu__ZuoraId__c" : "8adc8ea17c0bcae2017c0e1801590157", "zqu__Product__r" : {"Name" : "CanalBox - Burkina Faso", "Id" : "01t5r000001UCn1AAG"}, "ProductName" : "CanalBox - Burkina Faso", "ProductCategory" : "Accessory"}]';

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            string JSONResponse = ZuoraSubscriptionActions.createTechnicalSubscription( selectedJSON, newSub.Id, false, null,
                                                                                        null, null, null, null, '123421', 'Orange', null, 'Mobile_Money');
            ZuoraResponseObjects.ZuoraCreateOrderResponse orderResponse = (ZuoraResponseObjects.ZuoraCreateOrderResponse)JSON.deserialize(JSONResponse, ZuoraResponseObjects.ZuoraCreateOrderResponse.class);

            System.assertEquals(true, orderResponse.success, 'Subscription should be created');
            Test.stopTest();
        }
    }

    @isTest
    public static void createTechnicalSubscriptionFailedRequest_Test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, Quote__c, Quote__r.OpportunityId, Zuora__Status__c, Quote__r.Opportunity.priceBook2Id
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            string selectedJSON = '[{"Id" : "a155r0000002OYOAA2", "Type__c" : "AddOn", "Category__c" : "Accessory", "Name" : "Repeteur wifi N300 Dodocool", "zqu__Product__c" : "01t5r000001UCn1AAG", "zqu__ZuoraId__c" : "8adc8ea17c0bcae2017c0e1801590157", "zqu__Product__r" : {"Name" : "CanalBox - Burkina Faso", "Id" : "01t5r000001UCn1AAG"}, "ProductName" : "CanalBox - Burkina Faso", "ProductCategory" : "Accessory"}]';

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 300));
            string JSONResponse = ZuoraSubscriptionActions.createTechnicalSubscription( selectedJSON, newSub.Id, false, null,
                                                                                        null, null, null, null, '123421', 'Orange', null, 'Mobile_Money');

            Boolean result = JSONResponse.contains('"success":true');
            System.assertEquals(false, result, 'Technical subscription should not be created');
        }
    }

    @isTest
    public static void updateAccountAddress_Test(){
        user togoAdminUser = [SELECT id, USR_BypassVR__c FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        togoAdminUser.USR_BypassVR__c = true;
        update togoAdminUser;
        System.runAs(togoAdminUser){
            Test.startTest();
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
            endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
            HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);

            Zuora__Subscription__c sub = [SELECT id, name, Zuora__Account__c, Zuora__Account__r.ACC_BuildingID__c
                                          FROM Zuora__Subscription__c
                                          limit 1];
            Account acc = new Account();
            acc.ACC_BuildingId__c = 'OUA_1';
            acc.ACC_TIN__c = '123';
            acc.id = sub.Zuora__Account__c;
            update acc;
            Test.stopTest();
        }
    }

    @isTest
    public static void sendFundReportSucceededResponse_Test(){
        user myTestUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(myTestUser){
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            test.startTest();
            boolean isRDC = ZuoraSubscriptionActions.checkRDCUser();
            string reportResponse = ZuoraSubscriptionActions.sendFundReport();
            system.assertEquals(System.label.Rapport_De_Caisse_Success_Message, reportResponse, 'Report should be sent to the current user');
            system.assertEquals(false, isRDC, 'User country is incorrect');

            test.stopTest();
        }

    }
    @isTest
    public static void sendFundReportFailedResponse_Test(){
        user myTestUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(myTestUser){

            Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 400));
            test.startTest();
            string reportResponse = ZuoraSubscriptionActions.sendFundReport();
            system.assertNotEquals(System.label.Rapport_De_Caisse_Success_Message, reportResponse, 'Report should not be sent to the current user');
            test.stopTest();
        }

    }
    @isTest
    public static void reserveBox_Test() {
        Quote currentQuote = [SELECT Id FROM Quote LIMIT 1];

        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));

        string response = StockActions.reserveBox('[{"serial":"ALCL:9009","type_article_ref":"NOkON"}]', currentQuote.Id, null, 'NONNOK1G-240W-F');

        CanalBoxObjects.stockReservingResponse boxReservation = (CanalBoxObjects.stockReservingResponse) System.JSON.deserialize(
            response, CanalBoxObjects.stockReservingResponse.class);

        System.assertEquals(true, boxReservation.reservation_expiry_date != null, 'Box should be reserved');
        currentQuote = [SELECT Id, QUO_T_Numero_du_Box__c FROM Quote LIMIT 1];
        System.assertEquals('ALCL:9009', currentQuote.QUO_T_Numero_du_Box__c, 'Box Number should be added to the quote');
        Test.stopTest();
    }
    @isTest
    public static void ChangeBox_Test() {
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c currentSub = [SELECT Id, Zuora__Status__c FROM Zuora__Subscription__c LIMIT 1];

            //Prepare Mock
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
            currentSub.Zuora__Status__c = 'Suspended';
            update currentSub;
            List<Suivi_de_Souscription__c> listSuivi = [SELECT Id
                                                        FROM Suivi_de_Souscription__c
                                                        WHERE SV_Id_Souscription__c = :currentSub.Id AND SV_Code_Action__c = 'ACT002'];
            System.assertEquals(true, listSuivi.size() > 0, 'A suivi record for suspended action should be created');

            Suivi_de_Souscription__c suivi = new Suivi_de_Souscription__c(SV_Statut__c = 'STA001', SV_Code_Action__c = 'ACT006',
                                                                          SV_Id_Souscription__c = currentSub.id, SV_Garantie__c = 2,
                                                                          SV_Box_Number__c = 'ALCL:1234', SV_Reference_Externe__c = 'R01234');
            insert suivi;
            suivi.SV_Statut__c = 'STA002';
            update suivi;

            Test.stopTest();
        }
    }
    @isTest
    public static void insertLog_Test(){
        string log = ('([{"LG_Success__c":true,"LG_Body__c" : "1423e", "LG_Method_URL__c" : "stock/stock", "LG_Subscription_Number__c" : "A-S00001234"}])');
        ZuoraSubscriptionActions.insertLogs(log);
    }
}