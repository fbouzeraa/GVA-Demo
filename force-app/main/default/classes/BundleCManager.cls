public with sharing class BundleCManager {
    /**
     * Methode utilisée pour exécuter un callout dans CGA WEB.
     * <p>
     * Cette méthode est utilisée pour tous les types de callouts et permet d'appeler la bonne destination
     * Zuora avec les bons paramètres suivant les paramètres passés dans la méthode.
     *
     * @param url Le lien vers l'API Zuora
     * @param method La méthode HTTP de l'appel API Zuora: POST, PUT ou GET
     * @param body Le JSON de l'appel API envoyé à Zuora
     * @return HttpResponse Un Objet Réponse HTTP
     */
    public static HttpResponse doCallout(String url, String method, String body) {
        String username = System.label.CGA_Username;
        String password = System.label.CGA_Password;
        // Create blob of user:pass
        Blob headerValue = Blob.valueOf(username + ':' + password);
        // Base 64 Encode the blob and prepend "Basic "
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:CGAWeb' + System.Label.Partners_API_URL + url);
        request.setMethod(method);
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', authorizationHeader);

        if(!string.isEmpty(body) && !string.isBlank(body)) {
            body = body.replaceAll('_toReplace', '');
            body = body.replaceAll('_Reserved', '__c');
            request.setBody(body);
        }
        HttpResponse response = new HttpResponse();

        Http http = new Http();
        response = http.send(request);

        return response;
    }

    public static HttpResponse migrationCallout(String url, String method, String body, Boolean withParameters, String countrycode){

        // EligMigration --> PUT // 
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:CanalMigrationAPI' + url);
        request.setMethod(method);
       // request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('x-api-key',system.label.Canal_Migration_Key);
        request.setBody(body);

        if(withParameters) {
            request.setHeader('userId', 'WS_GVA');
            request.setHeader('countryCode', countrycode);
            request.setHeader('saleDeviceId', 'PARTENAIRE');
        }

        HttpResponse response = new HttpResponse();
        Http http = new Http();
        response = http.send(request);

        return response;
    }
}