/**
 * Classe permettant de définir les différentes méthodes d'appels vers Zuora et le callout API vers Zuora.
 *
 * @author Bilal El Aly
 * @date 2 Novembre 2020
 */
public class ZuoraManager {
    /**
     * Methode utilisée pour Créer ou Mettre à jour un Compte dans Zuora.
     * <p>
     * La méthode vérifie si l'objet passé en paramètre contient un ID pour décider si c'est le cas d'un Update ou un Insert.
     *
     * @param zuoraAccount Une instance de l'objet de type ZuoraObjects.ZuoraAccount
     * @return Http Response
     */
    public static HttpResponse createOrUpdateAccount(ZuoraObjects.ZuoraAccount zuoraAccount) {
        String methodType;
        String apiURL = ZuoraObjects.accountAPIUrl;

        if(zuoraAccount != null) {
            if(String.isNotBlank(zuoraAccount.existingID)) {
                methodType = ZuoraObjects.put;
                apiURL += zuoraAccount.existingID;
                zuoraAccount.existingID = null;
            } else {
                methodType = ZuoraObjects.post;
            }

            return doCallout(apiURL, methodType, JSON.serialize(zuoraAccount, true));
        } else {
            return null;
        }
    }
    /**
     * Methode utilisée pour Mettre à jour un Compte dans Zuora.
     *
     * @param zuoraAccount Une instance de l'objet de type ZuoraObjects.ZuoraAccount,
     * @param accountNumber id du compte (customer account)
     * @return Http Response
     */
    public static HttpResponse updateZuoraAccount(ZuoraObjects.ZuoraUpdateAccount zuoraAccount, string zuoraAccountId){
        String apiURL;
        apiURL = ZuoraObjects.updateAccountAPIUrl + zuoraAccountId;

        return doCallout(apiURL, ZuoraObjects.put, JSON.serialize(zuoraAccount, true));
    }
    /**
     * Methode utilisée pour récupèrer les informations de base d'un Compte dans Zuora.
     *
     * @param accountNumber numero du compte (customer account)
     * @return Http Response
     */
    public static HttpResponse getZuoraAccount(string accountNumber) {
        String apiURL;
        apiURL = ZuoraObjects.accountAPIUrl + accountNumber;

        return doCallout(apiURL, ZuoraObjects.get, '');
    }
    /**
     * Methode utilisée pour récupèrer les informations de base d'un Compte dans Zuora.
     *
     * @param accountNumber id du compte (customer account)
     * @return Http Response
     */
    public static HttpResponse getAccountSummary(string accountId) {
        String apiURL = ZuoraObjects.accountAPIUrl + accountId + '/summary';

        return doCallout(apiURL, ZuoraObjects.get, '');
    }

    /**
     * Methode utilisée pour Créer ou Mettre à jour un Contact dans Zuora.
     * <p>
     * La méthode vérifie si l'objet passé en paramètre contient un ID pour décider si c'est le cas d'un Update ou un Insert.
     *
     * @param zuoraContact Une instance de l'objet de type ZuoraObjects.ZuoraContact
     */
    public static void createOrUpdateContact(ZuoraObjects.ZuoraContact zuoraContact) {
        String methodType;
        String apiURL = ZuoraObjects.contactAPIUrl;

        if(zuoraContact != null) {
            if(String.isNotBlank(zuoraContact.existingID)) {
                methodType = ZuoraObjects.put;
                apiURL += zuoraContact.existingID;
                zuoraContact.existingID = null;
            } else {
                methodType = ZuoraObjects.post;
            }

            doCallout(apiURL, methodType, JSON.serialize(zuoraContact, true));
        }
    }
    /**
     * Methode utilisée pour Créer un ordre dans Zuora.
     * <p>
     * La méthode vérifie le type de l'ordre.
     *
     * @param zuoraOrder Une instance de l'objet de type ZuoraObjects.ZuoraOrder,
     * @param orderType le type de l'ordre : NEW_SUBSCRIPTION,ADD_PRODUCT,
     * REMOVE_PRODUCT,UPDATE_PRODUCT, RENEW_SUBSCRIPTION, TERMS_CONDITIONS, SUSPEND, RESUME
     */
    public static HttpResponse createOrder(ZuoraObjects.ZuoraOrder zuoraOrder, ZuoraObjects.OrderType orderType) {
        string methodType;
        String apiURL = ZuoraObjects.ordersAPIUrl;
        switch on orderType {
            when NEW_SUBSCRIPTION, CANCEL_SUBSCRIPTION, RENEW_SUBSCRIPTION, SUSPEND, ADD_PRODUCT, REMOVE_PRODUCT {
                methodType = ZuoraObjects.post;

                return doCallout(apiURL, methodType, JSON.serialize(zuoraOrder, true).replaceAll('_h', '__h'));
            }
            when else {
                return null;
            }
        }
    }

