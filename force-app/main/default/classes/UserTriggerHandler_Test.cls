@isTest
public with sharing class UserTriggerHandler_Test {

    @TestSetup
    static void makeData(){
        
    }	

    private static HttpCalloutMock getMultimockCallOut(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
          endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
          endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
          endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
          HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
          return  multiCalloutMock;
      }

    @isTest
    public static void shouldSendAnSmsWithPasswordAndLoginLinkToANewUtilisateurDuPortailClientUsers() {
        User adminUser = TestDataFactory.createAdminUser('TG');
        insert adminUser;
        System.runAs(adminUser){
            User togoClientPortalUser = TestDataFactory.createClientPortalUser(adminUser, 'TG');
            togoClientPortalUser.Phone = '+33 0687589874';
            insert togoClientPortalUser;

            Test.startTest();
                Test.setMock(HttpCalloutMock.class, new SMSMock());
            	Set<Id> setDeId = new Set<Id>();
        		setDeId.add(togoClientPortalUser.Id);
            	UserTriggerHandler.allMySmsBulkCallout(setDeId);
                UserTriggerHandler.sendNewPasswordBySmsToUser(togoClientPortalUser.Id);
            Test.stopTest();
        }
    }

    @isTest
    public static void shouldNotSendAnSmsToNotUtilisateurDuProfileClientUser() {
        User adminUser = TestDataFactory.createAdminUser('TG');
        insert(adminUser);
        
            Test.startTest();
                Test.setMock(HttpCalloutMock.class, new SMSMock());
                UserTriggerHandler.sendNewPasswordBySmsToUser(adminUser.Id);
            Test.stopTest();
       
    }


    @isTest
    public static void shouldSendAWelcomeSMSToAListOfUtilisateurDuPortailClientUsers() {
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
          Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
         HttpCalloutMock multiCalloutMock = getMultimockCallOut();
         Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
          Test.startTest();
              Account acc1 = TestDataFactory.createPersonAccount('test','TG');
              acc1.personMobilePhone = '0673994428';
              insert acc1;
              User togoClientPortalUser1 = TestDataFactory.createClientPortalUser(acc1, 'TG');
              togoClientPortalUser1.FirstName = 'MyFirstName';
              togoClientPortalUser1.Phone = '+33 0687589874';
              insert togoClientPortalUser1;
             List<User> users = new List<User>{togoClientPortalUser1};
                UserTriggerHandler.sendWelcomeSmsToClientPortalUsers(users);
        Test.stopTest();
         }
    }


    @isTest
    public static void shouldSendAWelcomeSMSToAListOfTwoUtilisateurDuPortailClientUsers() {
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
          Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
         HttpCalloutMock multiCalloutMock = getMultimockCallOut();
         Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
          Test.startTest();
              Account acc1 = TestDataFactory.createPersonAccount('test','TG');
              acc1.personMobilePhone = '0673994428';
              insert acc1;
              User user1 = TestDataFactory.createClientPortalUser(acc1, 'TG');
              user1.FirstName = 'firstName1';
              user1.Phone = '+33 0687589874';
              insert user1;

              Account acc2 = TestDataFactory.createPersonAccount('test2','TG');
              acc2.personMobilePhone = '0673994428';
              insert acc2;
              User user2 = TestDataFactory.createClientPortalUser(acc2, 'TG');
              user2.FirstName = 'firstName2';
              user2.Phone = '+33 0687589875';
              user2.userName = 'user2@test.com';
              insert user2;

             List<User> users = new List<User>{user1, user2};
            UserTriggerHandler.sendWelcomeSmsToClientPortalUsers(users);
        Test.stopTest();
         }
    }

    @isTest
    public static void shouldSendAWelcomeSMSIfUserObjectAsNotProfileInTheObject() {
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
          Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
         HttpCalloutMock multiCalloutMock = getMultimockCallOut();
         Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
          Test.startTest();
              Account acc1 = TestDataFactory.createPersonAccount('test','TG');
              acc1.personMobilePhone = '0673994428';
              insert acc1;
              User togoClientPortalUser1 = TestDataFactory.createClientPortalUser(acc1, 'TG');
              togoClientPortalUser1.FirstName = 'MyFirstName';
              togoClientPortalUser1.Phone = '+33 0687589874';
              insert togoClientPortalUser1;
              List<User> users = [SELECT Id FROM User WHERE Username = 'TG.client.portal.user@testorg.com'];
             System.debug('users : ' + users);
              // List<User> users = new List<User>{togoClientPortalUser1};
                UserTriggerHandler.sendWelcomeSmsToClientPortalUsers(users);
            Test.stopTest();
         }
    }

    

}