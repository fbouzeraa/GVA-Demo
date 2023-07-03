/**
 * Classe test pour Batch03_RapportDeCaisse
 * Couverture: 100%
 */
@isTest
public class Batch03_RapportDeCaisse_Test {

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
    static void testSucceededReport(){

        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système'];
        user myTestUser1 = TestUtils.createUser('example1@test.com', 'lastName1', 'y.bourdoukan@gva.africa', 'USER123', p.Id);
        user myTestUser2 = TestUtils.createUser('example2@test.com', 'lastName2', 'y.bourdoukan@gva.africa', 'USER345', p.Id);
        user myTestUser3 = TestUtils.createUser('example3@test.com', 'lastName3', 'y.bourdoukan@gva.africa', 'USER678', p.Id);

        // Test  Batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock());

        Database.executeBatch(new Batch03_RapportDeCaisse(), 1);
        Test.stopTest();
    }
    @isTest
    static void testFailedReport(){
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' OR Name = 'Administrateur système'];
        user myTestUser1 = TestUtils.createUser('example1@test.com', 'lastName1', 'y.bourdoukan@gva.africa', 'USER123', p.Id);
        user myTestUser2 = TestUtils.createUser('example2@test.com', 'lastName2', 'y.bourdoukan@gva.africa', 'USER345', p.Id);
        user myTestUser3 = TestUtils.createUser('example3@test.com', 'lastName3', 'y.bourdoukan@gva.africa', 'USER678', p.Id);

        // Test  Batch
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ZuoraMock(false, false, 400));
        String cronExpr = '0 0 23 * * ?';
        RapportDeCaisseScheduler rapport = new RapportDeCaisseScheduler();
        String jobId = System.schedule('myJobTestJobName', cronExpr, rapport);

        Test.stopTest();
    }

}