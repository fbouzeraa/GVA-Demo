@isTest
public with sharing class ClientPortalForgotPassController_Test {

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
            clientPortalUser.username = 'test@salesforce.com';
            clientPortalUser.email = 'test@salesforce.com';
            clientPortalUser.mobilePhone = '+33 0123456784';
            insert clientPortalUser;
        }
    }

    @IsTest
     public static void shouldSetIsForgotPasswordSucessToTrueOnResetPasswordByEmail() {
    	// Instantiate a new controller with all parameters in the page
    	ClientPortalForgotPasswordController clientPortalForgotPassword = new ClientPortalForgotPasswordController();
    	clientPortalForgotPassword.identifier = 'test@salesforce.com';     	
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        Test.startTest();
             clientPortalForgotPassword.forgotPassword();
        Test.stopTest();
        System.assertEquals(true, clientPortalForgotPassword.isForgotPasswordSucess);
    //	System.assertEquals(controller.forgotPassword(),null); 
    }

    @IsTest
    public static void shouldAddAnApexErrorMessageIfUserIsNotUserIsFoundByEmail() {
        // Instantiate a new controller with all parameters in the page
        ClientPortalForgotPasswordController clientPortalForgotPassword = new ClientPortalForgotPasswordController();
        clientPortalForgotPassword.identifier = 'test.not.exist.user@salesforce.com';     	
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        Test.startTest();
         Pagereference pagereference = clientPortalForgotPassword.forgotPassword();
        Test.stopTest();
        System.assertEquals(false, clientPortalForgotPassword.isForgotPasswordSucess);
        System.assertEquals(ApexPages.currentPage(), pagereference);  // Should be passworlessLogin page reference, don't know how to test Site.passwordlessLogin(user.Id, methods, startUrl) properly
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),'There should be error messages');
        System.assertEquals('No unique user found. User count=0', ApexPages.getMessages().get(0).getDetail()); 
   }

   @IsTest
    public static void shouldAddAnApexErrorMessageOnInvalidIdentier() {
        // Instantiate a new controller with all parameters in the page
        ClientPortalForgotPasswordController clientPortalForgotPassword = new ClientPortalForgotPasswordController();
        clientPortalForgotPassword.identifier = 'aaa';     	
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        Test.startTest();
         Pagereference pagereference = clientPortalForgotPassword.forgotPassword();
        Test.stopTest();
        System.assertEquals(false, clientPortalForgotPassword.isForgotPasswordSucess);
        System.assertEquals(ApexPages.currentPage(), pagereference);  // Should be passworlessLogin page reference, don't know how to test Site.passwordlessLogin(user.Id, methods, startUrl) properly
        System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),'There should be error messages');
        System.assertEquals('Invalid Identifier', ApexPages.getMessages().get(0).getDetail());
   }

   @IsTest
     public static void  shouldSetIsForgotPasswordSucessToTrueOnResetPasswordBySms() {
    	// Instantiate a new controller with all parameters in the page
    	ClientPortalForgotPasswordController clientPortalForgotPassword = new ClientPortalForgotPasswordController();
    	clientPortalForgotPassword.identifier = '+33 0123456784';     	
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        Test.startTest();
             clientPortalForgotPassword.forgotPassword();
        Test.stopTest();
        System.assertEquals(true, clientPortalForgotPassword.isForgotPasswordSucess);
    }

    @IsTest
    public static void shouldAddAnApexErrorMessageIfUserIsNoUserIsFoundByMobilePhone() {
       // Instantiate a new controller with all parameters in the page
       ClientPortalForgotPasswordController clientPortalForgotPassword = new ClientPortalForgotPasswordController();
       clientPortalForgotPassword.identifier = '+33 0123456785';     	
       Test.setMock(HttpCalloutMock.class, new SMSMock());
       Test.startTest();
       Pagereference pagereference = clientPortalForgotPassword.forgotPassword();
       Test.stopTest();
       System.assertEquals(false, clientPortalForgotPassword.isForgotPasswordSucess);
       System.assertEquals(ApexPages.currentPage(), pagereference);  // Should be passworlessLogin page reference, don't know how to test Site.passwordlessLogin(user.Id, methods, startUrl) properly
       System.assert(ApexPages.hasMessages(ApexPages.Severity.ERROR),'There should be error messages');
       System.assertEquals('No unique user found. User count=0', ApexPages.getMessages().get(0).getDetail()); 
   }



    
}