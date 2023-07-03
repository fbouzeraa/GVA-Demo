@isTest
public with sharing class Batch08_SuiviGVAdmin_Test {

    @isTest
    public static void updateStatus_SuiviGVAdmin_Test() {

        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));

        List<Suivi_de_Souscription__c> listOfSuiviToInsert = new List<Suivi_de_Souscription__c>();

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système'];
        // user myTestUser1 = TestUtils.createUser('example1@test.com', 'lastName1', 'j.abinassif@gva.africa', 'USER123', p.Id);
        //insert myTestUser1;
        Account acc = TestUtils.createPersonAccount('jackie');
        Account acc2 = TestUtils.createPersonAccount('jackie2');
        Account acc3 = TestUtils.createPersonAccount('jackie3');
        list<Account> listOfAccounts = new list<Account> {acc, acc2, acc3};
        insert listOfAccounts;
        String priceBookId = TestUtils.createPriceBook();
        Opportunity opp = TestUtils.createOpportunity('oppName', acc.Id, priceBookId);
        Opportunity opp2 = TestUtils.createOpportunity('oppName2ww', acc2.Id, priceBookId);
        Opportunity opp3 = TestUtils.createOpportunity('oppName3ww', acc3.Id, priceBookId);
        list<Opportunity> listOfOpportunity = new list<Opportunity> {opp, opp2, opp3};
        insert listOfOpportunity;
        Quote qut = TestUtils.createQuote(opp.Id, 'quoteName', priceBookId);
        Quote qut2 = TestUtils.createQuote(opp2.Id, 'quoteName2ww', priceBookId);
        Quote qut3 = TestUtils.createQuote(opp3.Id, 'quoteName3ww', priceBookId);
        list<Quote> listOfQuotes = new list<Quote> {qut, qut2, qut3};
        insert listOfQuotes;
        Zuora__CustomerAccount__c zAcc = TestUtils.createCustomerAccount('jackie', acc.Id, '0123');
        Zuora__CustomerAccount__c zAcc2 = TestUtils.createCustomerAccount('jackie2ww', acc2.Id, '0124');
        Zuora__CustomerAccount__c zAcc3 = TestUtils.createCustomerAccount('jackie3ww', acc3.Id, '0125');
        list<Zuora__CustomerAccount__c> listOfzAcc = new list<Zuora__CustomerAccount__c> {zAcc, zAcc2, zAcc3};
        insert listOfzAcc;
        Zuora__Subscription__c subsc1 = TestUtils.createSubscription(acc.Id, qut.Id, zAcc.Id, 'A-S00000400');
        Zuora__Subscription__c subsc2 = TestUtils.createSubscription(acc2.Id, qut2.Id, zAcc2.Id, 'A-S00000401');
        Zuora__Subscription__c subsc3 = TestUtils.createSubscription(acc3.Id, qut3.Id, zAcc3.Id, 'A-S00000402');
        list<Zuora__Subscription__c> listOfSubsToInsert = new list<Zuora__Subscription__c> {subsc1, subsc2, subsc3};
        system.debug('listOfSubsToInsert ' + listOfSubsToInsert);
        try {
            insert listOfSubsToInsert;
        } catch(Exception e) {
            system.debug('insert subs excep. ' + e);
        }

        Suivi_de_Souscription__c suivi1 = new Suivi_de_Souscription__c();
        suivi1.SV_Reference_Externe__c = '2021090200012-R0';
        suivi1.SV_Statut__c = 'STA002';
        suivi1.SV_Id_Souscription__c = subsc1.Id;
        suivi1.SV_T_GVAStatusKO__c = true;
        listOfSuiviToInsert.add(suivi1);

        Suivi_de_Souscription__c suivi2 = new Suivi_de_Souscription__c();
        suivi2.SV_Reference_Externe__c = '2021042902497';
        suivi2.SV_Statut__c = 'STA002';
        suivi2.SV_Id_Souscription__c = subsc2.Id;
        suivi2.SV_T_GVAStatusKO__c = true;
        listOfSuiviToInsert.add(suivi2);

        Suivi_de_Souscription__c suivi3 = new Suivi_de_Souscription__c();
        suivi3.SV_Reference_Externe__c = 'ref_a1l1l000000zhebAAA';
        suivi3.SV_Statut__c = 'STA002';
        suivi3.SV_Id_Souscription__c = subsc3.Id;
        suivi3.SV_T_GVAStatusKO__c = true;
        listOfSuiviToInsert.add(suivi3);

        system.debug('listOfSuiviToInsert ' + listOfSuiviToInsert);
        try {
            insert listOfSuiviToInsert;
        } catch(Exception e) {
            system.debug('insert error ' + e);
        }

        Test.startTest();
        BatchScheduler_SuiviGVAdmin sch = new BatchScheduler_SuiviGVAdmin();
        System.schedule('Test', '0 0 4 ? * * *', sch);
        Database.executeBatch(new Batch08_SuiviGVAdmin(), 10);
        Test.stopTest();

        list<Suivi_de_Souscription__c> Suivi = [Select Id, SV_T_GVAStatusKO__c
                                                From Suivi_de_Souscription__c
                                                WHERE SV_T_GVAStatusKO__c = true];

        system.assertEquals(3, Suivi.size(), '3 suivi with checkbox = true');
        list<Zuora__Subscription__c> Sub = [Select Id From Zuora__Subscription__c LIMIT 1];

        // system.assertEquals('KO', Sub[0].SUB_Statut_GVAdmin__c, 'Status add to subscription field');
    }
}