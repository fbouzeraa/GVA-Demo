/**
 * Classe pour simuler les appels API vers l'endpoint du stock de GVA
 */
@isTest
global class StockMock implements HttpCalloutMock {

    public boolean error = false;
    public boolean catchError = false;
    public Integer statusCode;

    public StockMock(){
        this.error = false;
        this.statusCode = 200;
    }

    public StockMock(boolean error, boolean catchError, Integer statusCode){
        this.error = error;
        this.catchError = catchError;
        this.statusCode = statusCode;
    }

    global HttpResponse respond(HTTPRequest request){
        String requestType = request.getEndpoint();

        HttpResponse response = new HttpResponse();
        try {
            if(requestType.contains(CanalBoxObjects.stockListingAPIUrl) && this.statusCode == 200) {
                // Set a sample response body for entity_site_ref=GABON-LBV-Entrepot, type_article_ref = NONNOK1G-240W-F
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"success": true,"articles":[{"serial": "ALCL:B3D03BDF","type_article_ref": "NONNOK1G-240W-F"},{"serial": "ALCL:B3D03BDE","type_article_ref": "NONNOK1G-240W-F"},{"serial": "ALCL:B3D03BDD","type_article_ref": "NONNOK1G-240W-F"},{"serial": "ALCL:B3D03BDC","type_article_ref": "NONNOK1G-240W-F"},{"serial": "ALCL:B3D03BDB","type_article_ref": "NONNOK1G-240W-F"},{"serial": "ALCL:B3D03BDA","type_article_ref": "NONNOK1G-240W-F"},{"serial": "ALCL:B3D03BD9","type_article_ref": "NONNOK1G-240W-F"}]}');
            } else if(requestType.contains(CanalBoxObjects.stockListingAPIUrl) && this.statusCode != 200) {
                // Set a sample response body for wrong data
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"errors": ["Entity site with reference GABON-LBV-Entrepo does not exist"],"success": false}');
            } else if(requestType.contains(CanalBoxObjects.stockReservingAPIUrl) && this.statusCode == 200) {
                // Set a sample response body for reserving a box
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"reservation_expiry_date": "2021-03-26 13:12:59","errors": [],"success": true}');
            } else if(requestType.contains(CanalBoxObjects.stockLiberationAPIUrl) && this.statusCode != 200) {
                // Set a sample response body for wrong data
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"errors": ["Entity site with reference GABON-LBV-Entrepo does not exist"],"success": false}');
            } else if(requestType.contains(CanalBoxObjects.stockLiberationAPIUrl) && this.statusCode == 200) {  // Set a sample response body for liberating a box
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"errors": [],"success": true}');
            } else if(requestType.contains(CanalBoxObjects.ordersAPIUrl) && this.statusCode == 200) {  // Set a sample response body for activation
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"services": [{"suivi": "string KO","external_ref": "string","pxo_date_rdv": "2019-08-24T14:15:22Z","suspended_date": "2019-08-24T14:15:22Z","activation_date": "' + date.today() + '","new_address": {' +
                                 '"mq_building_id": "BID_123","mq_residence": "string","mq_batiment": "string","mq_escalier": "1","mq_etage": "2","mq_porte": "2","mq_pto_ref": "string","zip": "string","town": "string"},"type_service": "string","reactivation_date": "2019-08-24T14:15:22Z","cancel_date": "2019-08-24T14:15:22Z","creation": "2019-08-24T14:15:22Z","status": "actif","service_ref": "string","type_service_descr": "string","type_operation": "string","statutGVAdmin": "KO","resultat": "string"}' +
                                 '],"order": {"external_ref": "string","signed_date": "2019-08-24T14:15:22Z","order_ref": "string","production_date": "2019-08-24T14:15:22Z","status": "produit","recette_date": "2019-08-24T14:15:22Z"}}');
            } else if(requestType.contains(CanalBoxObjects.ordersAPIUrl) && this.statusCode != 200) {
                response.setStatusCode(this.statusCode);
                response.setHeader('Content-Type', 'application/json');
                response.setBody('{"services": [{"suivi": "string","external_ref": "string","pxo_date_rdv": "2019-08-24T14:15:22Z","suspended_date": "2019-08-24T14:15:22Z","activation_date": "","type_service": "string","reactivation_date": "2019-08-24T14:15:22Z","cancel_date": "2019-08-24T14:15:22Z","creation": "2019-08-24T14:15:22Z","status": "pending","service_ref": "string","type_service_descr": "string","type_operation": "string","statutGVAdmin": "KO","resultat": "string"}' +
                                 '],"order": {"external_ref": "string","signed_date": "2019-08-24T14:15:22Z","order_ref": "string","production_date": "2019-08-24T14:15:22Z","status": "string","recette_date": "2019-08-24T14:15:22Z"}}');
            }

            return response;
        }
        catch(Exception e) {
            throw new MyCustomException('HTTP callout not supported for test methods');
        }

    }
    public class MyCustomException extends Exception {}

}