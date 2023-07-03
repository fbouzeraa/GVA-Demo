@isTest
public with sharing class CreateCommunityUserController_Test {

    // @TestSetup
    // static void makeData(){
    //     User adminUser = TestDataFactory.createAdminUser('TG');
    //     insert(adminUser);
    //     System.runAs(adminUser){
    //         Account personAccount = TestDataFactory.createPersonAccount(adminUser, 'TG');
    //         personAccount.ACC_Indicatif__c = '+33';
    //         personAccount.Phone = '0123456784';
    //         insert personAccount;
    //     }
    // }

    private static HttpCalloutMock getMultimockCallOut(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
          endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
          endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
          endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
          HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
          return  multiCalloutMock;
      }
    
    @isTest static void shouldCreateACommunityUser(){    
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
            HttpCalloutMock multiCalloutMock = getMultimockCallOut();
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            
            Account acc = TestDataFactory.createPersonAccount('test','TG');
            acc.personMobilePhone = '0673994428';
            insert acc;  
            System.debug('acc :' + acc);
            System.debug('acc.PersonContactId :' + acc.PersonContactId);
            //AccountNew is the Visualforce page created
            // PageReference testPage = Page.CreateCommunityUser; 
            // Test.setCurrentPage(testPage);
            // testPage.getParameters().put('Id', String.valueOf(acc.Id));
            
            ApexPages.StandardController sc = new  ApexPages.StandardController(acc);     
            CreateCommunityUserController createCommunityUserController = new CreateCommunityUserController(sc);         
            Test.startTest();
                createCommunityUserController.createCommunityUser();
            Test.stopTest();
            List<User> users = [SELECT Id, Username, ProfileId, UserRoleId FROM User WHERE Username = '2280673994428@canalbox.com'];
            System.assertEquals(1, users.size(), 'Should have created the user');
            System.assertEquals( '2280673994428@canalbox.com', users[0].username, 'The username should be : 2280673994428@canalbox.com');
            System.assertEquals(null, users[0].UserRoleId, 'The user created should have UserRoleId set to null');
        } 
    }

    
    @isTest static void shouldNotCreateAcommunityUserIfTheUserAlreadyExist(){    
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
            HttpCalloutMock multiCalloutMock = getMultimockCallOut();
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            Account acc = TestDataFactory.createPersonAccount('test','TG');
            acc.personMobilePhone = '0673994428';
            insert acc;  
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription;  // The user is created when insert a subcription
            List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
            CreateUserHandler.createCommunityUser(zuoraSubscriptions);

            List<User> users = [SELECT Id, Username, ProfileId, UserRoleId FROM User WHERE Username = '2280673994428@canalbox.com'];
            System.assertEquals(1, users.size(), 'Should have created the user at this point');

            ApexPages.StandardController sc = new  ApexPages.StandardController(acc);     
            CreateCommunityUserController createCommunityUserController = new CreateCommunityUserController(sc);         
            Test.startTest();
                createCommunityUserController.createCommunityUser();
            Test.stopTest();
            // List<User> users = [SELECT Id, Username, ProfileId, UserRoleId FROM User WHERE Username = '228673994428@canalbox.com'];
            // System.assertEquals(1, users.size(), 'Should have created the user');
            // System.assertEquals( '228673994428@canalbox.com', users[0].username, 'The username should be : 228673994428@canalbox.com');
            // System.assertEquals(null, users[0].UserRoleId, 'The user created should have UserRoleId set to null');
        } 
    }


    
    @isTest static void shouldUpdateTheUserBySetIsActiveToTrueIfTheCommunityUserExistAndIsInactive(){    
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
            HttpCalloutMock multiCalloutMock = getMultimockCallOut();
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            Account acc = TestDataFactory.createPersonAccount('test','TG');
            acc.personMobilePhone = '0673994428';
            insert acc;  
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription;  // The user is created when insert a subcription
             List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
            CreateUserHandler.createCommunityUser(zuoraSubscriptions);

            List<User> users = [SELECT Id, IsActive FROM User WHERE Username = '2280673994428@canalbox.com'];
            User user = users[0];
            user.IsActive = false;
            update user;
            System.assertEquals(false, user.IsActive, 'Should have desactivate the community user by setting the field IsActive to false');
            
            ApexPages.StandardController sc = new  ApexPages.StandardController(acc);     
            CreateCommunityUserController createCommunityUserController = new CreateCommunityUserController(sc);         
            Test.startTest();
                createCommunityUserController.createCommunityUser();
            Test.stopTest();
             users = [SELECT Id, IsActive FROM User WHERE Username = '2280673994428@canalbox.com'];
             System.assertEquals(true, users[0].IsActive, 'Should have activate the user by setting the field IsActive to true');
        } 
    }


    
    @isTest static void shouldDesactivateTheUserBySettingIsActiveToFalse(){    
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
            HttpCalloutMock multiCalloutMock = getMultimockCallOut();
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            Account acc = TestDataFactory.createPersonAccount('test','TG');
            acc.personMobilePhone = '0673994428';
            insert acc;  
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription;  // The user is created when insert a subcription
            List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
            CreateUserHandler.createCommunityUser(zuoraSubscriptions);
            
            ApexPages.StandardController sc = new  ApexPages.StandardController(acc);     
            CreateCommunityUserController createCommunityUserController = new CreateCommunityUserController(sc);         
            Test.startTest();
                createCommunityUserController.deactivateCommunityUser();
            Test.stopTest();
            List<User> users = [SELECT Id, IsActive FROM User WHERE Username = '2280673994428@canalbox.com'];
             System.assertEquals(false, users[0].IsActive, 'Should have activate the user by setting the field IsActive to true');
        } 
    }


}