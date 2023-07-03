@isTest
public with sharing class UserChangeEventTriggerHandler_Test {

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
            Account acc = TestDataFactory.createPersonAccount('test','TG');
            acc.personMobilePhone = '06799944284';
            insert acc;
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription; // The user is created  when insert a subsctription
            List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
            CreateUserHandler.createCommunityUser(zuoraSubscriptions);
        }
    }

    @isTest
    static void shouldUpdateTheEmailAccountIfTheCurrentUserConfirmEmail (){
         User user = [SELECT Id FROM User WHERE Username = '22806799944284@canalbox.com'].get(0);
         System.runAs(user){
            Test.enableChangeDataCapture();  
            Account account = [SELECT Id, PersonContactId, PersonEmail  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
            String oldAccountEmail = account.personEmail;
            account.personEmail = 'update.communityuser@gmail.com';
             Test.startTest();
                    update account;
                    Account accountUpdated = [SELECT Id, personEmail  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
                    System.assertEquals(oldAccountEmail, accountUpdated.personEmail, 'Should have not update the person email on the account at this point');
            Test.stopTest();
            //Test.getEventBus().deliver();
                accountUpdated = [SELECT Id, personEmail  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
                System.assertEquals('update.communityuser@gmail.com', accountUpdated.personEmail, 'Should have update the person email on the account');
        }
     }

}