    /**
     * Methode utilisée pour mettre a jour les dates trigger d'un ordre dans Zuora.
     * <p>
     * @param zuoraOrder Une instance de l'objet de type ZuoraObjects.ZuoraOrder
     * @param orderNumber numero de la commande
     * @return HttpResponse
     **/
    public static HttpResponse updateTriggerOrder(ZuoraObjects.ZuoraOrder zuoraOrder, string orderNumber){
        String apiURL = ZuoraObjects.ordersAPIUrl + orderNumber +  ZuoraObjects.activateOrdersAPIUrl;

        return doCallout( apiURL, ZuoraObjects.put, JSON.serialize(zuoraOrder, true));
    }
    /**
     * Methode utilisée pour mettre a jour les champs personalise d'un abonnement dans Zuora.
     * <p>
     * @param zuoraSub Une instance de l'objet de type ZuoraObjects.ZuoraOrderSubscription
     * @param subscriptionNumber numero de l'abonnement
     * @return HttpResponse
     **/
    public static HttpResponse updateSubscriptionCustomFields( ZuoraObjects.ZuoraOrderSubscription zuoraSub, string subscriptionNumber){
        // /v1/subscriptions/number/customFields
        String apiURL = ZuoraObjects.subscriptionAPIUrl + subscriptionNumber + '/customFields';

        return doCallout(apiURL, ZuoraObjects.put, JSON.serialize(zuoraSub, true));
    }
    /**
     * Methode utilisée pour afficher l'apercu d'un abonnement dans Zuora.
     * <p>
     * @param subscriptionId id de l'abonnement
     * @return HttpResponse
     **/
    public static HttpResponse susbcriptionPreview( string subscriptionId){
        return doCallout(ZuoraObjects.subscriptionAPIUrl + subscriptionId, ZuoraObjects.get, '');
    }
    /**
     * Methode utilisée pour créer un paiemant.
     * <p>
     * @param paymentInfo Une instance de l'objet de type ZuoraObjects.ZuoraPayment
     * @return HttpResponse
     **/
    public static HttpResponse createPayment( ZuoraObjects.ZuoraPayment paymentInfo){
        return doCallout(ZuoraObjects.paymentAPIUrl, ZuoraObjects.post, JSON.serialize(paymentInfo, true));
    }
    /**
     * Methode utilisée pour chercher un paiemant.
     * <p>
     * @param paymentId id du paiement
     * @return HttpResponse
     **/
    public static HttpResponse getPayment( string paymentId){
        return doCallout(ZuoraObjects.paymentAPIUrl + paymentId, ZuoraObjects.get, '');
    }
    /**
     * Methode utilisée pour faire un refund d'un payment.
     * <p>
     * @param paymentInfo Une instance de l'objet de type ZuoraObjects.ZuoraPayment
     * @param paymentId id du paiement
     * @return HttpResponse
     **/
    public static HttpResponse createRefundPayment(ZuoraObjects.ZuoraRefundPayment paymentInfo, string paymentId){
        string url = ZuoraObjects.paymentAPIUrl + paymentId + '/refunds';

        return doCallout(url, ZuoraObjects.post, JSON.serialize(paymentInfo, true));
    }
    /**
     * Methode utilisée pour appliquer un paiemant sur la facture.
     * <p>
     * @param paymentInfo Une instance de l'objet de type ZuoraObjects.ZuoraPayment
     * @param paymentId id du paiement
     * @return HttpResponse
     **/
    public static HttpResponse applyPayment(ZuoraObjects.ZuoraPayment paymentInfo, string paymentId){
        string url = ZuoraObjects.paymentAPIUrl + paymentId + '/apply';

        return doCallout(url, ZuoraObjects.put, JSON.serialize(paymentInfo, true));
    }
    /**
     * Methode utilisée pour créer un preview de la souscription.
     * <p>
     * @param zuoraOrder Une instance de l'objet de type ZuoraObjects.ZuoraOrder
     * @return HttpResponse
     **/
    public static HttpResponse previewOrder(ZuoraObjects.ZuoraOrder zuoraOrder) {
        return doCallout(ZuoraObjects.previewOrdersAPIUrl, ZuoraObjects.post, JSON.serialize(zuoraOrder, true));
    }

