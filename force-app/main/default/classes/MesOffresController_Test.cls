@isTest
public with sharing class MesOffresController_Test {

 
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
     static void shouldSendAnEmailWithGscAttachToTheUser(){

        List<User> togoClientPortalUsers = [SELECT Id FROM User WHERE Username = 'TG.client.portal.user@testorg.com'];
        User togoClientPortalUser = togoClientPortalUsers[0];

        System.runAs(togoClientPortalUser){
            test.startTest();
                     String emailIsSent =  MesOffresController.sendGeneralSalesConditionsByEmail('client.portal.user@testorg.com','CGV_GVA_Burkina_Faso_20220101_Fiche_tarifaire_20220315');
            test.stopTest();

            System.assertEquals(System.label.Email_Is_Sent, emailIsSent, 'The function should return that the email was sent');
        }
    }
 
   
}