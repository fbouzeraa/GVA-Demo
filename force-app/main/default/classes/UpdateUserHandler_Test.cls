@istest
public with sharing class UpdateUserHandler_Test {

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
            Account acc = TestDataFactory.createPersonAccount('testUpdate','TG');
            acc.personMobilePhone = '06799944284';
            insert acc;
            Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
            insert zuoraSubscription; // The user is created  when insert a subsctription
            List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
            CreateUserHandler.createCommunityUser(zuoraSubscriptions);
        }
    }

    @isTest
    static void shouldUpdateTheFirstNameAndLastNameOfTheUserWhenUpdateTheAccount (){
        Account account = [SELECT Id, PersonContactId  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
        account.firstName = 'NewFirstName';
        account.lastName = 'NewLastName';
        User user = [SELECT Id FROM User WHERE Username = 'test.admin.user@mail.fr'].get(0);

        System.runAs(user){
            Test.startTest();
                update account;
            Test.stopTest();
            List<User> users = [SELECT Id, FirstName, LastName, ContactId FROM User WHERE firstname = 'testUpdate'];
            System.assertEquals( 'NewFirstName', users[0].firstName, 'The user first name should be : NewFirstName');
            System.assertEquals( 'NewLastName', users[0].lastName, 'The user last name should be : NewLastName');
        }
    }

    // @isTest
    // static void shouldUpdateTheFirstNameAndLastNameOfTheUserWhenUpdateTheAccountRunningAdmin(){
        
    //     User adminUser = [SELECT Id FROM User WHERE Username = 'test.admin.user@mail.fr'].get(0);
    //     System.runAs(adminUser){
    //         Test.startTest();
    //             Account account = [SELECT Id  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
    //             account.firstName = 'NewFirstName';
    //             account.lastName = 'NewLastName';
    //             update account;
    //         Test.stopTest();
    //         List<User> users = [SELECT Id, FirstName, LastName, ContactId FROM User WHERE Username = '22806799944284@canalbox.com'];
    //         System.assertEquals(1, users.size(), 'Should have created the user');
    //         System.assertEquals( 'NewFirstName', users[0].firstName, 'The user first name should be : NewFirstName');
    //         System.assertEquals( 'NewLastName', users[0].lastName, 'The user last name should be : NewLastName');
    //     }
    // }

    @isTest
    static void shouldUpdateCreateTwoUser(){
      User togoAdminUser = [SELECT Id FROM User WHERE Username = 'test.admin.user@mail.fr'].get(0);

      System.runAs(togoAdminUser){

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
        Test.setMock(HttpCalloutMock.class, multiCalloutMock);   

        Test.startTest();
          Account acc2 = TestDataFactory.createPersonAccount('test2','TG');
          acc2.personMobilePhone = '0673258478';
          insert acc2;
          String subscriptionNumber = 'A-S00000401';
          Zuora__Subscription__c zuoraSubscription2 = TestDataFactory.createSecondSub(acc2, subscriptionNumber);
          insert zuoraSubscription2;
          List<Zuora__Subscription__c> zuoraSubscriptions2 = new List<Zuora__Subscription__c>{zuoraSubscription2};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions2);

          Account account1 = [SELECT Id  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
          account1.firstName = 'NewFirstName1';
          account1.lastName = 'NewLastName1';
          update account1;

          Account account2 = [SELECT Id  FROM Account WHERE PersonMobilePhone = '0673258478'].get(0);
          account2.firstName = 'NewFirstName2';
          account2.lastName = 'NewLastName2';
          update account2;

        Test.stopTest();
        List<User> users = [SELECT Id, FirstName, LastName FROM User WHERE firstname = 'testUpdate'];
        System.assertEquals(1, users.size(), 'Should have created the user');
        System.assertEquals( 'NewFirstName1', users[0].firstName, 'The user first name should be : NewFirstName1');
        System.assertEquals( 'NewLastName1', users[0].lastName, 'The user last name should be : NewLastName1');
        List<User> users2 = [SELECT Id, FirstName, LastName FROM User WHERE firstname = 'test2'];
        System.assertEquals(1, users2.size(), 'Should have created the second user');
        System.assertEquals( 'NewFirstName2', users2[0].firstName, 'The user first name should be : NewFirstName1');
        System.assertEquals( 'NewLastName2', users2[0].lastName, 'The user last name should be : NewLastName1');
      }
    }

    @isTest
    static void shouldUpdateFieldsOfTheUserWhenUpdateTheAccount(){
        Account acct = [SELECT Id  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
        acct.PersonEmail = 'update.communityuser@gmail.com';
        acct.BillingStreet = 'Street update';
        acct.BillingCity = 'City update';
        acct.BillingPostalCode = '38140';
        acct.suffix = 'Suffix update';
        acct.middleName = 'MiddleName update';
        acct.BillingCountryCode = 'BF';
        acct.CurrencyIsoCode = 'XOF';
        acct.ACC_LatLong__Latitude__s = 45.17;
        acct.ACC_LatLong__Longitude__s = 45.18;

        User adminUser = [SELECT Id FROM User WHERE Username = 'test.admin.user@mail.fr'].get(0);

        System.runAs(adminUser){
            Test.startTest();
                update acct;
            Test.stopTest();

            List<User> users = [SELECT Id, Email, Street, City, Suffix, MiddleName, CountryCode, Country, 
                                DefaultCurrencyIsoCode, Latitude, Longitude, PostalCode, Pays_Mapbox__c,
                                StateCode
                                 FROM User 
                                 WHERE firstname = 'testUpdate'];

            System.assertEquals(1, users.size(), 'Should have created the user');
            System.assertEquals( 'update.communityuser@gmail.com', users[0].email, 'The user email name should be : update.communityuser@gmail.com');
            System.assertEquals( 'Street update', users[0].street, 'The user street name should be : Street update');
            System.assertEquals( 'City update', users[0].city, 'The user city name should be : City update');
            System.assertEquals( 'Suffix update', users[0].suffix, 'The user suffix name should be : Suffix update');
            System.assertEquals( 'MiddleName update', users[0].middleName, 'The user suffix name should be : Suffix MiddleName update');
            System.assertEquals( 'BF', users[0].countryCode, 'The user country code name should be : BF');
            System.assertEquals( 'Burkina Faso', users[0].country, 'The user country code name should be : Burkina Faso');
            System.assertEquals( 'XOF', users[0].defaultCurrencyIsoCode, 'The user defaultCurrencyIsoCode code name should be : XOF');
            System.assertEquals( '38140', users[0].postalCode, 'The user postal code name should be : 38140');
            System.assertEquals( 'BF', users[0].Pays_Mapbox__c, 'The user postal code name should be : 38140');
        }
    }


    @isTest
    static void shouldUpdatelocalSettingOfTheUserWhenUpdateTHeBillingCountryCodeOfTheAccount (){
        Account account = [SELECT Id  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
        account.BillingCountryCode = 'BF';

        User user = [SELECT Id FROM User WHERE Username = 'test.admin.user@mail.fr'].get(0);
        System.runAs(user){
            Test.startTest();
                update account;
            Test.stopTest();

            List<User> users = [SELECT Id, LanguageLocaleKey, LocaleSidKey, TimeZoneSidKey FROM User WHERE firstname = 'testUpdate'];
            System.assertEquals('fr', users[0].languageLocaleKey);
            System.assertEquals('fr_FR', users[0].localeSidKey);
            System.assertEquals('Africa/Ouagadougou', users[0].timeZoneSidKey);
        }
    }

    @isTest
    static void shouldUpdatePhoneWhenUpdateTHeAccountPhoneIsUpdated (){
        Account account = [SELECT Id  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
        account.Phone = '0679994429';
        User user = [SELECT Id, phone FROM User WHERE Username = 'test.admin.user@mail.fr'].get(0);
        System.runAs(user){
            Test.startTest();
                update account;
            Test.stopTest();

            List<User> users = [SELECT Id, Phone, MobilePhone FROM User WHERE firstname = 'testUpdate'];
            System.assertEquals('+228 0679994429', users[0].phone,'The user phone should be');
            System.assertEquals('+228 06799944284', users[0].mobilePhone,'The user mobile phone should be');
        }
    }

    @isTest
    static void shouldUpdateMobilePhoneWhenUpdateTHeAccountMobilePhoneIsUpdated (){
        Account account = [SELECT Id  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
        account.personMobilePhone = '0679994430';
        User user = [SELECT Id, phone FROM User WHERE Username = 'test.admin.user@mail.fr'].get(0);
        System.runAs(user){
            Test.startTest();
                update account;
            Test.stopTest();
            List<User> users = [SELECT Id, Phone, MobilePhone FROM User WHERE firstname = 'testUpdate'];
            System.assertEquals('+228 01212121', users[0].phone,'The user phone should be +228 1212121');
            System.assertEquals('+228 0679994430', users[0].mobilePhone,'The user mobile phone should be +228 0679994430');
        }
    }

    @isTest
    static void shouldUpdateCommunityWhenUpdateTheAccountMobilePhoneIsUpdated (){
        Account account = [SELECT Id  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
        account.personMobilePhone = '0679994430';
        User user = [SELECT Id, phone FROM User WHERE Username = 'test.admin.user@mail.fr'].get(0);
        System.runAs(user){
            Test.startTest();
                update account;
            Test.stopTest();
            List<User> users = [SELECT Id, CommunityNickname FROM User WHERE firstname = 'testUpdate'];
                                                                                
            System.assertEquals('2280679994430', users[0].CommunityNickname,'The user nickname should be');
        }
    }

    @isTest
    static void shouldNotUpdateTheEmailAccountIfTheCurrentUserIsTheUserToUpdate (){
        Account account = [SELECT Id, PersonContactId, PersonEmail  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
        String oldAccountEmail = account.personEmail;
        account.personEmail = 'update.communityuser@gmail.com';
        User user = [SELECT Id FROM User WHERE firstname = 'testUpdate'].get(0);
        System.runAs(user){
            Test.startTest();
                update account;
            Test.stopTest();
            Account accountUpdated = [SELECT Id, personEmail  FROM Account WHERE PersonMobilePhone = '06799944284'].get(0);
            System.assertEquals(oldAccountEmail, accountUpdated.personEmail, 'Should have created not updated the account');
        }

    }
}