    /**
     * Methode utilisée pour créer une facture pour un compte
     * <p>
     * @param ZuoraBilling Une instance de l'objet de type ZuoraObjects.ZuoraBilling
     * @param zAccountId id du customer account
     * @return HttpResponse
     **/
    public static HttpResponse CreateBillByAccount(ZuoraObjects.ZuoraBilling ZuoraBilling, string zAccountId){
        String apiURL = ZuoraObjects.accountAPIUrl + zAccountId + ZuoraObjects.billAPIUrl;

        return doCallout(apiURL, ZuoraObjects.post, JSON.serialize(ZuoraBilling, true));
    }
    /**
     * Methode utilisée pour vider des champs dans zuora.
     * <p>
     * @param nullFields objet des champs vide
     * @return HttpResponse
     **/

    public static HttpResponse emptyFields(ZuoraObjects.ZuoraNullFields nullFields) {

        return doCallout(ZuoraObjects.nullFieldsAPIUrl, ZuoraObjects.post, JSON.serialize(nullFields, true));
    }
    /**
     * Methode utilisée pour obtenir le contenu de la facture.
     * <p>
     * @param invoiceId Id de la facture
     * @return HttpResponse
     **/

    public static HttpResponse getInvoiceBody(string invoiceId) {
        String apiURL = ZuoraObjects.invoiceAPIUrl + invoiceId;

        return doCallout(apiURL, ZuoraObjects.get, '');
    }
    /**
     * Methode utilisée pour envoyer le rapport du caisse par email.
     * <p>
     * @param workflowId id du workflow
     * @return HttpResponse
     **/
    public static HttpResponse getWorkflowInfo( string workflowId, ZuoraObjects.ZuoraWorkflow rapportDuCaisse){
        String apiURL = ZuoraObjects.workflowAPIUrl + workflowId + '/run';

        return doCallout(apiURL, ZuoraObjects.post, JSON.serialize(rapportDuCaisse, true));
    }
    /**
     * Methode utilisée pour mettre a jour un facture.
     * <p>
     * @param invoiceId Id de la facture,
     * @param invoice le contenu de la facture
     * @return HttpResponse
     **/

    public static HttpResponse updateInvoice(string invoiceId, ZuoraObjects.ZuoraBilling invoice) {
        String apiURL = ZuoraObjects.invoiceAPIUrl + invoiceId;

        return doCallout(apiURL, ZuoraObjects.put, JSON.serialize(invoice, true));
    }
    /**
     * Méthode utilisé pour générer le bearer token
     */
    public static string getToken() {
        HttpRequest req = new HttpRequest();
        req.setMethod(ZuoraObjects.Post);
        // req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setEndpoint('callout:ZuoraApiUrl' + ZuoraObjects.tokenAPIUrl);
        req.setBody('grant_type=client_credentials' + '&client_id=' + system.label.Client_Id + '&client_secret=' + system.label.Client_Secret + '&scope=USER');
        system.debug(req);
        system.debug(req.getBody());
        Http http = new Http();
        HTTPResponse response = http.send(req);

        ZuoraResponseObjects.OauthenticationResponse tokenResponse = (ZuoraResponseObjects.OauthenticationResponse) JSON.deserialize(response.getBody(), ZuoraResponseObjects.OauthenticationResponse.class);

        system.debug('tokenResponse >> '+tokenResponse);
        return tokenResponse.access_token;
    }

    /**
     * Methode utilisée pour obtenir des infos concernant la facture.
     * <p>
     * @param customerAccountId Id du compte
     * @return HttpResponse
     **/
    /*
       public static HttpResponse getInvoice(string customerAccountId){

       String apiURL = ZuoraObjects.getInvoiceAPIUrl + customerAccountId;
       return doCallout(apiURL, ZuoraObjects.get,'');
       }*/

    /**
     * Methode utilisée pour exécuter un callout dans Zuora.
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
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:ZuoraApiUrl' + url);
        request.setMethod(method);
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        if(url.contains(ZuoraObjects.workflowAPIUrl)) {
            string bearerToken = getToken();
            request.setHeader('Authorization', 'bearer ' + bearerToken);
        }
        if(!string.isEmpty(body) && !string.isBlank(body)) {
            body = body.replaceAll('_toReplace', '');
            body = body.replaceAll('_Reserved', '__c');
            request.setBody(body);
        }
        Zuora.ZApi zApiInstance = new Zuora.ZApi();
        HttpResponse response = new HttpResponse();
        //  response = zApiInstance.sendRequest(request);
        if(!Test.isRunningTest() && !url.contains(ZuoraObjects.workflowAPIUrl)) {
            response = zApiInstance.sendRequest(request);
        } else {
            Http http = new Http();
            response = http.send(request);
        }

        return response;
    }

}