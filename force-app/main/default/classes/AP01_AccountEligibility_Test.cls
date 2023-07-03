/**
 * Classe test pour AP01_AccountEligibility
 * Couverture: 88%
 * @author Yara Bourdoukan
 * @date 1 Decembre 2020
 */
@isTest
public class AP01_AccountEligibility_Test {
    @isTest
    public static void accountEligibilityTest_Test(){
        //Get a successful response from mock
        Test.setMock(HttpCalloutMock.class, new EligMock());

        Account acc = TestUtils.createPersonAccount('Test');
        insert acc;
        Account acc2 = TestUtils.createPersonAccount('Test2');
        insert acc2;
        Account acc3 = TestUtils.createPersonAccount('Test3');
        insert acc3;
        list<account> listAccount = new list<Account>();
        // map<string,id> newmap = new map<string,id>();
        // newmap.put(acc.ACC_BuildingID__c,acc.id);
        // newmap.put(acc2.ACC_BuildingID__c,acc2.id);
        Set<Id> newSet = new Set<Id> {acc.Id, acc2.Id};

        Test.startTest();
        // AP01_AccountEligibility.checkEligibility(newmap);
        AP01_AccountEligibility.checkEligibility(newSet);
        AP01_AccountEligibility.fillAccountFields(acc3.Id);
        Test.stopTest();
        list<Account> listCheckAccount = [SELECT Id, ACC_Eligible__c From Account];
        System.assertEquals(True, listCheckAccount[0].ACC_Eligible__c, 'Account not updated');
        acc.ACC_BuildingID__c = 'QAS_123';
        update acc;
        System.assertEquals('QAS_123', acc.ACC_BuildingID__c, 'Account not updated');
    }
}