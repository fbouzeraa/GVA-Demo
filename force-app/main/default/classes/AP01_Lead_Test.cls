/**
 * Classe test pour AP01_Lead
 * Couverture: 88%
 * @author Maroun Yazbeck
 * @date 23 Février 2021
 */
@isTest
public class AP01_Lead_Test {
	@isTest
	public static void lead_Test()
	{
		//Get a successful response from mock
		Test.setMock(HttpCalloutMock.class, new EligMock());
        Test.startTest();
		Lead piste = new Lead(FirstName = 'FN1',LastName = 'Test 1', LEA_IDBatiment__c = 'KIG_97341');
		Lead piste2 = new Lead(FirstName = 'FN2',LastName = 'Test 2', LEA_IDBatiment__c = 'KIG_97342');
		Lead piste3 = new Lead(FirstName = 'FN3',LastName = 'Test 3', LEA_IDBatiment__c = 'KIG_97343');
		List<Lead> listLeads = new List<Lead>{piste, piste2, piste3};
        insert listLeads;

		Test.stopTest();

		list<Lead> listCheckLead = [SELECT Id, LEA_Quartier__c FROM Lead];
		System.assertEquals('Kiyovu',listCheckLead[0].LEA_Quartier__c,'Lead not updated');
		piste.LEA_IDBatiment__c ='QAS-123';
		update piste;
		System.assertEquals('QAS-123', piste.LEA_IDBatiment__c,'Lead not updated');
	}
}