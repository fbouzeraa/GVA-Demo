/**
 * Classe permettant de définir les Objets Apex correspondant aux objets CanalBox utilisés pour
 * effectuer les appels API.
 *
 * Chaque Objet Apex présent dans la classe correspondera à un Objet stock et chaque Propriété Apex correspond à un
 * champ dans l'Objet CanalBox
 */
public with sharing class CanalBoxObjects {

    public static String post = 'POST';
    public static string stockListingAPIUrl = '/stock/stock';
    public static string stockReservingAPIUrl = '/stock/reserve';
    public static string stockLiberationAPIUrl = '/stock/liberate';
    public static string ordersAPIUrl = '/orders/orders';

    /**
     * Returns articles in stock given an entity site and article_type
     */
    public class stockListing {
        /**
         * Type article reference
         */
        public String type_article_ref;
        /**
         * Entity site reference
         */
        public String entity_site_ref;
    }

    /**
     * Reserve a serial that will be placed in the order
     * or Free a serial that has been reserved
     */
    public class StockReservationLiberation {
        /**
         * Article serial
         */
        public String serial;
        /**
         * Type article reference
         */
        public String type_article_ref;
        /**
         * Entity site reference
         */
        public String entity_site_ref;
    }

    public class stockListingResponse {
        /**
         * List of articles in stock
         */
        public list<stockArticleResponse> articles;
        /**
         * Was the query successful
         */
        //public boolean success;
        /**
         * List of possible errors
         */
        public list<string> errors;
        /**
         * Error message
         */
        //public string message;
        /**
         * Error name
         */
        public string status;
        /**
         * Error name
         */
        //public string status_Reserved;
        /**
         * Error code
         */
        public integer code;

    }

    public class stockArticleResponse {
        /**
         * Article serial
         */
        public String serial;
        /**
         * Type article reference
         */
        public String type_article_ref;

    }

    public class stockReservingResponse {
        /**
         * Article reservation expiry date
         */
        public string reservation_expiry_date;
        /**
         * Was the query successful
         */
        public boolean success;
        /**
         * List of possible errors
         */
        public list<string> errors;
        /**
         * Error message
         */
        public string message;
        /**
         * Error name
         */
        public string status;
        /**
         * Error name
         */
        public string status_Reserved;
        /**
         * Error code
         */
        public integer code;

    }
    public class Orders {
        /**
         * GVAdmin order reference
         */
        public string order_ref;
    }

    public class OrderResponse {
        /**
         * Array of objects (OrderServiceItem)
         *   Client service(s)
         */
        public list<OrderServiceItemResponse> services;
        /**
         * object Order Information
         */
        public OrderInformationResponse order;
        /**
         *  boolean Was the request successful
         */
        public Boolean success;
        /**
         * Error description
         */
        public string error;
        /**
         * Unprocessable entity
         */
        public string status;
        /**
         * HTTP error code
         */
        public string code;
        /**
         * list of errors
         */
        //  public ErrorResponse errors;

    }
    public class newAddress {
        public string mq_building_id;
        public string mq_residence;
        public string mq_batiment;
        public string mq_escalier;
        public string mq_etage;
        public string mq_porte;
        public string mq_pto_ref;
        public string zip;
        public string town;
    }
    public class OrderServiceItemResponse {
        /**
         * Provisioning steps for Salesforce consulting
         */
        public string suivi;
        /**
         * Salesforce subscription reference
         */
        public string external_ref;
        /**
         * Praxedo appointment date
         */
        public string pxo_date_rdv;
        /**
         * Last suspension date
         */
        public string suspended_date;
        /**
         * Activation date (Use this date for invoicing)
         */
        public string activation_date;
        /**
         * Service type
         */
        public string type_service;
        /**
         * Last reactivation date
         */
        public string reactivation_date;
        /**
         * Cancelation date
         */
        public string cancel_date;
        /**
         * Creation date (database insertion)
         */
        public string creation;
        /**
         * Service status (en attente/actif/suspendu/annule/a detruire/resilie)
         */
        public string status;
        /**
         * Service reference
         */
        public string service_ref;
        /**
         * Service type description
         */
        public string type_service_descr;
        /**
         * Operation type (RESIL/REACTIVATE/CREATION/MIGRATION/MODIF/SUSPEND/MOVE)
         */
        public string type_operation;
        /*
         * présent si erreur d’adresse détectée pendant la phase de livraison
         */
        public newAddress new_address;
        /*
         * présent
         */
        public string statutGVAdmin;
        /*
         * présent
         */
        public string resultat;
    }

    public class OrderInformationResponse {
        /**
         * Salesforce order reference
         */
        public string external_ref;
        /**
         * Signature date
         */
        public string signed_date;
        /**
         * Order reference
         */
        public string order_ref;
        /**
         * Production date
         */
        public string production_date;
        /**
         * string status
         */
        public string status;
        /**
         * Acceptance date
         */
        public string recette_date;
    }
    // public class ErrorResponse{
    /**
     * object (OrderResponseUnprocessableEntityErrorsJson)
     */
    //   public UnprocessableEntityErrorsResponse json;
    // }
    // public class UnprocessableEntityErrorsResponse{
    /**
     * Missing data for required field
     */
    //    public string order_ref;
    //  }

}