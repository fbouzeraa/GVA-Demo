@isTest
public class SubscriptionTriggerTest {
    @isTest static void TestSubscriptionTrigger() {
        //add Zuora Mock and Eligibility Mock to MultiMock class

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();

        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());

        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());

        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());

        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);



        Test.setMock(HttpCalloutMock.class, multiCalloutMock);

        Profile p = [SELECT Id FROM Profile WHERE Name = :System.label.Administrator_Profile];

        user togoAdminUser = TestUtils.createUser('example1@test.com', 'lastName1', 'y.bourdoukan@gva.africa', system.label.Distributor_Id, p.Id);

        insert(togoAdminUser);



        System.runAs(togoAdminUser){

               id subId = TestUtils.createSub();
            Zuora__Subscription__c sub = [Select Zuora__Status__c from Zuora__Subscription__c LIMIT 1];

            sub.Zuora__Status__c = 'cancelled';

            update sub;

        }

    }

}