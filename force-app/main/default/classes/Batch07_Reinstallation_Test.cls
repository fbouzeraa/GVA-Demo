@isTest
public class Batch07_Reinstallation_Test {
    @TestSetup
    public static void makeData() {
        //Prepare Mock
        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));

        TestUtils.createSub();
    }
    @isTest
    static void ResumeSubscription(){
        Zuora__Subscription__c newSub = [SELECT Id, Name, Quote__c, Zuora__Status__c
                                         FROM Zuora__Subscription__c
                                         LIMIT 1];
        Suivi_de_Souscription__c suivi = new Suivi_de_Souscription__c(SV_Id_Souscription__c = newSub.Id, SV_Code_Action__C = 'ACT007',
                                                                      SV_Reference_Externe__c = '1234', SV_Statut__c = 'STA002');
        insert suivi;
        Suivi_de_Souscription__c suivi1 = new Suivi_de_Souscription__c(SV_Id_Souscription__c = newSub.Id, SV_Code_Action__C = 'ACT007',
                                                                       SV_Reference_Externe__c = '1234', SV_Statut__c = 'STA002');
        insert suivi1;
        newSub.Zuora__Status__c = 'Suspended';
        update newSub;

        Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
        endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
        endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        Database.executeBatch(new Batch07_Reinstallation(), 100);
        Test.stopTest();
        list<Suivi_de_Souscription__c> listSuivi = [SELECT id, SV_Reference_Externe__c
                                                    FROM Suivi_de_Souscription__c
                                                    WHERE SV_Code_Action__c = 'ACT003'];
        System.assertEquals(true, listSuivi.size() == 2, '2 Follow up should be created');
    }

}