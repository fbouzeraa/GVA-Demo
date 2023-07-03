@isTest
public with sharing class FooterController_Test {

    @testSetup
    static void makeData(){
        User adminUser = TestDataFactory.createAdminUser('TG');        
        insert adminUser;
        System.runAs(adminUser){      
            Test.setMock(HttpCalloutMock.class, new SMSMock());    
            User togoClientPortalUser = TestDataFactory.createClientPortalUser(adminUser, 'TG');
            User frenchClientPortalUser = TestDataFactory.createClientPortalUser(adminUser, 'FR');
            List<User> clientPortalUsers = new List<User>{
                                                        togoClientPortalUser,
                                                        frenchClientPortalUser
                                                        };
            insert togoClientPortalUser;
        }
    }


    @isTest 
    static void shouldGetTheCountryOfThePortalUser(){
        List<User> togoClientPortalUsers = [SELECT Id, countryCode FROM User WHERE countryCode='TG'];
        User togoClientPortalUser = togoClientPortalUsers[0];

        System.runAs(togoClientPortalUser){
            test.startTest();
                FooterController.FooterWrapperResponse footerWrapperResponse = FooterController.getUserCountryInfo();
            test.stopTest();
            System.assertEquals('TG', footerWrapperResponse.countryCode);
        }
    }

    @isTest 
    static void shouldGetCurrentUserCountryContactsLink(){
        List<User> togoClientPortalUsers = [SELECT Id, countryCode FROM User WHERE countryCode='TG'];
        User togoClientPortalUser = togoClientPortalUsers[0];

        System.runAs(togoClientPortalUser){
            test.startTest();
                    FooterController.FooterWrapperResponse footerWrapperResponse = FooterController.getUserCountryInfo();
            test.stopTest();
            System.assertNotEquals(null, footerWrapperResponse.countryContactInfo.phone__c);
            System.assertNotEquals(null, footerWrapperResponse.countryContactInfo.email__c);
            System.assertEquals('8866', footerWrapperResponse.countryContactInfo.phone__c);

        }
    }


    @isTest 
    static void shouldHandleReturnNullCurrentUserCountryContactsLink(){
        List<User> franceClientPortalUsers = [SELECT Id, countryCode FROM User WHERE countryCode='FR'];
        User franceClientPortalUser = franceClientPortalUsers[0];

        System.runAs(franceClientPortalUser){
            test.startTest();
                    FooterController.FooterWrapperResponse footerWrapperResponse = FooterController.getUserCountryInfo();
            test.stopTest();
            System.assertEquals(null, footerWrapperResponse.countryContactInfo);
        }
    }

    
}