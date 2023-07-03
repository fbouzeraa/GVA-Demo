/**
 * Classe pour simuler les appels API vers l'endpoint du Bizao
 *
 * @author Yara Bourdoukan
 * @date 3 Mars 2022
 */
@isTest
global class BizaoMock implements HttpCalloutMock {
    public boolean error = false;
    public boolean catchError = false;
    public Integer statusCode;

    public BizaoMock(){
        this.error = false;
        this.statusCode = 200;
    }

    public BizaoMock(boolean error, boolean catchError, Integer statusCode){
        this.error = error;
        this.catchError = catchError;
        this.statusCode = statusCode;
    }
    global HttpResponse respond(HTTPRequest request){
        String endpoint = request.getEndpoint();

        HttpResponse response = new HttpResponse();
        if(endpoint.contains(BIZAObjects.MobileMoneyAPIUrl) && this.statusCode == 200 && !endpoint.contains(BIZAObjects.MobileMoneyStatusAPIUrl)) {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody( '{"order_id": "M-S24359658001-2022331451", "status" : 201, "payment_token": "f8d3f99b5c64e07a3993c907ac48ef393889945d5134a7b9a531542e6eddc20", "payment_url": "https://preproduction-mm-webpayment.bizao.com/mm-p…7a3993c907ac48ef393889945d5134a7b9a531542e6eddc20", "state": "Processing"}');
        } else if((endpoint.contains(BIZAObjects.MobileMoneyAPIUrl) || endpoint.contains(BIZAObjects.DebitCardAPIURL)) && this.statusCode != 200  && !endpoint.contains(BIZAObjects.MobileMoneyStatusAPIUrl)) {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody( '{"requestError" :{"serviceException":{"messageId": "SVC0002","text": "Invalid input value for message part %1","variables": "Invalid mno name"}}}');
        } else if(endpoint.contains(BIZAObjects.MobileMoneyStatusAPIUrl) ) {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody( '{"meta" : {"type" : "payment","source" : "bf_orange_mm","channel" : "web"},"status" : "Successful","amount" : "100","order-id" : "M-S24359658001-202233154","currency" : "XOF","reference" : "GVA_BF","date" : "2022-03-03 15:05:03.0","country-code" : "bf","state" : "Processing","user_msisdn" : "","intTransaction-id" : "","extTransaction-id" : ""}');
        } else if(endpoint.contains(BIZAObjects.DebitCardAPIURL) ) {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody( '{"status" : 201, "message" : "OK", "payment_token" : "31fe70a8-6948-453b-bae5-3a927281a343", "order_id" : "M-S24359658001-2022331513", "state" : "Processing", "payment_url" : "https://migs.mastercard.com.au/vpcpay?vpc_AccessCode=4058C749&vpc_Amount=100&vpc_Command=pay&vpc_Currency=XOF&vpc_Locale=fr&vpc_MerchTxnRef=31fe70a8-6948-453b-bae5-3a927281a343&vpc_Merchant=ECI0059&vpc_OrderInfo=M-S24359658001-2022331513&vpc_ReturnURL=https%3A%2F%2Fpreproduction-gateway.bizao.com%2Fecobanq%2Fci%2Fredir%2Fv1&vpc_SecureHash=89668DCAEB020B8924EF16134FFC1C82D3B92D20BCEF6A9642B53B3CBD90C62F&vpc_SecureHashType=SHA256&vpc_Version=1"}');
        } else if(endpoint.contains(BIZAObjects.DebitCardStatusAPIUrl) ) {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody( '{"meta" : {"type" : "payment","source" : "ci_","category" : "BIZAO-RETAIL"},"status" : "Successful","amount" : "100.00","order-id" : "M-S24359658001-2022331513","currency" : "XOF","reference" : "GVA_BF","date" : "2022-03-03 15:13:37.0","country-code" : "ci","state" : "Processing","intTransaction-id" : "31fe70a8-6948-453b-bae5-3a927281a343","extTransaction-id" : ""}');
        } else {
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody( '{}');
        }

        return response;
    }
}