public with sharing class BizaoManager {
    /**
     * Methode utilisée pour exécuter un callout.
     * <p>
     * Cette méthode est utilisée pour tous les types de callouts et permet d'appeler la bonne destination
     * stock avec les bons paramètres suivant les paramètres passés dans la méthode.
     *
     * @param url Le lien vers l'API des Bizao Mobile Money
     * @param body Le JSON de l'appel API envoyé
     * @return HttpResponse Un Objet Réponse HTTP
     */
    public static HttpResponse mobileMoneyCallout(String url, String body, string method, string operator, string userCountryCode){

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:BizaoApiUrl' + url );
        request.setMethod(method);
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        string authToken;

        // Pre-prod Bizao
        // authToken = CIV ==> 'b2f43d6e-34c6-3309-81f4-0572bca5599a';  // Bf==>'e16eb780-7eab-305d-bbc1-72175ca0a583';
        // Prod Bizao
        // authToken = CIV ==> 'e9191a09-183d-3f0a-877f-13daa40e7594'; // BF ==> '8a6812a1-df8c-314a-92c4-973c28c25af4';   
        if(userCountryCode == 'BF') {
            authToken = System.Label.MMAuthentication;
        } else if(userCountryCode == 'CI') {
            authToken = System.Label.MMAuthentication_CIV_MobileMoney;
        }
        else if(userCountryCode == 'CD') {
            authToken = System.Label.MMAuthentication_CD;
        }

        // Cookie : SERVERID=s0; SERVERID=s0; SERVERID=s0; route=1674465950.166.35.813320|81ae3a9a04c06b83bdb4bb4311fcd72d
        request.setHeader('Authorization', 'Bearer ' + authToken);
        request.setHeader('mno-name', operator.toLowerCase());
        request.setHeader('country-code', userCountryCode.toLowerCase());
        request.setHeader('channel','web');
        if(operator != null && !string.isBlank(operator)) {
            request.setHeader('lang', 'fr');
            request.setHeader('channel', 'web');
        }
        if(!String.isBlank(body)) {
            body = body.replaceAll('_Reserved', '');
            request.setBody(body);
        }
        System.debug('requete '+ request);
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        response = http.send(request);

        return response;
    }

    /**
     * Methode utilisée pour exécuter un callout.
     * <p>
     * Cette méthode est utilisée pour tous les types de callouts et permet d'appeler la bonne destination
     * stock avec les bons paramètres suivant les paramètres passés dans la méthode.
     *
     * @param url Le lien vers l'API des Bizao Mobile Money
     * @param body Le JSON de l'appel API envoyé
     * @return HttpResponse Un Objet Réponse HTTP
     */
    public static HttpResponse debitCardCallout(String url, String body, string method, string userCountryCode){

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:BizaoApiUrl' + url );
        request.setMethod(method);
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        string authToken;
        if(userCountryCode == 'BF') {
            authToken = System.Label.CMAuthentication;
         } else if(userCountryCode == 'CI') {
            authToken = System.Label.CMAuthentication_CIV;
            
         }

         else if(userCountryCode == 'CD') {
            authToken = System.Label.CMAuthentication_CD;
            
         }
        // Pre prod Bizao
        //authToken = '1ad08a98-8824-3c2e-b5df-064a5de4c112';
        //  Prod Bizao
        // authToken = '1d53eddc-192a-33af-a4e8-d1bf956f3707';  CIV==> 9ce346ed-014f-3607-ae3e-28bd614ef2af
        request.setHeader('Authorization', 'Bearer ' + authToken);
        request.setHeader('country-code', userCountryCode.toLowerCase());
        request.setHeader('lang', 'fr');
        request.setHeader('category', 'BIZAO'); // Prod : BIZAO 
        if(!String.isBlank(body)) {
            body = body.replaceAll('_Reserved', '');
            request.setBody(body);
        }
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        response = http.send(request);

        return response;
    }
}