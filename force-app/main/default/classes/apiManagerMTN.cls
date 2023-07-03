public class apiManagerMTN {
    
    public static String getToken()
    {
        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:MTNAPIURL'+'/collection/token/');
            request.setMethod('POST');
            request.setTimeout(120000);
            request.setHeader('Authorization', System.Label.token_authorization);
            request.setHeader('Ocp-Apim-Subscription-Key',System.Label.MTN_Subscription_Key);
            request.setHeader('Content-Length', '0');
            HttpResponse response = http.send(request);

            MTNObjects.TokenResponse getTokenResponse = (MTNObjects.TokenResponse) JSON.deserialize(response.getBody(), MTNObjects.TokenResponse.class);


            String theToken = getTokenResponse.access_token;

            return theToken;
        }
        catch(exception e) {
            System.debug('API is unavailable:' + e.getMessage());
            return null;
        }

     }
    
    @AuraEnabled(cacheable=true)
    public static String callout(String transactionId, String strJSON, String method, String requesttopayAPIUrl){
        
        String theToken =  getToken();
        try{
            String addParam = '';
            if(strJSON == null){
                addParam = '?referenceId='+transactionId;
            }

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:MTNAPIURL'+requesttopayAPIUrl+addParam);
            request.setMethod(method);
            request.setTimeout(120000);
            request.setHeader('Authorization', 'Bearer '+theToken);
            request.setHeader('Ocp-Apim-Subscription-Key',System.Label.MTN_Subscription_Key);
            request.setHeader('X-Target-Environment',System.Label.MTN_Congo_TargetEnviroment);
            request.setHeader('X-Reference-Id',transactionId);
            
            if(strJSON != null){
                request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                request.setBody(strJSON);
                request.setHeader('Content-Length', String.valueOf(strJSON.length()));  
            }else{
                request.setHeader('Content-Length', '0');  
            }

            HTTPResponse res = http.send(request);

            // when the request body is null it's in the case of getstatus a response body is returned
            String retrunResponse = strJSON != null ? String.valueOf(res.getStatusCode()) : res.getBody();
            return retrunResponse;
        } 
        catch(exception e) {
            System.debug('API is unavailable:'+e.getMessage());
            return e.getMessage();
        }
    }
}