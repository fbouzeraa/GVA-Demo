@isTest
public with sharing class NosAgencesController_Test {

    @testSetup
    static void makeData(){
        User adminUser = TestDataFactory.createAdminUser('TG');        
        insert adminUser;
        System.runAs(adminUser){   
            Test.setMock(HttpCalloutMock.class, new SMSMock());       
            User togoClientPortalUser = TestDataFactory.createClientPortalUser(adminUser, 'TG');
            insert togoClientPortalUser;
        }
    }

    @isTest
    static void shouldGetCurrentUserCountryAgencies(){
        List<User> togoClientPortalUsers = [SELECT Id, countryCode FROM User WHERE countryCode='TG'];
        User togoClientPortalUser = togoClientPortalUsers[0];

        System.runAs(togoClientPortalUser){
            test.startTest();
                        List<Agency__mdt> agencies = NosAgencesController.getCurrentUserCountryAgencies();
            test.stopTest();
            System.assertNotEquals(null, agencies.size());
            for(Agency__mdt agency : agencies){
                System.assertEquals('TG', agency.countryCode__c);
            }
        }
    }
   
}