@isTest
public with sharing class AccountControllerExtension_Test {
       
    @isTest static void shouldSendWelcomeSMSToUser(){    
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
                insert(togoAdminUser);
        System.runAs(togoAdminUser){
            HttpCalloutMock multiCalloutMock = getMultimockCallOut();
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            
            Account acc = TestDataFactory.createPersonAccount('test','TG');
            acc.personMobilePhone = '0673994428';
            insert acc;
            User clientPortalUser = TestDataFactory.createClientPortalUser(acc, 'TG');
            clientPortalUser.MobilePhone = '+228 0673994428';
            insert clientPortalUser;
            
            ApexPages.StandardController sc = new  ApexPages.StandardController(acc);     
            AccountControllerExtension accountControllerExtension = new AccountControllerExtension(sc);         
            Test.startTest();
                accountControllerExtension.sendWelcomeSms();
            Test.stopTest();
        } 
    }

    
    @isTest static void shouldNotSendWelcomeSmsIfUserNotExist(){    
        User togoAdminUser = TestDataFactory.createAdminUser('TG');
        insert(togoAdminUser);
        System.runAs(togoAdminUser){
            HttpCalloutMock multiCalloutMock = getMultimockCallOut();
            Test.setMock(HttpCalloutMock.class, multiCalloutMock);
            
            Account acc = TestDataFactory.createPersonAccount('test','TG');
            acc.personMobilePhone = '0673994428';
            insert acc;
            
            ApexPages.StandardController sc = new  ApexPages.StandardController(acc);     
            AccountControllerExtension accountControllerExtension = new AccountControllerExtension(sc);         
            Test.startTest();
                accountControllerExtension.sendWelcomeSms();
            Test.stopTest();
        } 
    }

    private static HttpCalloutMock getMultimockCallOut(){
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
          endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
          endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
          endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
          HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);
          return  multiCalloutMock;
      }
}