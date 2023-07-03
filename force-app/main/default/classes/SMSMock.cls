/**
 * Classe pour simuler les appels API vers l'endpoint d'envoi d'SMS
 */
@isTest
global class SMSMock implements HttpCalloutMock {

    public boolean error = false;
    public boolean catchError = false;
    public Integer statusCode;

    public SMSMock(){
        this.error = false;
        this.statusCode = 200;
    }

    public SMSMock(boolean error, boolean catchError, Integer statusCode){
        this.error = error;
        this.catchError = catchError;
        this.statusCode = statusCode;
    }

    global HttpResponse respond(HTTPRequest request){
        String requestType = request.getEndpoint();

        HttpResponse response = new HttpResponse();
        try {

            if(requestType.contains(SMSObjects.smsBulkAPIUrl) && this.statusCode == 200) {
                // Set a sample response body
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"status": 100,"description": "Your messages have been sent","invalidNumbers": "","campaignId": "3118769098039","nbContacts": 2,"nbSms": 2,"balance": 3.10,"cost": 0.090,"smsIds": [{"smsId": "69276b1a-4cbc-11e9-a8ef-0025907cf72e","phoneNumber": "228612345678"},{"smsId": "69276ff8-4cbc-11e9-a8ef-0025907cf72e","phoneNumber": "228612345679"}]}');
            } else if(requestType.contains(SMSObjects.smsBulkAPIUrl) && this.statusCode != 200) {
                // Set a sample response body for wrong data
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"code": 114,"description": "no valid recipient found"}');
            }

            return response;
        }
        catch(Exception e) {
            throw new MyCustomException('HTTP callout not supported for test methods');
        }

    }
    public class MyCustomException extends Exception {}

}