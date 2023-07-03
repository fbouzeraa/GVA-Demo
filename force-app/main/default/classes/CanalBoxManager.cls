public with sharing class CanalBoxManager {

    /**
     * Methode utilisée pour verifier si le box existe en stock.
     * <p>
     * @param stockListing Une instance de l'objet de type CanalBoxObjects.StockListing
     * @return HttpResponse
     **/

    public static HttpResponse stockAvailability(CanalBoxObjects.StockListing stockListing){

        return doCallout(CanalBoxObjects.stockListingAPIUrl, JSON.serialize(stockListing, true));
    }

    /**
     * Methode utilisée pour reserver un box
     * <p>
     * @param stockReserving Une instance de l'objet de type CanalBoxObjects.StockReservationLiberation
     * @return HttpResponse
     **/

    public static HttpResponse boxReservation(CanalBoxObjects.StockReservationLiberation stockReserving){

        return doCallout(CanalBoxObjects.stockReservingAPIUrl, JSON.serialize(stockReserving, true));
    }
/**
 * Methode utilisée pour liberer un box
 * <p>
 * @param stockLiberation Une instance de l'objet de type CanalBoxObjects.StockReservationLiberation
 * @return HttpResponse
 **/

    public static HttpResponse boxLiberation(CanalBoxObjects.StockReservationLiberation stockLiberation){

        return doCallout(CanalBoxObjects.stockLiberationAPIUrl, JSON.serialize(stockLiberation, true));
    }
    /**
     * Methode utilisée pour reserver un box
     * <p>
     * @param order Une instance de l'objet de type CanalBoxObjects.Orders
     * @return HttpResponse
     **/

    public static HttpResponse boxInstallation(CanalBoxObjects.Orders order){

        return doCallout(CanalBoxObjects.ordersAPIUrl, JSON.serialize(order, true));
    }
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
        request.setEndpoint('callout:StockApiUrl' + url);
        request.setMethod(CanalBoxObjects.post);
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        // request.setHeader('Accept', 'application/json');
        if(!String.isBlank(body)) {
            request.setBody(body);
        }
        HttpResponse response = new HttpResponse();
        Http http = new Http();
        response = http.send(request);

        return response;
    }
}