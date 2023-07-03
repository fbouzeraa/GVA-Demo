@isTest
public with sharing class Batch09_CreateUserFromPersonAccount_Test {

    @TestSetup
    static void makeData(){

        User burkinaFasoAdminUser = TestDataFactory.createAdminUser('BF');
        burkinaFasoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler'; // Bypass trigger create useer
        burkinaFasoAdminUser.userName = 'bf.test.admin.user@mail.fr';
        insert(burkinaFasoAdminUser);

        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler'; // Bypass trigger
        togoAdminUser.userName = 'tg.test.admin.user@mail.fr';
        insert(togoAdminUser);
    }

    @isTest
    public static void shouldCreateAUserFromThePersonAccount() {
        Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);

        User burkinaFasoAdminUser = [SELECT Id FROM USER WHERE UserName = 'bf.test.admin.user@mail.fr' LIMIT 1];
        System.runAs(burkinaFasoAdminUser){
           
           Test.setMock(HttpCalloutMock.class,  createMultiCalloutMock()); 

           Account acc = TestDataFactory.createPersonAccount('test','BF');
           acc.personMobilePhone = '0679994428';
           insert acc;
           Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
           insert zuoraSubscription; // The user is not created  here since  burkinaFasoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler'; 

            List<Id> accountIds = new List<Id>{acc.Id};

            Test.startTest();
                Batch09_CreateUserFromPersonAccount createUserFromPersonAccount = new Batch09_CreateUserFromPersonAccount(accountIds, 'BF');
                Id batchId = Database.executeBatch(createUserFromPersonAccount,200);
            Test.stopTest();

            List<User> users = [SELECT Id, Username, ProfileId,Phone,MobilePhone FROM User WHERE Username = '2260679994428@canalbox.com'];
           // List<User> users = [SELECT Id, Username, ProfileId FROM User];
           System.debug('users : ' + users[0].Phone);
            System.debug('users : ' + users);
            System.assertEquals(1, users.size(), 'Should have created the user');
            System.assertEquals( '2260679994428@canalbox.com', users[0].username, 'The username should be : 226673994428@canalbox.com');
            System.assertEquals( clientPortalProfile.Id, users[0].profileId, 'The created user should be Utilisateur du portail client profile');
        }
    }

    @isTest
    public static void shouldNotCreateAUserIfPersonAccountDoesNotHaveASubcription() {
        Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
    
        User burkinaFasoAdminUser = TestDataFactory.createAdminUser('BF');
        burkinaFasoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler'; // Bypass trigger
        insert(burkinaFasoAdminUser);

        System.runAs(burkinaFasoAdminUser){

            Test.setMock(HttpCalloutMock.class,  createMultiCalloutMock()); 

            Account acc = TestDataFactory.createPersonAccount('Test2','BF');
            acc.personMobilePhone = '0679994429';
            insert acc;

            List<Id> accountIds = new List<Id>{acc.Id};

            Test.startTest();
                Batch09_CreateUserFromPersonAccount createUserFromPersonAccount = new Batch09_CreateUserFromPersonAccount(accountIds,'BF');
                System.debug('In shouldCreateAUserFromThePersonAccount startTest');
                Id batchId = Database.executeBatch(createUserFromPersonAccount,200);
            Test.stopTest();
            List<User> users2 = [SELECT Id, Username, ProfileId FROM User WHERE Username = '2260679994429@canalbox.com'];
            System.assertEquals(0, users2.size(), 'Should not have created the user where account does not have a subcritption');
        
        }
    }


    @isTest
    public static void shouldNotCreateAUserIfPersonAccountIsTogo() {
        User togoAdminUser = [SELECT Id FROM USER WHERE UserName = 'tg.test.admin.user@mail.fr' LIMIT 1];
        System.runAs(togoAdminUser){
            Test.setMock(HttpCalloutMock.class,  createMultiCalloutMock()); 

            Account acc = TestDataFactory.createPersonAccount('Test2','TG');
            acc.personMobilePhone = '0679994429';
            insert acc;
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription; 

            List<User> users2 = [SELECT Id, Username, ProfileId FROM User WHERE Username = '2280679994429@canalbox.com'];

            List<Id> accountIds = new List<Id>{acc.Id};

            Test.startTest();
                Batch09_CreateUserFromPersonAccount createUserFromPersonAccount = new Batch09_CreateUserFromPersonAccount(accountIds, 'BF');
                System.debug('In shouldCreateAUserFromThePersonAccount startTest');
                System.debug('accountIds : ' + accountIds);
                Id batchId = Database.executeBatch(createUserFromPersonAccount,200);
            Test.stopTest();

            List<User> users = [SELECT Id, Username, ProfileId FROM User WHERE Username = '2280679994429@canalbox.com'];
            System.assertEquals(0, users.size(), 'Should not have created the user where person account is Togo');
        
        }
    }



    @isTest
    public static void shouldNotCreateAUserIfItAlreadyExist() {
        Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
        User burkinaFasoAdminUser = TestDataFactory.createAdminUser('BF');
     
        insert(burkinaFasoAdminUser);
        System.runAs(burkinaFasoAdminUser){

            Test.setMock(HttpCalloutMock.class,  createMultiCalloutMock()); 

            Account acc = TestDataFactory.createPersonAccount('Test2','BF');
            acc.personMobilePhone = '0679994429';
            insert acc;
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription; // The user is created, no bypass

            List<Id> accountIds = new List<Id>{acc.Id};

            Test.startTest();
                Batch09_CreateUserFromPersonAccount createUserFromPersonAccount = new Batch09_CreateUserFromPersonAccount(accountIds, 'BF');
                System.debug('In shouldCreateAUserFromThePersonAccount startTest');
                Id batchId = Database.executeBatch(createUserFromPersonAccount,200);
            Test.stopTest();
            
            List<User> users = [SELECT Id, Username, ProfileId FROM User WHERE Username = '2260679994429@canalbox.com'];
            System.assertEquals(1, users.size(), 'Should not have created the user where person account is Togo');
        
        }
    }

    @isTest
    public static void shouldNotCreateAUserIfItAlreadyExistWithAnOtherUsernname() {

        User burkinaFasoAdminUser = [SELECT Id FROM USER WHERE UserName = 'bf.test.admin.user@mail.fr' LIMIT 1];
        System.runAs(burkinaFasoAdminUser){

            Test.setMock(HttpCalloutMock.class,  createMultiCalloutMock());  

            Account acc = TestDataFactory.createPersonAccount('Test2','BF');
            acc.personMobilePhone = '0679994429';
            insert acc;
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription; 
            User user = TestDataFactory.createClientPortalUser(acc, 'BF');
            insert user;

            List<Id> accountIds = new List<Id>{acc.Id};

            Test.startTest();
                System.debug('In shouldCreateAUserFromThePersonAccount startTest');
                Batch09_CreateUserFromPersonAccount createUserFromPersonAccount = new Batch09_CreateUserFromPersonAccount(accountIds, 'BF');
                Id batchId = Database.executeBatch(createUserFromPersonAccount,200);
            Test.stopTest();

            List<User> users1 = [SELECT Id, Username, ProfileId FROM User WHERE Username = 'BF.client.portal.user@testorg.com'];
            System.assertEquals(1, users1.size(), 'Should have created the user with Username BF.client.portal.user@testorg.com');
            List<User> users2 = [SELECT Id, Username, ProfileId FROM User WHERE Username = '2260679994429@canalbox.com'];
            System.assertEquals(0, users2.size(), 'Should not have created the user with Username 2260679994429@canalbox.com');
        
        }
    }

    public static MultiMock createMultiCalloutMock(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        return new MultiMock(endpoint2TestResp);
    }

}