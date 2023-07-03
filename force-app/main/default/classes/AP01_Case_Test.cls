@isTest
public class AP01_Case_Test {

    // your current User pays should be Rwanda
    @isTest(SeeAllData = true)
    public static void categUpdateTriggerHandler_Test() {

        Test.setMock(HttpCalloutMock.class, new EligMock());
        User rwAdminUser = TestDataFactory.createAdminUser('RW');
        insert(rwAdminUser);
        System.runAs(rwAdminUser){
            id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
            Account acc = new Account ( firstName = 'jackie', lastName = 'abi nassif', ACC_BuildingID__c = 'KIG_12343', ACC_LatLong__Latitude__s = 2, ACC_Eligible__c = false,
                                        ACC_LatLong__Longitude__s = 1.2, ACC_NumeroDEtage__c = 2, PersonMobilePhone = '+36963', phone = '+01212121', ACC_PresencePTO_cc__c = 'non',
                                        ACC_MaturiteProspect__c = 'Chaud', ACC_CategorisationProspect__c = 'prix', BillingCountry = 'Burkina Faso', BillingCountryCode = 'BF',
                                        CurrencyIsoCode = 'XOF', recordtypeId = personAccountId, PersonEmail = 'example@test.com', ACC_Escalier__c = 'Esc-12', ACC_Indicatif__c = '+228');
            try {
                insert acc;
            } catch(Exception e) {
                system.debug('insert acc exception ' + e);
            }

            Case cs1 = new Case(AccountId = acc.Id, Status = 'CAS_Nouvelle', Type = 'Modification d\'abonnement', CAS_Motif_De_La_Requete__c = 'Déménagement');
            try {
                insert cs1;
            } catch(Exception e) {
                system.debug('insert cs1 exception ' + e);
            }

            cs1.CAS_Categorie1__c = 'SI';
            cs1.CAS_Categorie2__c = 'Service now';
            cs1.CAS_Categorie3__c = 'ServiceNowKO';
            Test.startTest();
            try {
                update cs1;
                system.debug('update ' + cs1);
            } catch(Exception e) {
                system.debug('update cs1 exception1 ' + e);
            }
            list<Case> css = [SELECT CAS_Impact__c, OwnerId, Owner.Name, CAS_Categorie1__c, CAS_Categorie2__c, CAS_Categorie3__c FROM Case WHERE Id =: cs1.Id];

            System.assertEquals('ImpactMineur', css[0].CAS_Impact__c, 'impact not updated 1');
            System.assertEquals('Exploitation SI', css[0].Owner.Name, 'Owner not updated 1');

            cs1.CAS_Categorie1__c = 'Installation';
            cs1.CAS_Categorie2__c = 'InstallationKO';
            cs1.CAS_Categorie3__c = null;

            try {
                update cs1;
            } catch(Exception e) {
                system.debug('update cs1 exception2 ' + e);
            }
            list<Case> css2 = [SELECT CAS_Impact__c, OwnerId, Owner.Name FROM Case WHERE Id =: cs1.Id];
            System.assertEquals('ParcoursDActivation', css2[0].CAS_Impact__c, 'impact not updated 2');
            System.assertEquals('Installation Client RW', css2[0].Owner.Name, 'Owner not updated 2');
            Test.stopTest();
        }
    }

    @isTest
    public static void caseComponent_Test(){

        //add Zuora Mock and Eligibility Mock to MultiMock class
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

        id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
        try {
            TestUtils.createSub();
        } catch(Exception e) {
            system.debug('create sub error ' + e);
        }
        Account acc = [SELECT id FROM Account WHERE firstName = 'TEST'];
        acc.BillingCountryCode = 'BF';
        try {
            update acc;
        } catch(Exception e) {
            system.debug('update account error ' + e);
        }
        Zuora__Subscription__c subs = [SELECT id, Zuora__Account__c, Name, Zuora__SubscriptionNumber__c, isCollaborator__c,
                                       Zuora__Status__c, Type__c, SUB_T_Produit_De_Base__c, Zuora__Account__r.BillingCountryCode
                                       FROM Zuora__Subscription__c
                                       WHERE Zuora__SubscriptionNumber__c = 'A-S00000400'];
        subs.Zuora__Status__c =  'Active';
        subs.SUB_T_Produit_De_Base__c = 'Start';
        try {
            update subs;
        } catch(Exception e) {
            system.debug('update sub error ' + e);
        }

        coupon__c coupon = new coupon__c();
        coupon.COU_Amount__c = '1500 XOF';
        coupon.COU_Country__c = 'BF';
        coupon.COU_Offer__c  = 'Start';
        try {
            insert coupon;
        } catch(Exception e) {
            system.debug('insert copon error ' + e);
        }

        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        Test.startTest();
        list<Zuora__Subscription__c> listOfSub = AP01_Case.getListSub(subs.Name, acc.Id);
        System.assertEquals(true, listOfSub.size() > 0, 'return a subscription');
        list<string> listOfCoupons = AP01_Case.getCoupons(acc.Id, listOfSub[0].Id);
        System.assertEquals(true, listOfCoupons.size() > 0, 'return a coupon');
        list<string> listOfCoupons2 = AP01_Case.getCoupons(null, listOfSub[0].Id);
        System.assertEquals(true, listOfCoupons2.size() > 0, 'return a coupon');
        Case cs = AP01_Case.insertCase(acc.Id, listOfSub[0].Id, 'CAS_Nouvelle', 'Dédommagement', '', 'Dedomagement', 'Réclamation', '', '', null, '1500 XOF');
        System.assertEquals('1500 XOF', cs.CAS_Coupon__c, 'case created');
        Test.stopTest();
    }
}