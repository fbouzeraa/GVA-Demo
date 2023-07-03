/**
 * An apex page controller that exposes the site login functionality
 */
@IsTest global with sharing class SiteLoginControllerTest {

    @TestSetup
    static void makeData(){
        User adminUser = TestDataFactory.createAdminUser('TG');
        insert adminUser;
        System.runAs(adminUser){
            // QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Task');
            // insert testQueue;
            Account togoPersonAccount = TestDataFactory.createPersonAccount(adminUser,'TG');
            togoPersonAccount.PersonMobilePhone = '+33 0673994431';
            insert togoPersonAccount;
        }
        
    }

    @IsTest 
    global static void testSiteLoginController () {
        // Instantiate a new controller with all parameters in the page
        User adminUser =  [SELECT id FROM User WHERE Username = 'admin.user@mail.fr'].get(0);
        System.runAs(adminUser){
            SiteLoginController controller = new SiteLoginController ();
            controller.mobilePhone = '+33 00673994431';
            controller.password = '123456'; 
                    
            System.assertEquals(controller.login(),null);  
        }                         
    }    
}