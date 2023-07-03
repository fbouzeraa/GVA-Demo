@isTest
public class QuoteTriggerTest {
 @isTest static void TestQuoteTriggerDelete() {
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
            Account acc = TestUtils.createPersonAccount('account test');
            insert acc;
            id pricebookId = TestUtils.createPriceBook();
            
			Opportunity opp = TestUtils.createOpportunity('opportunity test',acc.id,pricebookId);
            insert opp;
            Quote quoteTest = TestUtils.createQuote(opp.id,'quote name',pricebookId);
            insert quoteTest; 
            Quote qu = [Select Id,Name from Quote LIMIT 1];

            update qu;

        }

    }

}