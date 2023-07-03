/**
 * Classe Test pour Batch01_SendBulkSMS
 * Couverture: 83%
 * @author Yara Bourdoukan
 * @date 29 Avril 2021
 */
@isTest
public class Batch01_SendBulkSMS_Test {

    @TestSetup
    static void makeData(){
        //add Zuora Mock and Eligibility Mock to MultiMock class
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
        HttpCalloutMock multiCalloutMock = new MultiMock(endpoint2TestResp);

        Test.setMock(HttpCalloutMock.class, multiCalloutMock);
        TestUtils.createSub();
    }

    @isTest
    static void testBulkSMS(){
        Test.setMock(HttpCalloutMock.class, new EligMock());
        //get Account Id
        Zuora__Subscription__c sub = [SELECT Zuora__Account__c, ExpectedRenewalDate__c, Quote__c, Zuora__CustomerAccount__c
                                      FROM Zuora__Subscription__c
                                      LIMIT 1];
        sub.ExpectedRenewalDate__c = date.today().addDays(-15);
        try {
            update sub;

            contact con = [SELECT id, MobilePhone
                        FROM Contact
                        WHERE AccountId = :sub.Zuora__Account__c];
            // Create Test Campaign
            Campaign testCampaign = new Campaign(Name = 'Test Campaign', IsActive = true);//, CurrencyIsoCode = 'XOF'
            insert testCampaign;

            // Create Test Campaign
            Campaign RenewCampaign = new Campaign(Name = 'Renew Campaign', IsActive = true);//, CurrencyIsoCode = 'XOF'
            insert RenewCampaign;

            id personAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
            Account acc2 = new Account(firstname = 'Test', lastname = 'Test 2', Phone = '234654', recordtypeId = personAccountId);
            insert acc2;

            // Mobile Phone numbers for each contact should be like the ones in the Mock response
            con.Phone = '612345678';
            update con;

            Contact testContact2 = [SELECT Id, MobilePhone, Phone, Email
                                    FROM Contact
                                    WHERE AccountId = :acc2.Id];
            testContact2.Phone = '612345679';
            // Changing Phone and email to avoid duplicate detection
            testContact2.MobilePhone = '123456';
            testContact2.Email = 'test2@test.com';
            update testContact2;

            CampaignMember member1 = new CampaignMember(CampaignId = testCampaign.Id, ContactId = con.Id, Status = 'Sent', CMB_SMS_Envoye__c  = false);
            CampaignMember member2 = new CampaignMember(CampaignId = testCampaign.Id, ContactId = testContact2.Id, Status = 'Sent', CMB_SMS_Envoye__c  = false);
            insert member1;
            insert member2;
        } catch (Exception e) {
            system.debug(e.getLineNumber()+'  '+ e.getMessage());
        }
        // Test Scheduler and Batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SMSMock());
        String cronExpr = '0 0 23 * * ?';
        BulkSMSBatchScheduler smsbs = new BulkSMSBatchScheduler();
        String jobId = System.schedule('myJobTestJobName', cronExpr, smsbs);
        CronTrigger ct = [SELECT id, CronExpression FROM CronTrigger where id = :jobId];
        System.assertEquals(cronExpr, ct.CronExpression, 'Scheduler not set correctly');
        smsbs.execute(null);
        jobId = Database.executeBatch(new Batch01_SendBulkSMS(), 200);
        Test.stopTest();
        List<CampaignMember> targetedMembers = [SELECT Id, Name, CMB_SMS_Envoye__c FROM CampaignMember WHERE CMB_SMS_Envoye__c = true];
        System.assertEquals(2, targetedMembers.size(), 'Wrong number of targeted Campaign Members received');
    }
}