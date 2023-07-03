@isTest
public with sharing class MonCompteController_Test {

    @TestSetup
    private static void makeData() {
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
            Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
            endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
            endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
            endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
            HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);

            Account acc = TestDataFactory.createPersonAccount('test', 'TG');
            acc.personMobilePhone = '0673994428';
            insert acc;
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription;
            List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c> {zuoraSubscription};
            CreateUserHandler.createCommunityUser(zuoraSubscriptions);
        }
    }

    @isTest
    private static void shouldCallGetMonCompteSummaryData(){
        User user = [SELECT Id FROM User WHERE Username = '2280673994428@canalbox.com'].get(0);
        System.runAs(user){
            Test.startTest();
            MonCompteController.MonCompteWrapperResponse monCompteWrapperResponse =  MonCompteController.getMonCompteSummaryData(user.Id);
            Test.stopTest();
            System.assertNotEquals(null, monCompteWrapperResponse, 'MonCompteWrapperResponse should not be null');
        }
    }

    @isTest
    private static void shouldChangeUserPassword(){
        User user = [SELECT Id FROM User WHERE Username = '2280673994428@canalbox.com'].get(0);
        System.setPassword(user.Id, 'a1234567');
        System.runas(user){
            Test.startTest();
            String result =  MonCompteController.changePassword('a1234567', 'abcd56av', 'abcd56av');
            Test.stopTest();
            System.assertEquals('erreur', result, 'Change password should return erreur');
        }
    }

}