/**
 * Classe pour simuler les appels API vers l'endpoint du MTN Congo
 *
 * @author Jackie Abi NAssif
 * @date 23 Mai 2023
 */
@isTest
global class MTNMock implements HttpCalloutMock {

    global HttpResponse respond(HTTPRequest request){
        String endpoint = request.getEndpoint();

        HttpResponse response = new HttpResponse();

            if(endpoint.contains(System.Label.MTNApiUrl+'token/')) {
                response.setStatusCode(200);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSMjU2In0.eyJjbGllbnRJZCI6IjZmOTJlMTRlLWE0OTgtNGVkOS1iZGFiLTg4OTA0N2U4ZjgwNiIsImV4cGlyZXMiOiIyMDIzLTA1LTIzVDA5OjUyOjIwLjIyNCIsInNlc3Npb25JZCI6IjIzNWU5MDFiLTFjNmMtNDZlMS1iNjM2LTY2YWQ0OWVjMWQwOSJ9.YeIZq5fdlIdytNj6LG_WEHj74yo8s1yWh7NMmHlajkGKytkpOSrh6Y5JHgpOsk6lFwvwuDSKlzq7ES-45CkLS1Xg3Zbz22rA_3qJoNPCdz89Po5wGlWhuM0fOnYIQ3iacQ_Sy3yRm7LE0ToZQKZlgzRnRpY1K3P6bHR34Rb1NOS_l4c7YCtTjlp0VAP-MOO2dfDFPgiL-8QXCEZGEJPqBPVuN58pFuNFnlxoc3IqikZJy6NAqzquzVxU9q_2jZSZkaFcITFhFATsCCkKXlz0KINzkuKfUAv7ZFuIR2-MVh53hZcNR4n7GD5Zq6oM0Jf4iZVz1NoSQu122orohygnPQ","token_type":"access_token","expires_in":3600}');
            } else if(endpoint.contains(MTNObjects.requesttopayAPIUrl+'?')) {
                response.setStatusCode(200);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"amount": "100","currency": "UGX", "financialTransactionId": "23503452", "externalId": "947354","payer": {"partyIdType": "MSISDN","partyId": 4656473839.0},"status": "SUCCESSFUL"}');
            } else if(endpoint.contains(MTNObjects.requesttopayAPIUrl)) {
                response.setStatusCode(202);
                response.setHeader('Content-Type', 'application/json');
            }else{
                response.setStatusCode(400);
            }

        return response;
    }
    public class MyCustomException extends Exception {}
}