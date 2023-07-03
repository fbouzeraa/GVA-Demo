/**
 * @author Jackie Abi NAssif
 * @date 27 avril 2022
 */

@isTest
public class AP02_Quote_TEST {

    @TestSetup
    static void dataSetUp(){
        String priceBookId = TestUtils.createPriceBook();
    }

    @isTest
    public static void AP_Quote_TEST() {
		User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
        Account accJ = TestUtils.createPersonAccount('accJackie');
        String priceBookId = [SELECT Id FROM Pricebook2 LIMIT 1].Id;
        try {
            insert accJ;
        } catch (Exception e) {
            system.debug('excep1 '+e);
        }
        Opportunity newOpp = 
            new Opportunity ( AccountId = accJ.Id, Name = 'myNewOpp', StageName = 'Négociation', CloseDate = Date.today(), priceBook2Id =priceBookId);
        try {
            insert newOpp;
        } catch (Exception e2) {
            system.debug('excep2 '+e2);
        }
        Quote oneQuote = new Quote(OpportunityId = newOpp.Id, Name = 'testQuote',Status = 'Draft');
        try {
            insert oneQuote;
        } catch (Exception e3) {
            system.debug('excep3 '+e3);
        }

        string  selectedFields = '[';
                selectedFields += '"' + oneQuote.id + '"]';

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EligMock());
        list<Quote> listOfQuotes = AP02_Quote.getRequestedQuotes();
        AP02_Quote.handleBulkActions(selectedFields, true);
        system.assertEquals(1, listOfQuotes.size(), 'number Of Quote');
        Test.stopTest();
        }}
    @isTest
    public static void addDateOfStatusUpdate_TEST(){
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
        
        Account accJ = TestUtils.createPersonAccount('accJackie');
        String priceBookId = [SELECT Id FROM Pricebook2 LIMIT 1].Id;
        try {
            insert accJ;
        } catch (Exception e) {
            system.debug('excep1 '+e);
        }
        Opportunity newOpp = 
            new Opportunity ( AccountId = accJ.Id, Name = 'myNewOpp', StageName = 'Négociation', CloseDate = Date.today(), priceBook2Id =priceBookId);
        try {
            insert newOpp;
        } catch (Exception e2) {
            system.debug('excep2 '+e2);
        }

        Quote newQuote = new Quote(OpportunityId = newOpp.Id, Name = 'testQuote',Status = 'Draft');

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EligMock());
        try {
            insert newQuote;
        } catch (Exception e) {
            system.debug('inset qote '+ e);
        }

        list<Quote> updatedQuote1 = [SELECT Id,Status,QUO_T_Status_Update_Date__c FROM Quote where Id= :newQuote.Id];
        system.assertEquals(system.today(),updatedQuote1[0].QUO_T_Status_Update_Date__c,'today\'s date field beacause status is Négociation');


        newQuote.Status = 'Needs Review';
        try {
            update newQuote;
        } catch (Exception ee) {
            system.debug('inset qote '+ ee);
        }

        list<Quote> updatedQuote2 = [SELECT Id,Status,QUO_T_Status_Update_Date__c FROM Quote where Id= :newQuote.Id];
        system.assertEquals(system.today(),updatedQuote2[0].QUO_T_Status_Update_Date__c,'today\'s date field beacause status is Needs Review');

        newQuote.Status = 'Accepted';
        newQuote.QUO_Mode_de_paiement__c = 'Cash';
        newQuote.QUO_Periodes_Prepayees__c = '1';
        newQuote.QUO_SommeEncaissee__c = true;
        newQuote.QUO_TECH_Nombre_De_Produits__c  = 2;
        newQuote.QUO_Grand_Total__c = 1200;
 
        try {
            update newQuote;
        } catch (Exception ee) {
            system.debug('inset qote '+ ee);
        }
        Test.stopTest();

        list<Quote> updatedQuote3 = [SELECT Id,Status,QUO_T_Status_Update_Date__c FROM Quote where Id= :newQuote.Id];
        system.assertEquals(null,updatedQuote3[0].QUO_T_Status_Update_Date__c,'null field beacause status is Accepted');
        }}
    @isTest
    public static void changeStatus_TEST(){
        //add Zuora Mock and Eligibility Mock to MultiMock class
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Account acc = TestUtils.createPersonAccount('jackyAcc');
        try {
            insert acc;
        } catch(Exception eACC) {
            system.debug('eACC ' + eACC);
        }
        String priceBookId = [SELECT Id FROM Pricebook2 LIMIT 1].Id;
        Opportunity opp = TestUtils.createOpportunity('oppName', acc.Id, priceBookId);
        try {
            insert opp;
        } catch(Exception eOpp) {
            system.debug('eOpp ' + eOpp);
        }
        Quote newQuote = new Quote (Name = 'quoteName2', OpportunityId = opp.Id, priceBook2Id = priceBookId,QUO_T_Account__c = acc.Id,
                                     QUO_Periodes_Prepayees__c = '2', QUO_T_Numero_De_Commande__c = 'O-0000100', QUO_PTO__c = 'PTO01', QUO_T_Numero_du_Box__c = 'ALCL:B3B9C31C');
        try {
            insert newQuote;
        } catch(Exception eQuote) {
            system.debug('eQuote ' + eQuote);
        }

        //Account theAccount0 = [SELECT Id, ACC_StatutCompte__c,ACC_T_SubStatus__c FROM Account WHERE Id =: acc.Id ];
        //System.assertEquals('Prospect argumenté', theAccount0.ACC_StatutCompte__c, 'FLW07_DevisB2C (2) update Account status');
        //FLW07_DevisB2C is a screen flow

        Zuora__CustomerAccount__c billigAcc = TestUtils.createCustomerAccount('TestAccount',acc.Id,'0123');
        try {
            insert billigAcc;
        } catch(Exception eZAccount) {
            system.debug('eZAccount ' + eZAccount);
        }
        Zuora__Subscription__c subs = TestUtils.createSubscription(acc.Id,newQuote.Id,billigAcc.Id,'A-S00000400');
        try {
            insert subs;
        } catch(Exception eSub) {
            system.debug('eSub ' + eSub);
        }
        system.debug('subscription AP02_quoteTest '+subs);
        Account theAccount = [SELECT Id, ACC_StatutCompte__c,ACC_T_SubStatus__c FROM Account WHERE Id =: acc.Id ];
        system.debug('jackieAccount '+theAccount);
        System.assertEquals('Client signé', theAccount.ACC_StatutCompte__c, 'AP01_Quote');
    //    System.assertEquals('Pending Activation', theAccount.ACC_T_SubStatus__c, 'FLW18_Acc_SUBStatus_Update');

        subs.Zuora__Status__c = 'Active';
        try {
            update subs;
            system.debug('jackie '+subs);
        } catch(Exception eSub) {
            system.debug('eSub on update ' + eSub);
        }

        Account theAccount2 = [SELECT Id, ACC_StatutCompte__c,ACC_T_SubStatus__c,ACC_T_ActiveSub__c FROM Account WHERE Id =: acc.Id ];
        system.debug('jackieAccount '+theAccount2);
        System.assertEquals('Client actif', theAccount2.ACC_StatutCompte__c, 'FLW18_Acc_SUBStatus_Update');
        System.assertEquals('Active', theAccount2.ACC_T_SubStatus__c, 'FLW18_Acc_SUBStatus_Update');
        System.assertEquals(true, theAccount2.ACC_T_ActiveSub__c, 'FLW18_Acc_SUBStatus_Update');


        }}
}