/**
 * Classe pour simuler les appels API vers l'endpoint d'Eligibilité de GVA
 *
 * @author Maroun Yazbeck
 * @date 17 Décembre 2020
 */
@isTest
global class EligMock implements HttpCalloutMock {

    public boolean error = false;
    public boolean catchError = false;
    public Integer statusCode;

    public EligMock(){
        this.error = false;
        this.statusCode = 200;
    }

    public EligMock(boolean error, boolean catchError, Integer statusCode){
        this.error = error;
        this.catchError = catchError;
        this.statusCode = statusCode;
    }

    global HttpResponse respond(HTTPRequest request){
        String requestType = request.getEndpoint();

        HttpResponse response = new HttpResponse();
        if(requestType.contains(EligibilityObjects.buildingsAPIUrl)) {
            // Set a sample response body for building ID KIG_97341
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"comment":"","country":"RWANDA","date_audited":"2019-11-27T08:31:08+01:00","date_creation":"2019-07-10T11:55:11+02:00","date_inventory":null,"date_survey":"2019-11-21T10:03:29+01:00","electrical_access":"underground","geom":{"coordinates":[30.06183571266881,-1.9516109860662578],"type":"Point"},"gref":"KIG_97341","has_clients":false,"import_gref":"","is_empty":false,"is_inaccessible":false,"is_invalid":false,"is_slum":false,"is_under_construction":false,"last_auditor":"VINCENT MUHIRE","last_surveyor":"JAMES HAKIZIMANA\n","nb_ent_a":0,"nb_ent_b":5,"nb_ent_c":0,"nb_ent_d":0,"nb_flat_a":0,"nb_flat_b":3,"nb_flat_c":0,"nb_flat_d":2,"nb_flat_empty":0,"nb_floors":4,"neighborhood":"Kiyovu","other_ops_drop":null,"pictures":[{"taken_at":"2019-11-27T10:29:00+01:00","url":"https://photos.canalbox.net/kig/buildings/KIG_97341/20191127-112900.jpg"},{"taken_at":"2019-11-21T11:57:36+01:00","url":"https://photos.canalbox.net/kig/buildings/KIG_97341/20191121-125736.jpg"}],"region":"Kigali","residence":"","survey_status":"audited","town":"KIGALI","zone_osp":""}');
        } else if(requestType.contains(EligibilityObjects.rawFeasibilityAPIUrl) && this.statusCode == 200) {
            // Set a sample response body for building ID KIG_97341
            response.setStatusCode(this.statusCode);
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"feasible": true,"info": {"code": 0,"extra": {},"message": null,"status": 1},"reason": null}');
        }

        return response;
    }
}