/**
* Classe test pour WS03_SouscriptionAPI
* Couverture: 
* @author Yara Bourdoukan
* @date 2021-10-13
*/

@isTest
public class WS03_SouscriptionAPI_Test {
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
    public static void doGet_Test()
    {
        Zuora__Subscription__c sub =[SELECT Zuora__Account__c
                                     FROM Zuora__Subscription__c
                                     LIMIT 1];
        String restResourceRequestURI  = 'https://yourInstance.salesforce.com/services/apexrest/v1/souscriptions/';

        RestRequest request = new RestRequest();
        request.requestUri= restResourceRequestURI;
        request.httpMethod = SuiviObjects.post;
        request.addHeader('Content-Type', 'application/json');
        // // Set an empty body, no specific filters
        // request.requestBody = Blob.valueOf('{}');
        // Use filters to cover filter code
        request.requestBody = Blob.valueOf('{"Statut":["Pending Activation"],"CodeSouscription":["A-S00000400"],"Pays":["TG"],"Compte":["'+sub.Zuora__Account__c+'"]}');
        RestContext.request = request;        
        List<Zuora__Subscription__c> listSubscriptions = WS03_SouscriptionAPI.doGet();
        System.assertEquals(1, listSubscriptions.size(),'Expected Subscription record not found');
        System.assertEquals('Pending Activation', listSubscriptions[0].Zuora__Status__c,'Status filter is not applied');
        System.assertEquals(sub.Zuora__Account__c, listSubscriptions[0].Zuora__Account__c,'Account filter is not applied');

      
    }
}