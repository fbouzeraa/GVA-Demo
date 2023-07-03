@isTest
public with sharing class Batch10_SendWelcomeSmsToPortalUser_Test {
    

    @TestSetup
    static void makeData(){
        Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
        User burkinaFasoAdminUser = TestDataFactory.createAdminUser('BF');
     
        insert(burkinaFasoAdminUser);

        System.runAs(burkinaFasoAdminUser){
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
            endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
            endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
            HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
            Test.setMock(HttpCalloutMock.class, multiCalloutMock); 

            Account acc = TestDataFactory.createPersonAccount('test23','BF');
            acc.personMobilePhone = '0679994429';
            insert acc;
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription; // The user is created whn subcription is inserted
        }
    }

    @isTest
    public static void shouldSendAnSmsToBurkinaFasoClientPortalProfile(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
        Account acc = TestDataFactory.createPersonAccount('test','BF');
           acc.personMobilePhone = '0679994428';
           insert acc;
        List<Id> accountIds = new List<Id>{acc.Id};
        Test.startTest();
             Batch10_SendWelcomeSmsToPortalUser sendWelcomeSmsToClientPortalUser = new Batch10_SendWelcomeSmsToPortalUser(accountIds,'BF');
             Id batchId = Database.executeBatch(sendWelcomeSmsToClientPortalUser,200);
         Test.stopTest();

    }    
    
}