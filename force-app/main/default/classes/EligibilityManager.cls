/**
 * Classe permettant de définir la méthode d'appel vers l'éligibilité et le callout API vers l'éligibilité.
 *
 * @author Yara Bourdoukan
 * @date 3 Decembre 2020
 */
public class EligibilityManager {
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
        HttpResponse response = new HttpResponse();
        try {
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint('callout:EligibilityApiUrl' + url);
            request.setMethod(method);
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Accept', 'application/json');
            request.setHeader('Authorization', 'Token ' + System.Label.ELIG_API_Access_Token);
            if(!String.isBlank(body)) {
                request.setBody(body);
            }
            //System.debug('Request for Elig Endpoint:' + request);
    

            Http http = new Http();
    
            response = http.send(request);
        } catch (Exception e) {
            system.debug('elig callOut '+e.getMessage());
        }


        return response;
    }

}