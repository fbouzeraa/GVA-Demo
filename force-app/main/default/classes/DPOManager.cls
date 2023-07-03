/**
 * Classe permettant de définir la méthode d'appel vers DPO et le callout API vers DPO.
 *
 * @author Yara Bourdoukan
 * @date 3 Decembre 2021
 */
public with sharing class DPOManager {
    /**
     * Methode utilisée pour exécuter un callout.
     * <p>
     * Cette méthode est utilisée pour tous les types de callouts et permet d'appeler la bonne destination
     * éligibilité avec les bons paramètres suivant les paramètres passés dans la méthode.
     *
     * @param url Le lien vers l'API d'éligibilité
     * @param method La méthode HTTP de l'appel API d'éligibilité: POST, PUT ou GET
     * @param body Le JSON de l'appel API envoyé au test d'éligibilité
     * @return HttpResponse Un Objet Réponse HTTP
     */
    public static HttpResponse doCallout(String url, String method, String body){
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:DPOApiUrl' + url);
        request.setMethod(method);
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/xml');
        //request.setHeader('Accept', 'application/json');

        if(!String.isBlank(body)) {

            request.setBody(body);
        }

        system.debug('dpo request '+request);

        Http http = new Http();
        HttpResponse response  = http.send(request);

        return response;
    }
}