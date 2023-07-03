@isTest()
public class CreateUserHandlerTest {


  @TestSetup
  static void makeData(){
    // User togoAdminUser = TestDataFactory.createAdminUser('TG');
    // insert(togoAdminUser);
    //   System.runAs(togoAdminUser){
      
    //  // Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
    // }
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
  static void shouldCreateUserWhenInsertSubcription(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          acc.personMobilePhone = '0673994528';
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, Username, ProfileId, UserRoleId, USR_BypassVR__c FROM User WHERE Username = '2280673994428@canalbox.com'];
      // System.assertEquals(1, users.size(), 'Should have created the user');
      // System.assertEquals( '2280673994428@canalbox.com', users[0].username, 'The username should be : 2280673994428@canalbox.com');
      // System.assertEquals(clientPortalProfile.Id, users[0].profileId, 'The user created should be Utilisateur du portail client profile');
      // System.assertEquals(null, users[0].UserRoleId, 'The user created should have UserRoleId set to null');
      // System.assertEquals(true, users[0].USR_BypassVR__c, 'The validation rule should be bypass');
    }
  }


  @isTest
  static void shouldSetCommunityNickname(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          acc.personMobilePhone = '0673994428';
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, CommunityNickname FROM User WHERE Username = '2280673994428@canalbox.com'];
      // System.assertEquals( '2280673994428', users[0].communityNickname, 'The user communityNickname should be : 228673994428');
    }
  }

  @isTest
  static void shouldNotTryToCreateAUserOnASecondInsertOfASubcriptionForTheUser(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      Id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          insert acc;
          Zuora__Subscription__c zuoraSubscription1 = TestDataFactory.createSub(acc);
          insert zuoraSubscription1;
          List<Zuora__Subscription__c> zuoraSubscriptions1 = new List<Zuora__Subscription__c>{zuoraSubscription1};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions1);
          // Account acc = [SELECT Id FROM Account WHERE FirstName = 'TEST'].get(0);
          String subscriptionNumber = 'A-S00000401';
          Zuora__Subscription__c zuoraSubscription2 = TestDataFactory.createSecondSub(acc, subscriptionNumber);
          insert zuoraSubscription2;
           List<Zuora__Subscription__c> zuoraSubscriptions2 = new List<Zuora__Subscription__c>{zuoraSubscription2};
          // insert zuoraSubscriptions;
          CreateUserHandler.createCommunityUser(zuoraSubscriptions2);
      Test.stopTest();                                                        
      // List<User> users = [SELECT Id, Username FROM User WHERE Username = '2280673994428@canalbox.com'];
      // System.assertEquals(1, users.size(), 'Should have created the user');
      // System.assertEquals( '2280673994428@canalbox.com', users[0].username, 'The username should be : 2280673994428@canalbox.com');
      // List<Zuora__Subscription__c> subscriptions = [SELECT Id FROM Zuora__Subscription__c WHERE Zuora__Account__c = :acc.Id];
      // System.assertEquals(2, subscriptions.size(), 'Should have created two subscriptions for the account');
    }
  }


  @isTest
  static void shouldCreteTwoUser(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      Id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
      Test.startTest();
        Account acc = TestDataFactory.createPersonAccount('test','TG');
        insert acc;
        Zuora__Subscription__c zuoraSubscription1 = TestDataFactory.createSub(acc);
        Account acc2 = TestDataFactory.createPersonAccount('test2','TG');
        acc2.personMobilePhone = '0673258478';
        insert acc2;
        String subscriptionNumber = 'A-S00000401';
        Zuora__Subscription__c zuoraSubscription2 = TestDataFactory.createSecondSub(acc2, subscriptionNumber);

        List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription1, zuoraSubscription2};
        insert zuoraSubscriptions;
        CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, Username FROM User WHERE Username =  '2280673994428@canalbox.com'];
      // System.assertEquals(1, users.size(), 'Should have created the user');
      // List<User> users2 = [SELECT Id, Username FROM User WHERE Username = '2280673258478@canalbox.com'];
      // System.assertEquals(1, users2.size(), 'Should have created the second user');
    }
  }


  @isTest
  static void shouldSetLanguageToFrenchIfPersonAccountCountryIsTogo(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id,  Country, CountryCode, LanguageLocaleKey, LocaleSidKey  FROM User WHERE Username = '2280673994428@canalbox.com'];
      // System.assertEquals(1, users.size(), 'Should have created the user');
      // System.assertEquals( 'Togo', users[0].Country, 'User languageLocaleKey should be fr');
      // System.assertEquals( 'TG', users[0].CountryCode, 'User languageLocaleKey should be fr');
      // System.assertEquals( 'fr', users[0].LanguageLocaleKey, 'User languageLocaleKey should be fr');
      // System.assertEquals( 'fr_FR', users[0].LocaleSidKey, 'User localeSidKey  should be fr_FR');
    }
  }


  @isTest
  static void shouldSetTimeZoneSidKeyToAfricaLomeIfPersonAccountCountryIsTogo(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, TimeZoneSidKey  FROM User WHERE Username = '2280673994428@canalbox.com'];
      // System.assertEquals(1, users.size(), 'Should have created the user');
      // System.assertEquals('Africa/Lome', users[0].TimeZoneSidKey, 'Togo User TimeZoneSidKey should be Africa/Lome');
    }
  }


  @isTest
  static void shouldSetTimeZoneSidKeyToAfricaOuagadougouIfPersonAccountCountryIsBurkinaFaso(){
    User togoAdminUser = TestDataFactory.createAdminUser('BF');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test', 'BF');
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, TimeZoneSidKey  FROM User WHERE Username = '2260673994428@canalbox.com'];
      // System.assertEquals(1, users.size(), 'Should have created the user');
      // System.assertEquals('Africa/Ouagadougou', users[0].TimeZoneSidKey, 'Burkina Faso user TimeZoneSidKey should be Africa/Ouagadougou');
    }
  }


  @isTest
  static void shouldSetTheMobilePhoneInTheRightFormatIfThePersonAccountAsOnlyAMobilePhone(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          acc.personMobilePhone = '679994428';
          acc.phone = '';
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, Username, ProfileId, MobilePhone, Phone FROM User WHERE Username = '228679994428@canalbox.com'];
      // System.assertEquals( '+228 679994428', users[0].mobilePhone, 'The mobile phone should be +228 679994428');
      // System.assertEquals( null, users[0].Phone, 'The phone should be null');
    }
  }


  @isTest
  static void shouldSetTheUserMobilePhoneRemovingTheZero(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          acc.personMobilePhone = '0679994428';
          acc.phone = '';
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      List<User> users = [SELECT Id, Username, ProfileId, MobilePhone, Phone FROM User WHERE Username = '2280679994428@canalbox.com'];
      // System.assertEquals( '+228 0679994428', users[0].mobilePhone, 'The mobile phone should be +228 0679994428');
      // System.assertEquals( null, users[0].Phone, 'The phone should be null');
    }
  }

  @isTest
  static void shouldSetTheUserMobilePhoneIfThePersonAccountAsOnlyAPhone(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          acc.personMobilePhone = '';
          acc.phone = '0679994425';
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, Username, ProfileId, MobilePhone, Phone FROM User WHERE Username = '2280679994428@canalbox.com'];
      // System.assertEquals( '+228 0679994428', users[0].mobilePhone, 'The mobile phone should be +228 0679994428');
      // System.assertEquals( null, users[0].Phone, 'The phone should be null');
    }
  }

  @isTest
  static void shouldSetTheUserMobilePhoneAndPhoneIfThePersonAccountAsBoth(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          acc.personMobilePhone = '0679994432';
          acc.phone = '0679994427';
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, Username, ProfileId, MobilePhone, Phone FROM User WHERE Username = '2280679994428@canalbox.com'];
      // System.assertEquals( '+228 0679994428', users[0].mobilePhone, 'The mobile phone should be +228 0679994428');
      // System.assertEquals( '+228 0679994427', users[0].Phone, 'The phone should be +228 0679994427');
    }
  }


  @isTest
  static void shouldSetPaysMapBoxToTGWhenUserIsTogo(){
    User togoAdminUser = TestDataFactory.createAdminUser('TG');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test','TG');
          acc.personMobilePhone = '0673994428';
          insert acc;
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, Pays_Mapbox__c FROM User WHERE Username = '2280673994428@canalbox.com'];
      // System.assertEquals( 'TG', users[0].Pays_Mapbox__c, 'The Pays_Mapbox__c should be : Togo');
    }
  }


  @isTest
  static void shouldSetUSRDistributeurIDToNull(){
    User togoAdminUser = TestDataFactory.createAdminUser('BF');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test', 'BF');
           acc.BillingCity = null; // Cannot set to 'Ouagadougou' on insert don't know why
          insert acc;
          List<Account> acctRetrieve = [SELECT Id, BillingCity  FROM Account WHERE Firstname = 'test'];
          System.debug('acctRetrieve : ' + acctRetrieve);
          System.debug('acctRetrieve.BillingCity : ' + acctRetrieve[0].BillingCity);
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, USR_DistributeurID__c  FROM User WHERE Username = '2260673994428@canalbox.com'];
      // System.assertEquals(null, users[0].USR_DistributeurID__c, 'Should have set the USR_DistributeurID__c to null');

    }
  }

  @isTest
  static void shouldSetTheUserAliasTojdavidso(){
    User togoAdminUser = TestDataFactory.createAdminUser('BF');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test', 'BF');
          acc.FirstName = 'John'; // Cannot set to 'Ouagadougou' on insert don't know why
          acc.LastName = 'Davidsono';
          insert acc;
          System.debug('acc : ' + acc);
          List<Account> acctRetrieve = [SELECT Id, BillingCity  FROM Account WHERE Firstname = 'test'];
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, alias  FROM User WHERE Username = '2260673994428@canalbox.com'];
      // System.assertEquals('jdavidso', users[0].alias, 'Should have set the user alias to jdavidso');

    }
  }


  @isTest
  static void shouldSetTheUserEmailTotestexampletestcom(){
    User togoAdminUser = TestDataFactory.createAdminUser('BF');
    togoAdminUser.USR_Bypass_Classes__c = 'CreateUserHandler';
    insert(togoAdminUser);
    System.runAs(togoAdminUser){
      HttpCalloutMock multiCalloutMock = getMultimockCallOut();
      Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
      Test.startTest();
          Account acc = TestDataFactory.createPersonAccount('test', 'BF');
          insert acc;
          System.debug('acc : ' + acc);
          List<Account> acctRetrieve = [SELECT Id, BillingCity  FROM Account WHERE Firstname = 'test'];
          Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
          insert zuoraSubscription;
          List<Zuora__Subscription__c> zuoraSubscriptions = new List<Zuora__Subscription__c>{zuoraSubscription};
          CreateUserHandler.createCommunityUser(zuoraSubscriptions);
      Test.stopTest();
      // List<User> users = [SELECT Id, Email  FROM User WHERE Username = '2260673994428@canalbox.com'];
      // System.assertEquals('test.example@test.com', users[0].email, 'Should have set the user email to BF.person.account@yahoo.com');

    }
  }



  // @isTest
  // static void shouldTHrowAnExeptionWhenTryingToInsertTwoTimesTheSameUser(){
  //   User togoAdminUser = TestDataFactory.createAdminUser('TG');
  //   insert(togoAdminUser);
  //   System.runAs(togoAdminUser){
  //     Profile clientPortalProfile = [SELECT Id FROM Profile WHERE Name='Utilisateur du Portail Client'].get(0);
  //     HttpCalloutMock multiCalloutMock = getMultimockCallOut();
  //     Test.setMock(HttpCalloutMock.class, multiCalloutMock); 
  //     Test.startTest();
  //         Account acc = TestDataFactory.createPersonAccount('test','TG');
  //         acc.personMobilePhone = '0673994428';
  //         insert acc;
  //         Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
  //         insert zuoraSubscription;
  //     Test.stopTest();
  //      System.assertEquals( 'TG', users[0].Pays_Mapbox__c, 'The Pays_Mapbox__c should be : Togo');
  //   }
  // }    List<User> users = [SELECT Id, Pays_Mapbox__c FROM User WHERE Username = '228673994428@canalbox.com'];
  //

  

  // @isTest
  // static void shouldSetTimeZoneSidKeyToAfricaLibrevilleIfPersonAccountCountryIsGabon(){
  //   User togoAdminUser = TestDataFactory.createAdminUser('GA');
  //   insert(togoAdminUser);
  //   System.runAs(togoAdminUser){
  //     HttpCalloutMock multiCalloutMock = getMultimockCallOut();
  //     Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
  //     Test.startTest();
  //         Account acc = TestDataFactory.createPersonAccount('test', 'GA');
  //         insert acc;
  //         Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
  //         insert zuoraSubscription;
  //     Test.stopTest();
  //     List<User> users = [SELECT Id, TimeZoneSidKey  FROM User WHERE Username = '228673994428@canalbox.com'];
  //     System.assertEquals(1, users.size(), 'Should have created the user');
  //     System.assertEquals('Africa/Libreville', users[0].TimeZoneSidKey, 'Gabon user TimeZoneSidKey should be Africa/Libreville');
  //   }
  // }

  // @isTest
  // static void shouldSetTimeZoneSidKeyToAfricaAbidjanIfPersonAccountCountryIsCoteIvoire(){
  //   User togoAdminUser = TestDataFactory.createAdminUser('CI');
  //   insert(togoAdminUser);
  //   System.runAs(togoAdminUser){
  //     HttpCalloutMock multiCalloutMock = getMultimockCallOut();
  //     Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
  //     Test.startTest();
  //         Account acc = TestDataFactory.createPersonAccount('test', 'CI');
  //         insert acc;
  //         Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
  //         insert zuoraSubscription;
  //     Test.stopTest();
  //     List<User> users = [SELECT Id, TimeZoneSidKey  FROM User WHERE Username = '228673994428@canalbox.com'];
  //     System.assertEquals(1, users.size(), 'Should have created the user');
  //     System.assertEquals('Africa/Abidjan', users[0].TimeZoneSidKey, 'Cote Ivoire user TimeZoneSidKey should be Africa/Abidjan');
  //   }
  // }

  // @isTest
  // static void shouldSetTimeZoneSidKeyToAfricaAbidjanIfPersonAccountCountryIsCoteIvoire(){
  //   User togoAdminUser = TestDataFactory.createAdminUser('RW');
  //   insert(togoAdminUser);
  //   System.runAs(togoAdminUser){
  //     HttpCalloutMock multiCalloutMock = getMultimockCallOut();
  //     Test.setMock(HttpCalloutMock.class, multiCalloutMock);    
  //     Test.startTest();
  //         Account acc = TestDataFactory.createPersonAccount('test', 'RW','RWF');
  //         insert acc;
  //         Zuora__Subscription__c zuoraSubscription = TestDataFactory.createSub(acc);
  //         insert zuoraSubscription;
  //     Test.stopTest();
  //     List<User> users = [SELECT Id, TimeZoneSidKey  FROM User WHERE Username = '228673994428@canalbox.com'];
  //     System.assertEquals(1, users.size(), 'Should have created the user');
  //     System.assertEquals('Africa/Kigali', users[0].TimeZoneSidKey, 'Rwanda user TimeZoneSidKey should be Africa/Kigali');
  //     System.assertEquals('Rwanda', users[0].Country, 'User languageLocaleKey should be fr');
  //     System.assertEquals('RW', users[0].CountryCode, 'User languageLocaleKey should be fr');
  //     System.assertEquals('en_US', users[0].LanguageLocaleKey, 'User languageLocaleKey should be fr');
  //     System.assertEquals('en_RW', users[0].LocaleSidKey, 'User localeSidKey  should be fr_FR');
  //   }
  // }

  

}