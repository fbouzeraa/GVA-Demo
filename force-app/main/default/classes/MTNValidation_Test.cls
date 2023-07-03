@isTest
public with sharing class MTNValidation_Test {
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
    static void doPost_Test(){
        /*    //private static final String RESOURCE_PATH = '/services/apexrest' + RESOURCE_URL;
            RestRequest request = new RestRequest();
            request.addHeader('Content-Type', 'application/json');
            request.requestUri = '/v1/Subscription/CheckAccount';
            request.httpMethod = 'POST';
            request.resourcePath =  '/services/apexrest';
            request.requestBody = Blob.valueOf('{"BoxNumber":"ALCL001","AccountCurrency":"XOF","CountryCode":"TG","OperationType":1,"OperatorTYpe":"Orange"}');

            RestContext.request = request;

            RestContext.Response = new RestResponse();
            WS04_MTNAPI.handlePost();*/
    }
}