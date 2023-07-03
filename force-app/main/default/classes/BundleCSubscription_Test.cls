/**
 * Classe test pour BundleCSubscription
 * Couverture:
 */
@isTest
public with sharing class BundleCSubscription_Test {

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
        UserRole rle = [SELECT Id, Name FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        user togoAdminUser = TestUtils.createUser('example1@test.com', 'lastName1', 'y.bourdoukan@gva.africa', system.label.Distributor_Id, p.Id);
        togoAdminUser.UserRoleId = rle.Id;
        insert(togoAdminUser);

        System.runAs(togoAdminUser){
            TestUtils.createSub();
            Zuora__Product__c zpr = TestUtils.createZuoraProduct();
            insert zpr;
        }
    }

    @isTest
    public static void getProductAndEquipmentFromQuoteFalse_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Account__c, SUB_Status__c, SUB_Subscription_Number__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];
            Account acc = new Account(id = newSub.Zuora__Account__c, BillingCountryCode = 'BF');
            update acc;
            product2 pr = new product2(Name = 'Test', PRO_Country_Code__c = 'BF', PRO_Renewable__c = '0', PRO_Duree__c = '1;3;6', PRO_Canal_Options__c = 'CHR');
            insert pr;
            Equipment__c eq = new Equipment__c();
            eq.Equipment_Id__c = 'aaa111';
            eq.Equipment_Type__c = 'eqip 1';
            eq.Country_Code__c = 'BF';
            insert eq;
            string equip = ' [{"Equipment_Id__c" : "21100009173037", "Equipment_Type__c" : "G11A", "EQ_Decodeur__c" : true, "EQ_Have_Decoder__c" : false, "Id" : "' + eq.Id + '", "Equipment" : "21100009173037", "Type" : "G11A"}]';

            newSub.SUB_Status__c = 'Cancelled';
            newSub.SUB_Subscription_Number__c = newSub.Name;
            update newSub;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new CBundeMock());
            string compatible = BundleCSubscription.verifiyOptionsCompatibility (newSub.Id, 'false', 'Test', null, new list<string> {'CHR'}, '0');

            list<product2> listProd = BundleCSubscription.getBundleProducts(newSub.Id, 'false');
            // list<Equipment__mdt> listEquipment = BundleCSubscription.getEquipmentList(newSub.Id);
            Zuora__Subscription__c currentsub = BundleCSubscription.getCanalSubscription(newSub.Id);
            string newSubResponse = BundleCSubscription.subscribeToC (newSub.Id,  'offerName', new list<string> {'ASD', 'AEA'}, equip, '2', false);
            CBundleObjects.newSubResponse response =  (CBundleObjects.newSubResponse) JSON.deserialize(newSubResponse, CBundleObjects.newSubResponse.class);

            System.assertEquals(true, listProd.size() > 0, 'Products should be found');
            // System.assertEquals(true, listEquipment.size() > 0, 'Equipments should be found');
            System.assertEquals('OK', response.returnCode, 'Subscription Should be created');
            //    System.assertEquals(true, currentsub.SUB_Subscription_Number__c == null, 'Current client should not be subscribed to C+' );
            Test.stopTest();
        }
    }
    @isTest
    public static void getProductAndEquipmentFromQuoteTrue_test(){

        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Account__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Account acc = new Account(id = newSub.Zuora__Account__c, BillingCountryCode = 'BF');
        update acc;
        product2 pr = new product2(Name = 'Test', PRO_Country_Code__c = 'BF', PRO_Renewable__c = '0');
        insert pr;
        Equipment__c eq = new Equipment__c();
        eq.Equipment_Id__c = 'aaa111';
        eq.Equipment_Type__c = 'eqip 1';
        eq.Country_Code__c = 'BF';
        insert eq;
        Quote currentQuote = [SELECT Account.BillingCountryCode FROM Quote LIMIT 1];
        string equip = '[{"Equipment_Id__c" : "21100009173037", "Equipment_Type__c" : "G11A", "EQ_Decodeur__c" : true, "EQ_Have_Decoder__c" : false, "Id" : "' + eq.Id + '", "Equipment" : "21100009173037", "Type" : "G11A"}]';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        list<product2> listProd = BundleCSubscription.getBundleProducts(currentQuote.Id, 'true');
        // list<Equipment__mdt> listEquipment = BundleCSubscription.getEquipmentList(currentQuote.Id);
        Zuora__Subscription__c currentsub = BundleCSubscription.getCanalSubscription(newSub.Id);
        string newSubResponse = BundleCSubscription.subscribeToC (newSub.Id,  'offerName', new list<string> {'ASD', 'AEA'}, equip, '2', false);
        CBundleObjects.newSubResponse response =  (CBundleObjects.newSubResponse) JSON.deserialize(newSubResponse, CBundleObjects.newSubResponse.class);

        System.assertEquals(true, listProd.size() > 0, 'Products should be found');
        // System.assertEquals(true, listEquipment.size() > 0, 'Equipments should be found');
        System.assertEquals('OK', response.returnCode, 'Subscription Should be created');
        //    System.assertEquals(true, currentsub.SUB_Subscription_Number__c == null, 'Current client should not be subscribed to C+' );
        Test.stopTest();
    }
    @isTest
    public static void cancelBundleC_test(){

        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Account__c,SUB_Status__c, SUB_Subscription_Number__c, SUB_Subscriber_Number__c, SUB_Tech_Material__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];

        Equipment__c eq = new Equipment__c();
        eq.Equipment_Id__c = 'aaa111';
        eq.Equipment_Type__c = 'eqip 1';
        eq.Country_Code__c = 'TG';
        insert eq;
        newSub.SUB_EquipmenId_CBundle__c = 'aaa111';
        newSub.SUB_EquipmentType_CBundle__c = 'eqip 1';
        newSub.SUB_Status__c = 'Active';
        newSub.SUB_Subscription_Number__c = '1';
        newSub.SUB_Subscriber_Number__c = '1';
        newSub.SUB_Tech_Material__c =	'[{"Equipment_Id__c":"aaa111","Equipment_Type__c":"eqip 1","EQ_Decodeur__c":false,"EQ_Have_Decoder__c":false,"Id":"'+eq.Id+'","Equipment":"aaa111","Type":"eqip 1"}]';
        update newSub;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        string cancelSubResponse = BundleCSubscription.cancelBundleC (newSub.Id, 'test');
        //CBundleObjects.newSubResponse response =  (CBundleObjects.newSubResponse) JSON.deserialize(newSubResponse, CBundleObjects.newSubResponse.class);
        newSub = [SELECT Id, SUB_Subscription_Number__c, SUB_Status__c
                  FROM Zuora__Subscription__c
                  LIMIT 1];
        System.assertEquals('Cancelled', newSub.SUB_Status__c, 'C Bundle sub should be cancelled' );
        Test.stopTest();
    }
    @isTest
    public static void suspendBundleC_test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Account__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        string suspendSubResponse = BundleCSubscription.suspendBundleC (newSub.Id, 'for test', '2026-2-2');
        newSub = [SELECT Id, SUB_Subscription_Number__c, SUB_Status__c
                  FROM Zuora__Subscription__c
                  LIMIT 1];
        // System.assertEquals('Suspended', newSub.SUB_Status__c, 'C Bundle sub should be Suspended' );
        Test.stopTest();
    }
    @isTest
    public static void modifyOfferBundleC_test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Account__c, SUB_Offer__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        string modifySubResponse = BundleCSubscription.modifyOfferBundleC (newSub.Id, 'testOfferName', new list<string> {'TestOfferOption', 'Option2'});
        newSub = [SELECT Id, SUB_Subscription_Number__c, SUB_Status__c, SUB_Offer__c
                  FROM Zuora__Subscription__c
                  LIMIT 1];
        System.assertEquals('testOfferName', newSub.SUB_Offer__c, 'C Bundle sub should be Suspended' );
        Test.stopTest();
    }
    @isTest
    public static void exchangeMaterialInZuora_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Account__c, SUB_EquipmenId_CBundle__c, Zuora__Status__c,
                                             Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_EquipmentType_CBundle__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            zqu__ZProduct__c zProd = [SELECT Id, zqu__Product__c FROM zqu__ZProduct__c LIMIT 1];

            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            zqu__productrateplan__c newequip = TestUtils.createProductRatePlan('eqip 2',  zProd.Id, zProd.zqu__Product__c, '12344324', 'AddOn', 'Bundle C');
            insert newequip;
            zqu__ProductRatePlanCharge__c newEquipCharge = TestUtils.createPRPCharge(newequip.Id, 'eqip 2', '572525352752538585896983');
            insert newEquipCharge;

            Equipment__c eq = new Equipment__c();
            eq.Equipment_Id__c = 'aaa111';
            eq.Equipment_Type__c = 'eqip 1';
            eq.Country_Code__c = 'TG';

            Equipment__c eq2 = new Equipment__c();
            eq2.Equipment_Id__c = 'bbb222';
            eq2.Equipment_Type__c = 'eqip 2';
            eq2.Country_Code__c = 'TG';

            list<Equipment__c> listOfEquipment = new list<Equipment__c> {eq, eq2};
            insert listOfEquipment;
            newSub.SUB_EquipmenId_CBundle__c = 'aaa111';
            newSub.SUB_EquipmentType_CBundle__c = 'eqip 1';
            newSub.Zuora__Status__c = 'Active';
            update newSub;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new ZuoraMock());
            BundleCSubscription.getEquipmentList (newSub.Id, 'false', null);
            BundleCSubscription.getEquipmentList (newSub.Id, 'false', 'MATTOT');
            BundleCSubscription.getEquipmentList (newSub.Id, 'false', 'TERMG11A');
            string exchangeMaterialBundleC = BundleCSubscription.changeMaterialInZuora(newSub.Id, false, 'Cash', null, null, null, null, null, null, 'eqip 2');
            Test.stopTest();
        }
    }
    @isTest
    public static void exchangeMaterialBundleC_test(){
        user togoAdminUser = [SELECT id FROM User WHERE countryCode = 'TG' AND USR_DistributeurId__c =:system.label.Distributor_Id LIMIT 1 ];
        System.runAs(togoAdminUser){
            Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Account__c, SUB_EquipmenId_CBundle__c,
                                             Zuora__CustomerAccount__r.Zuora__AccountNumber__c, SUB_EquipmentType_CBundle__c
                                             FROM Zuora__Subscription__c
                                             LIMIT 1];

            Zuora__Product__c zpr = [SELECT Id FROM Zuora__Product__c LIMIT 1];
            zqu__ZProduct__c zProd = [SELECT Id, zqu__Product__c FROM zqu__ZProduct__c LIMIT 1];

            Zuora__SubscriptionProductCharge__c subProduct = TestUtils.createSubscriptionProduct(newSub.Id, newSub.Zuora__Account__c, 'Premium', zpr.Id, 'Premium');
            insert subProduct;

            zqu__productrateplan__c newequip = TestUtils.createProductRatePlan('eqip 2',  zProd.Id, zProd.zqu__Product__c, '12344324', 'AddOn', 'Bundle C');
            insert newequip;
            zqu__ProductRatePlanCharge__c newEquipCharge = TestUtils.createPRPCharge(newequip.Id, 'eqip 2', '572525352752538585896983');
            insert newEquipCharge;

            Equipment__c eq = new Equipment__c();
            eq.Equipment_Id__c = 'aaa111';
            eq.Equipment_Type__c = 'eqip 1';
            eq.Country_Code__c = 'TG';

            Equipment__c eq2 = new Equipment__c();
            eq2.Equipment_Id__c = 'bbb222';
            eq2.Equipment_Type__c = 'eqip 2';
            eq2.Country_Code__c = 'TG';

            list<Equipment__c> listOfEquipment = new list<Equipment__c> {eq, eq2};
            insert listOfEquipment;
            newSub.SUB_EquipmenId_CBundle__c = 'aaa111';
            newSub.SUB_EquipmentType_CBundle__c = 'eqip 1';
            newSub.SUB_Tech_Material__c = '[{"Equipment_Id__c":"aaa111","Equipment_Type__c":"eqip 1","EQ_Decodeur__c":false,"EQ_Have_Decoder__c":true,"Id":"'+eq.Id+'","Equipment":"aaa111","Type":"eqip 1"}]';
            update newSub;
            Test.startTest(); 
            Test.setMock(HttpCalloutMock.class, new CBundeMock());
            list<string> exchangeMaterialBundleC = BundleCSubscription.exchangeMaterialBundleC(newSub.Id, new list<String>{'bbb222'},new list<String>{'eqip 2'},new list<String>{eq2.id});
            newSub = [SELECT Id, SUB_Subscription_Number__c, SUB_Status__c, SUB_EquipmenId_CBundle__c
                      FROM Zuora__Subscription__c
                      LIMIT 1];
            System.assertEquals('bbb222', newSub.SUB_EquipmenId_CBundle__c, 'C Bundle sub should be Suspended' );
            Test.stopTest();
        }
    }
    @isTest
    public static void renewBundleCFromRenewFalse_test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Account__c, SUB_Offer__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        string renewSubResponse = BundleCSubscription.renewBundleC(newSub.Id, 1, 'offer', new list<string> {'option1', 'option2'}, false);
        newSub = [SELECT Id, SUB_Subscription_Number__c, SUB_Status__c, SUB_Offer__c
                  FROM Zuora__Subscription__c
                  LIMIT 1];
        //    System.assertEquals('testOfferName', newSub.SUB_Offer__c, 'C Bundle sub should be Suspended' );
        Test.stopTest();
    }
    @isTest
    public static void renewBundleCFromRenewTrue_test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Account__c, SUB_Offer__c, Zuora__CustomerAccount__r.Zuora__AccountNumber__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        string renewSubResponse = BundleCSubscription.renewBundleC(newSub.Id, 1, 'offer', new list<string> {'option1', 'option2'}, true);
        newSub = [SELECT Id, SUB_Subscription_Number__c, SUB_Status__c, SUB_Offer__c
                  FROM Zuora__Subscription__c
                  LIMIT 1];
        //    System.assertEquals('testOfferName', newSub.SUB_Offer__c, 'C Bundle sub should be Suspended' );
        Test.stopTest();
    }
    @isTest
    public static void activateCBundle_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_Activation_Date__c, SUB_Offer__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Date actDate = Date.valueOf('2022-10-10');
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        string activateBundleC = BundleCSubscription.activateCBundle(newSub.Id,  actDate);
        Test.stopTest();
        //System.assertEquals('Active', updatedSub.SUB_Status__c, 'C Bundle sub should be activated' );

    }

    @isTest
    public static void fastRenewBundleC_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_Activation_Date__c, SUB_Offer__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        string activateBundleC = BundleCSubscription.fastRenewBundleC (newSub.Id);
        Test.stopTest();
        //System.assertEquals('Active', updatedSub.SUB_Status__c, 'C Bundle sub should be renewed' );
    }

    @isTest
    public static void modifyContactsBundleC_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_Activation_Date__c, SUB_Offer__c, Zuora__Account__c, SUB_Status__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];

        Profile p = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client' OR Name = 'Utilisateur du Portail Client'];
        Account acc = [SELECT FirstName, RecordTypeId,personContactId, owner.name FROM account WHERE Id =: newSub.Zuora__Account__c];
        newSub.SUB_Status__c = 'Active';
        try {
            update newSub;
        } catch(Exception e) {
            system.debug('update sub error ' + e);
        }

        User usr = TestUtils.createUser('userTest@gva.com', 'Abi Nassif', 'jUserTest@GVA.com', '13234', p.Id);
        usr.ContactId = acc.personContactId;
        usr.mobilePhone = '12345677';
        try {
            insert usr;
        } catch (Exception e) {
            system.debug('error on user insert '+e.getMessage());
        }
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        acc.firstName = 'jackie AN';
        acc.lastName = 'lastname';
        acc.Phone = '123234337';
        try {
            update acc;
        } catch(Exception e) {
            system.debug('update acc error ' + e);
        }
        Test.stopTest();
        //System.assertEquals('Active', updatedSub.SUB_Status__c, 'C Bundle sub should be renewed' );
    }
    
    @isTest
    public static void SaveEquopementAndUserCanSee_Test(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, SUB_Activation_Date__c, Zuora__Account__c, SUB_Status__c,SUB_Tech_Material__c,
                                            SUB_Offer__c, SUB_Options__c, CBundle_Periode__c, Prior_expedted_renewal_Date__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];

        Account acc = [SELECT FirstName FROM account WHERE Id =: newSub.Zuora__Account__c];
        acc.FirstName = 'ChangeUsername';
        update acc;
        newSub.SUB_Status__c = 'Active';
        try {
            update newSub;
        } catch(Exception e) {
            system.debug('update sub error ' + e);
        }
        Test.startTest();
        BundleCSubscription.saveEquipementValue(newSub.Id, '[Equipement]', '[Options]', '[Offer]', 1);
        Boolean bool = BundleCSubscription.userCanSee();

        Zuora__Subscription__c updatedSub = [SELECT Id, Name, SUB_Activation_Date__c, Zuora__Account__c, SUB_Status__c,SUB_Tech_Material__c,
                                            SUB_Offer__c, SUB_Options__c, CBundle_Periode__c, Prior_expedted_renewal_Date__c
                                        FROM Zuora__Subscription__c
                                        LIMIT 1];
        Test.stopTest();
        System.assertEquals(true, bool, 'Administrator User can see Bundle options');
        System.assertEquals(1, updatedSub.CBundle_Periode__c, 'subscription fields updated');
    }

    @isTest
    public static void DeleteQuote(){

        String message;
        Quote quote = [SELECT Id, Status, QUO_Tech_Material__c, Pricebook2Id
                        FROM Quote LIMIT 1];

        PricebookEntry prB = [SELECT Id
                                FROM PricebookEntry WHERE Pricebook2Id = :quote.Pricebook2Id LIMIT 1];
        zqu__ProductRatePlan__c prp = [SELECT Id
                                    FROM zqu__ProductRatePlan__c LIMIT 1];
        Product2 pId =[SELECT Id
                        FROM Product2 LIMIT 1];

        Equipment__c eq = new Equipment__c();
        eq.Equipment_Id__c = 'aaa111';
        eq.Equipment_Type__c = 'eqip 1';
        eq.Country_Code__c = 'TG';
        eq.Already_Used__c = true;
        insert eq;
        QuoteLineItem QLI = TestUtils.createQuoteLineItem(quote.Id, pId.Id, prp.Id, prB.Id);
        insert QLI;
        Test.startTest();
        quote.Status = 'Accepted';
        quote.QUO_Mode_de_paiement__c = 'Cash';
        quote.QUO_Periodes_Prepayees__c = '1';
        quote.QUO_Grand_Total__c = 200;
        quote.QUO_SommeEncaissee__c = true;
        quote.QUO_TECH_Nombre_De_Produits__c  = 1;
        quote.QUO_Tech_Material__c = '[{"Equipment_Id__c":"aaa111","Equipment_Type__c":"eqip 1","EQ_Decodeur__c":false,"EQ_Have_Decoder__c":false,"Id":"'+eq.Id+'","Equipment":"aaa111","Type":"eqip 1"}]';
        update quote;
        try {
            delete quote;
        } catch (Exception e) {
            message = e.getmessage();
        }
        System.assertEquals(true, message.contains('can\'t be deleted having an active subscription'), 'subscription fields updated');

        quote.Status = 'Denied';
        update quote;
        delete quote;
        Test.stopTest();
        Equipment__c checkEquip = [SELECT Equipment_Id__c, Already_Used__c
                            FROM Equipment__c WHERE Equipment_Id__c = 'aaa111' LIMIT 1];
        System.assertEquals(false, checkEquip.Already_Used__c, 'subscription fields updated');
    }

    @isTest
    public static void eligmigration_Test(){

        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Status__c, Zuora__Account__c, SUB_Status__c,SUB_Tech_Material__c, SUB_Bundle_Contract_Id__c,
                                            SUB_Offer__c, SUB_Options__c, CBundle_Periode__c, Prior_expedted_renewal_Date__c, SUB_EquipmenId_CBundle__c
                                        FROM Zuora__Subscription__c
                                        LIMIT 1];

        list<String> listOfEquipId = new list<String>{'aaa111'};
        list<String> listOfSubId = new list<String>{newSub.Id};

        Equipment__c eq = new Equipment__c();
        eq.Equipment_Id__c = 'aaa111';
        eq.Equipment_Type__c = 'eqip 1';
        eq.Country_Code__c = 'TG';
        eq.Already_Used__c = true;
        insert eq;

        newSub.Zuora__Status__c = 'Active'; 
        newSub.SUB_EquipmenId_CBundle__c = 'aaa111';
        newSub.SUB_Bundle_Contract_Id__c = '12345';
        newSub.SUB_Status__c = 'Active';
        update newSub;
        
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        Test.startTest();

        BundleCSubscription.EligMigrationTest(null, listOfEquipId, null);

        Test.stopTest();
    }

    @isTest
    public static void migration_Test(){

        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Status__c, Zuora__Account__c, SUB_Status__c,SUB_Tech_Material__c, SUB_Bundle_Contract_Id__c,
                                            SUB_Offer__c, SUB_Options__c, CBundle_Periode__c, Prior_expedted_renewal_Date__c, SUB_EquipmenId_CBundle__c
                                        FROM Zuora__Subscription__c
                                        LIMIT 1];

        list<String> listOfEquipId = new list<String>{'aaa111'};
        list<String> listOfSubId = new list<String>{newSub.Id};

        Equipment__c eq = new Equipment__c();
        eq.Equipment_Id__c = 'aaa111';
        eq.Equipment_Type__c = 'eqip 1';
        eq.Country_Code__c = 'TG';
        eq.Already_Used__c = true;
        insert eq;

        newSub.Zuora__Status__c = 'Active'; 
        update newSub;
        
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        Test.startTest();

        BundleCSubscription.requestMigration(listOfSubId,'1', '62GVAAC|ACDD', true, '"[]"', 'aaa111', 'type');

        Zuora__Subscription__c updatedSub = [SELECT Id, Name, SUB_Activation_Date__c, Zuora__Account__c, SUB_Status__c,SUB_Tech_Material__c,
                                                SUB_Offer__c, SUB_Options__c, CBundle_Periode__c, Prior_expedted_renewal_Date__c,C_Migration_Date__c
                                            FROM Zuora__Subscription__c
                                            LIMIT 1];
       system.debug('mig date > '+updatedSub.C_Migration_Date__c);
        System.assertEquals(true, updatedSub.C_Migration_Date__c != null, 'date de migration ajouter');

        Test.stopTest();
    }

    @isTest
    public static void cancelMigration_Test(){

        Zuora__Subscription__c newSub = [SELECT Id, Name, Zuora__Status__c, Zuora__Account__c, SUB_Status__c,SUB_Tech_Material__c, SUB_Bundle_Contract_Id__c,
                                            SUB_Offer__c, SUB_Options__c, CBundle_Periode__c, Prior_expedted_renewal_Date__c, SUB_EquipmenId_CBundle__c
                                        FROM Zuora__Subscription__c
                                        LIMIT 1];

        list<String> listOfEquipId = new list<String>{'aaa111'};
        list<String> listOfSubId = new list<String>{newSub.Id};

        Equipment__c eq = new Equipment__c();
        eq.Equipment_Id__c = 'aaa111';
        eq.Equipment_Type__c = 'eqip 1';
        eq.Country_Code__c = 'TG';
        eq.Already_Used__c = true;
        insert eq;

        newSub.Zuora__Status__c = 'Active'; 
        newSub.SUB_EquipmenId_CBundle__c = 'aaa111';
        newSub.SUB_Bundle_Contract_Id__c = '12345';
        newSub.SUB_Status__c = 'Active';
        newSub.C_Migration_Date__c = datetime.valueof('2023-12-12 00:00:00');
        newSub.Sub_CanalMigration_orderId__c = '123';
        update newSub;
        
        Test.setMock(HttpCalloutMock.class, new CBundeMock());
        Test.startTest();
        
        BundleCSubscription.cancelCanalMigration(listOfSubId);

        Zuora__Subscription__c updatedSubAgain = [SELECT Id, Name, SUB_Activation_Date__c, Zuora__Account__c, SUB_Status__c,SUB_Tech_Material__c,
                                                SUB_Offer__c, SUB_Options__c, CBundle_Periode__c, Prior_expedted_renewal_Date__c,C_Migration_Date__c
                                                FROM Zuora__Subscription__c
                                                LIMIT 1];
        System.assertEquals(false, updatedSubAgain.C_Migration_Date__c != null, 'date de migration effacer');

        Test.stopTest();
    }

}