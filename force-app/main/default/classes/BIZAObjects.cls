public with sharing class BIZAObjects {

    // URL prod ==> https://api.bizao.com ---- URL pre prod ==> 
    public static string MobileMoneyAPIUrl = '/mobilemoney/v1';
    public static string MobileMoneyStatusAPIUrl = '/mobilemoney/v1/getStatus/'; // preprod: mobilemoney/getStatus/v1/';// prod: '/mobilemoney/v1/getStatus/';
    public static string DebitCardAPIURL =  '/debitCard/v2'; // Prod '/debitCard/v2'; // preprod: '/debitCard/v1';
    public static string DebitCardStatusAPIUrl =  '/debitCard/getStatus/v2/';// prod: '/debitCard/v1/getStatus/'; // preprod: '/debitCard/getStatus/v1/'
    public static string post = 'POST';
    public static string get = 'GET';

    public class MobileMoneyRequest {
        public string currency_Reserved;
        public string order_id;
        public integer amount;
        public string state;
        public string return_url;
        public string cancel_url;
        public string reference;
        public string user_msisdn;


    }
    /*   public class MobileMoneyResponse {
           public string status;
           public string order_id;
           public string payment_token;
           public string payment_url;
           public string state;
           public string user_msisdn;
           public error requestError;

    }*/
    public class getPaymentStatus {
        public string status;
        public error requestError;
    }
    public class error {
        public exceptions serviceException;
    }
    public class exceptions {
        public string messageId;
        public string text;
        public string variables;
    }

}