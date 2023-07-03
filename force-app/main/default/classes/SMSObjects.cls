/**
 * Classe permettant de définir les Objets Apex correspondant aux objets SMS utilisés pour
 * effectuer les appels API.
 *
 * Chaque Objet Apex présent dans la classe correspondera à un Objet SMS et chaque Propriété Apex correspond à un
 * champ dans l'Objet SMS
 */
public with sharing class SMSObjects {

    public static String post = 'POST';
    public static String get = 'GET';
    public static string smsBulkAPIUrl = '/sendSms/';

    /**
     * Sends bulk SMS requests
     */
    public class SMSBulkRequest {
        /**
         * Type article reference, Required
         */
        public List<SMSTarget> to;
        /**
         * Message text with placeholders in the format #param1#   #param2" etc., Required
         */
        public string text;
        public string from_Reserved;
        public string campaignName;
        public string date_Reserved;
        public integer coding;
        public integer tracking;
        public integer alerting;
        public integer simulate;
        public integer verbose;
    }
    /**
     * Send bulk Sms
     */
    public class SMSRequest {
        public SMSData DATA;
    }
    /**
     * Sends bulk SMS requests
     */
    public class SMSData {
        /**
         * Type article reference, Required
         */
        public List<SMSTarget> SMS;
        /**
         * Message text with placeholders in the format #param1#   #param2" etc., Required
         */
        public string MESSAGE;
        public string TPOA;
        /**
         * Number of Param in the message
         */
        public string DYNAMIC;
        public string DATE_Reserved;
        public integer LOWCOST;
    }

    /**
     * Target for each SMS message
     */
    public class SMSTarget {
        /**
         * Mobile Phone
         */
        public String MOBILEPHONE;
        /**
         * Nom du quatier
         */
        public String PARAM_1;
        /**
         * Date de renouvellement
         */
        public date PARAM_2;
        /**
         * Numero du box
         */
        public String PARAM_3;
        /**
         * numero du call center
         */
        public String PARAM_4;
        /**
         * Durée d'échu
         */
        public String PARAM_5;

    }

    public class SMSBulkResponse {
        public Integer code;
        public integer status;
        public String statusText;
        public String invalidNumbers;
        public String campaignId;
        public Integer nbContacts;
        public Integer nbSms;
        public Double balance;
        public Double cost;
        public List<SmsIds> smsIds;
    }

    public class SmsIds {
        public String smsId;
        public String phoneNumber;
    }
}