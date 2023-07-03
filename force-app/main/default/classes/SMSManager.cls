public with sharing class SMSManager {
/**
 * Methode utilisée pour exécuter un callout.
 * <p>
 * Cette méthode est utilisée pour tous les types de callouts et permet d'appeler la bonne destination
 * stock avec les bons paramètres suivant les paramètres passés dans la méthode.
 *
 * @param url Le lien vers l'API des stocks
 * @param body Le JSON de l'appel API envoyé
 * @return HttpResponse Un Objet Réponse HTTP
 */
    public static HttpResponse doCallout(String url, String body){
        HttpRequest request = new HttpRequest();
        //api key should be custom label
        string endpoint = url + '?login=' + System.label.ALLMYSMS_UserName + '&apiKey=' + System.label.ALLMYSMS_AUTH_TOKEN + '&smsData=' + body;
        request.setEndpoint('callout:SMSApiUrl' + endpoint);
        request.setMethod(SMSObjects.get);
        request.setTimeout(120000);
        // request.setHeader('Content - Type ', 'application / json ');
        // request.setHeader('Authorization ', 'Basic ' + Label.ALLMYSMS_AUTH_TOKEN);
        /* if(!String.isBlank(body)) {
             request.setBody(body);
           }*/
        HttpResponse response = new HttpResponse();
        Http http = new Http();

        response = http.send(request);

        return response;
    }
}