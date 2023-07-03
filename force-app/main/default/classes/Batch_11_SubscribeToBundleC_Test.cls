/**
 * Classe Test pour Batch01_SendBulkSMS
 * Couverture: 83%
 * @author Jackie Abi Nassif
 * @date 28 Decembre 2022
 */
@isTest
public class Batch_11_SubscribeToBundleC_Test {

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
    public static void Batch_11_SubscribeToBundleC_Test() {

        equipment__c eq = new equipment__c();
        eq.Equipment_Type__c = 'G11A';
        eq.Equipment_Id__c = '21100012773456';
        eq.Already_Used__c = false;
        eq.EQ_Decodeur__c = false;
        eq.EQ_Have_Decoder__c = true;
        eq.Country_Code__c = 'TG';
        equipment__c eq2 = new equipment__c();
        eq2.Equipment_Type__c = 'NVSAG11A';
        eq2.Equipment_Id__c = '54259698645459';
        eq2.Already_Used__c = false;
        eq2.EQ_Decodeur__c = true;
        eq2.EQ_Have_Decoder__c = false;
        eq2.Country_Code__c = 'TG';
        list<equipment__c> listOfEqu = new list<equipment__c>{eq, eq2}; 
        insert listOfEqu;

        Zuora__Subscription__c sub = [SELECT Zuora__Account__c, ExpectedRenewalDate__c, Create_Bundle_C_subscription__c, Prior_expedted_renewal_Date__c,
                                        CBundle_Periode__c,SUB_Tech_Material__c,SUB_Offer__c,SUB_Options__c
                                    FROM Zuora__Subscription__c
                                    LIMIT 1];

        sub.Create_Bundle_C_subscription__c = true;
        sub.Prior_expedted_renewal_Date__c = Date.today();
        sub.SUB_Options__c = '[option]';
        sub.SUB_Offer__c = '[offer]';
        sub.SUB_Tech_Material__c = '[{"Equipment_Id__c":"21100012773456","Equipment_Type__c":"G11A","EQ_Decodeur__c":false,"EQ_Have_Decoder__c":true,"Id":"'+eq.Id+'","Equipment":"21100012773456","Type":"G11A"},{"Equipment_Id__c":"54259698645459","Equipment_Type__c":"NVSAG11A","EQ_Decodeur__c":true,"EQ_Have_Decoder__c":false,"Id":"'+eq2.Id+'","Equipment":"54259698645459","Type":"NVSAG11A"}]';
        sub.CBundle_Periode__c = 1;

        try {
            update sub;
        } catch (Exception e) {
            system.debug(e.getLineNumber()+' '+e.getMessage());
        }

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new CBundeMock());

        String cronExpr = '0 0 * ? * * *';
        Batch11_BundleCSubscription_Scheduler smsbs = new Batch11_BundleCSubscription_Scheduler();
        String jobId = System.schedule('myJobTestJobName', cronExpr, smsbs);
        CronTrigger ct = [SELECT id, CronExpression FROM CronTrigger where id = :jobId];
        System.assertEquals(cronExpr, ct.CronExpression, 'Scheduler not set correctly');
        smsbs.execute(null);

        Batch_11_SubscribeToBundleC btch = new Batch_11_SubscribeToBundleC();
        Database.executeBatch(btch, 5);

        Test.stopTest();

        Zuora__Subscription__c updatedSub = [SELECT Zuora__Account__c, ExpectedRenewalDate__c, Zuora__Status__c,SUB_Status__c
                                        FROM Zuora__Subscription__c
                                        LIMIT 1];

        System.assertEquals('Active', updatedSub.SUB_Status__c, 'Subscribe to C request is sent');
    }
}