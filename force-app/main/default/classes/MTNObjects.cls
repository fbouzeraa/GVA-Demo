public with sharing class MTNObjects {

    public static String post = 'POST';
    public static String put = 'PUT';
    public static String get = 'GET'; 
    public static String requesttopayAPIUrl = '/collection/v1_0/requesttopay';
    
    // body of the requestToPay APi request
    public class MobileMoneyRequest {
        public String externalId;
        public string amount;
        public String curency;
        public String payeeNote;
        public String payerMessage;
        public Payer payer;
        public String financialTransactionId;
        public String status;
        public String code;
        public String message;
    }
    public class Payer{
        public String partyIdType;
        public String partyId;
        public Payer(String partyIdType,String partyId){
            this.partyIdType = partyIdType;
            this.partyId = partyId;
        }
        
    }
    
    public class MobileMoneyResponse {

        public Boolean success;
        public string message;
        public string requestDate;
    }
    public class RequestToPayReq2 {
        public String boxNumber;
        public Double amount;
        public String curency;
        public String financialTransactionId;
        public String subsName;
        public Integer prepaidPeriod;
        public String operator;
        public String ACCOUNT_HOLDER_MSISDN;
        
    }
    public class RequestToPayReq {
        public List<Argument> arguments; 
        public String languageCode;
        public String sessionIdentifier;
        public String journeyIdentifier;
    }
    public class getOffersReq {
        public List<Argument> arguments; 
        public String languageCode;
        public String sessionIdentifier;
        public String journeyIdentifier;
    }

    // response of the preview request MTN to SF
    public class RequestToPayPreviewResponse {

        public list<Argument> arguments;
        public boolean success;
        public string message;
    }
    public class Argument {
        public Key key;
        public Value value;
    }
    public class Key{
        public String value;
    }
    public class Value{
        public String value;
    }

    // get Token response
    public class TokenResponse {

        public string access_token;
        public string token_type;
        public integer expires_in;
    } 
}