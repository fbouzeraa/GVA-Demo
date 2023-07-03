/**
* Classe test pour WS01_SuiviCommandeAPI
* Couverture: 
* @author Maroun YAZBECK
* @date 2021-02-04
*/

@isTest
public class WS01_SuiviCommandeAPI_Test {
    @TestSetup
	static void makeData(){
        //Get a successful response from mock 
        //Prepare Mock
		Map<String, HttpCalloutMock> endpoint2TestResp = new Map<String, HttpCalloutMock>();
		endpoint2TestResp.put('callout:StockApiUrl', new StockMock());
		endpoint2TestResp.put('callout:ZuoraApiUrl', new ZuoraMock());
        endpoint2TestResp.put('callout:EligibilityApiUrl', new EligMock());
        endpoint2TestResp.put('callout:All_My_Sms', new SMSMock());
		Test.setMock(HttpCalloutMock.class, new MultiMock(endpoint2TestResp));
        
		TestUtils.createSub();
    }
    
    @isTest
    public static void testGetAndUpate()
    {
        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/suivis';

        RestRequest request = new RestRequest();
        request.requestUri= restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');
        // // Set an empty body, no specific filters
        // request.requestBody = Blob.valueOf('{}');
        // Use filters to cover filter code
        request.requestBody = Blob.valueOf('{"Actions":["ACT001","ACT002","ACT003"],"Pays":["FR","TGO","Togo","TG"]}');
        RestContext.request = request;        
        List<Suivi_de_Souscription__c> listSuivis = WS01_SuiviCommandeAPI.doGet();
        System.assertEquals(1, listSuivis.size(),'Expected Suivi record not found');
        System.assertEquals('STA001', listSuivis[0].SV_Statut__c,'Filter is not applied');


        // Provide Suivi record number to update and set the Statut as "Traité"
        request = new RestRequest();
        request.requestUri = restResourceRequestURI;
        request.httpMethod = 'PATCH';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('[{"ID":"'+ listSuivis[0].Id +'","referenceexterne":"REF1"}]');
        RestContext.request = request;
        // Update status of existing record
        List<SuiviObjects.SuiviUpdateResponse> updateResponse = WS01_SuiviCommandeAPI.doUpdate();
        System.assertEquals(true, updateResponse[0].success, 'Successful request expected');

        // Sending wrong ID value to generate an exception
        request.requestBody = Blob.valueOf('[{"ID":"'+ listSuivis[0].Id +'12121' +'","referenceexterne":"REF1"}]');
        RestContext.request = request;
        // Update status of existing record
        updateResponse = WS01_SuiviCommandeAPI.doUpdate();
        System.assertEquals(false, updateResponse[0].success, 'Error request expected');


        // Sending allong Reference Externe to generate an error
        request.requestBody = Blob.valueOf('[{"ID":"'+ listSuivis[0].Id +'","referenceexterne":"REF1RASDASDFAFAWFQ234234123412FEFADFAERGEERGAERGERGWTGWTRHWRTHWRTH32412341324"}]');
        RestContext.request = request;
        // Update status of existing record
        updateResponse = WS01_SuiviCommandeAPI.doUpdate();
        System.assertEquals(false, updateResponse[0].success, 'Error request expected');
    }
}