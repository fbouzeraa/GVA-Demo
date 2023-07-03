@isTest
public with sharing class ClientPortalLoginController_Test {
    


    // private String userMobilePhone = '+33 0123456781'
    
    @TestSetup
    static void makeData(){
        User adminUser = TestDataFactory.createAdminUser('TG');
        insert(adminUser);
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        System.runAs(adminUser){
            Account personAccount = TestDataFactory.createPersonAccount(adminUser, 'TG');
            personAccount.ACC_Indicatif__c = '+33';
            personAccount.Phone = '0123456784';
            insert personAccount;
            User clientPortalUser = TestDataFactory.createClientPortalUser(personAccount, 'TG');
            clientPortalUser.username = 'tg.test@test.com';
            clientPortalUser.email = 'tg.test@test.com';
            clientPortalUser.mobilePhone = '+33 0123456784';
            insert clientPortalUser;

            Account personAccountBF = TestDataFactory.createPersonAccount(adminUser, 'BF');
            personAccountBF.ACC_Indicatif__c = '+226';
            personAccountBF.Phone = '123456789';
            insert personAccountBF;
            User clientPortalUserBF = TestDataFactory.createClientPortalUser(personAccountBF, 'BF');
            clientPortalUserBF.username = 'bf2.test@test.com';
            clientPortalUserBF.email = 'bf2.test@test.com';
            clientPortalUserBF.mobilePhone = '+226 123456789';
            insert clientPortalUserBF;
        }
    }

    @isTest
    static void onFirstUserLoginByMobilePhoneShouldSendPasswordByAllMySmsApi(){
    //    User adminUser = [SELECT Id FROM User WHERE Username='admin.user@mail.fr'];
    ClientPortalLoginController  clientPortalLoginController = new ClientPortalLoginController();
    clientPortalLoginController.identifier = '+33 0123456784';
    clientPortalLoginController.password = 'Test123';
      //  System.runAs(adminUser){
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        System.assert(clientPortalLoginController.login()==null);  // Should be passworlessLogin page reference, don't know how to test Site.passwordlessLogin(user.Id, methods, startUrl) properly
        
    
    }

    @isTest
    static void  onUserLoginByEmailShouldRedirectToPasswlordLessLoginPage(){
        ClientPortalLoginController  clientPortalLoginController = new ClientPortalLoginController();
        clientPortalLoginController.identifier = 'tg.test@test.com';
        clientPortalLoginController.password = 'Test123';
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        System.assert(clientPortalLoginController.login()==null);  // Should be passworlessLogin page reference, don't know how to test Site.passwordlessLogin(user.Id, methods, startUrl) properly

    }

    @isTest
    static void  shouldAddAnErrorMessageOnNullIdentifier(){
        ClientPortalLoginController  clientPortalLoginController = new ClientPortalLoginController();
        clientPortalLoginController.identifier = null;
        Test.setMock(HttpCalloutMock.class, new SMSMock());
            Test.startTest();
               Pagereference pagereference = clientPortalLoginController.login();
            Test.stopTest();
        System.assertEquals(ApexPages.currentPage(), pagereference); 
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),'There should be error messages');
        System.assertEquals('Invalid Identifier', ApexPages.getMessages().get(0).getDetail());
    }

    @isTest
    static void  shouldAddAnErrorMessageOnMobilePhoneIdentifierWithNoUserOrMulipleUsersFound(){
        ClientPortalLoginController  clientPortalLoginController = new ClientPortalLoginController();
        clientPortalLoginController.identifier = '+33 0123456785';
        Test.setMock(HttpCalloutMock.class, new SMSMock());
            Test.startTest();
               Pagereference pagereference = clientPortalLoginController.login();
            Test.stopTest();
        System.assertEquals(ApexPages.currentPage(), pagereference); 
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),'There should be error messages');
        System.assertEquals('No unique user found. User count=0', ApexPages.getMessages().get(0).getDetail());
    }


    @isTest
    static void  shouldAddAnErrorMessageOnEmailIdentifierWithNoUserOrMulipleUsersFound(){
        ClientPortalLoginController  clientPortalLoginController = new ClientPortalLoginController();
        clientPortalLoginController.identifier = 'no.user.test@test.com';
        Test.setMock(HttpCalloutMock.class, new SMSMock());
            Test.startTest();
               Pagereference pagereference = clientPortalLoginController.login();
            Test.stopTest();
        System.assertEquals(ApexPages.currentPage(), pagereference); 
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),'There should be error messages');
        System.assertEquals('No unique user found. User count=0', ApexPages.getMessages().get(0).getDetail());
    }


    @isTest
    static void  shouldAcceptBurkinaFasoPhoneFormat(){
        ClientPortalLoginController  clientPortalLoginController = new ClientPortalLoginController();
        clientPortalLoginController.identifier = '+226 123456789';
        clientPortalLoginController.password = 'Test123';
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        System.assert(clientPortalLoginController.login()==null); 
        
    }

    @isTest
    static void  shouldAcceptBurkinaFasoPhoneFormatWithNoSpace(){
         ClientPortalLoginController   clientPortalLoginController = new  ClientPortalLoginController();
         clientPortalLoginController.identifier = '+226123456789';
         clientPortalLoginController.password = 'Test123';
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        System.assert(clientPortalLoginController.login()==null);
    }

    @isTest
    static void  shouldAcceptFrenchPhoneFormatWithNoSpace(){
         ClientPortalLoginController   clientPortalLoginController = new  ClientPortalLoginController();
         clientPortalLoginController.identifier = '+330123456784';
         clientPortalLoginController.password = 'Test123';
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        System.assert(clientPortalLoginController.login()==null);
    }

}