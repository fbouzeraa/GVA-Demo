public class MultiMock implements HttpCalloutMock, WebServiceMock {

    //set URL and corresponding mock
    Map<String, HttpCalloutMock> RESTRequests;
    Map<String, WebServiceMock> SOAPRequests;

    public MultiMock(Map<String, HttpCalloutMock> RESTRequests) {
        this.RESTRequests = RESTRequests;
    }
    public MultiMock(Map<String, WebServiceMock> SOAPRequests) {
        this.SOAPRequests = SOAPRequests;
    }

    public HTTPResponse respond(HTTPRequest req) {
        //get mock of requested url
        HttpCalloutMock mock = RESTRequests.get(req.getEndpoint().substring(0, req.getEndpoint().indexOf('/', 0)));

        if(mock != null) {
            return mock.respond(req);
        } else {
            throw new MyCustomException('HTTP callout not supported for test methods');
        }
    }
    public static void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint,
                                String soapAction, String requestName, String responseNS, String responseName, String responseType) {

        // WebServiceMock mock = endpoint.substring (0, endpoint.indexOf('/', 0));
    }

    public class MyCustomException extends Exception {}
}