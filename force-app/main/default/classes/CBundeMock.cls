/**
 * Classe pour simuler les appels API vers l'endpoint du stock de GVA
 */
@isTest
global class CBundeMock implements HttpCalloutMock {

    public boolean error = false;
    public boolean catchError = false;
    public Integer statusCode;

    public CBundeMock(){
        this.error = false;
        this.statusCode = 200;
    }

    public CBundeMock(boolean error, boolean catchError, Integer statusCode){
        this.error = error;
        this.catchError = catchError;
        this.statusCode = statusCode;
    }

    global HttpResponse respond(HTTPRequest request){
        String requestType = request.getEndpoint();

        HttpResponse response = new HttpResponse();
        try {
            if((requestType.contains(CBundleObjects.subscriptionAPIUrl) || requestType.contains(CBundleObjects.cancellationAPIUrl) || requestType.contains(CBundleObjects.modifyContactsAPIUrl)) && this.statusCode == 200) {
                // Set a sample response body for entity_site_ref=GABON-LBV-Entrepot, type_article_ref = NONNOK1G-240W-F
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"codeHttp" : 200,"returnCode" : "OK","message" : "SUBSCRIPTION SUCCESSFUL","severity" : "SUCCESS","errorMessageBeanList" : null,"data" : {"numabo" : "15980476","numabont" : "4","transactionId" : "23d2a9ca-8faf-458c-9ed3-cfc52e18cfe7"}}');
            } else if((requestType.contains(CBundleObjects.suspensionAPIUrl) || requestType.contains(CBundleObjects.materialExchangeAPIUrl) || requestType.contains(CBundleObjects.activationAPIUrl) || requestType.contains(CBundleObjects.modifyOffersAPIUrl) || requestType.contains(CBundleObjects.fastReactivationAPIUrl)) && this.statusCode == 200) {
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"codeHttp" : 200, "severity" : "SUCCESS","acquittementObject" : {"returnCode" : "OK", "message" : "", "severity" : "SUCCESS", "data" : null}}');
            } else if(requestType.contains(CBundleObjects.reactivationAPIUrl) && this.statusCode == 200){
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"codeHttp" : 201, "severity" : "SUCCESS","acquittementObject" : {"returnCode" : "OK", "message" : "", "severity" : "SUCCESS", "data" : null}}');
            } else if(requestType.contains(CBundleObjects.eligMigrationAPIUrl)  && this.statusCode == 200){
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{ "eligible": true, "endDate": "2022-09-29T18:43:44.970530" }');
            } else if(requestType.contains(CBundleObjects.requMigrationAPIUrl)  && this.statusCode == 200){
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"orderId": "634ed1389f7af33b17f88938", "personId": 918042, "activationDate": "2022-12-22 00:00:00" }');
            } else if(requestType.contains(CBundleObjects.cancelMigrationAPIURL)  && this.statusCode == 200){
                response.setStatusCode(204);
                response.setHeader('Content-Type', 'application/json');
            } else if(this.statusCode != 200 && (requestType.contains(CBundleObjects.eligMigrationAPIUrl) || requestType.contains(CBundleObjects.requMigrationAPIUrl) || requestType.contains(CBundleObjects.cancelMigrationAPIURL))){
                response.setStatusCode(422);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"title": "ERR_ELIGIBILITY_UNPROCESSED","status": 422,"detail": "Eligibility impossible due to functional error","instance": "BOMIESB","code": "Unprocessable Entity","correlationId": "null","timestamp": {"nano": 207941000,"epochSecond": 1665675783}}');
            }

            return response;
        }
        catch(Exception e) {
            throw new MyCustomException('HTTP callout not supported for test methods');
        }

    }
    public class MyCustomException extends Exception {}

}