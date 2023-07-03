/**
 * Classe permettant de définir les Objets Apex correspondant aux objets utilisés pour
 * effectuer les appels API du MTN ws et les appels API USSD HexaKomb.
 * @author Yara Bourdoukan
 * @date 15/03/2022
 * @Updates Jackie Abi Nassif
 * @date 27/09/2022
 */

global class USSDObjects {
    public static String post = 'POST';
    public static String put = 'PUT';
    public static String get = 'GET';

    public class TransactionAPIResponse {

        public boolean success;
        public string message;
        public double amount;
        public string endDate;
        public string requestDate;
        public string status;
        public string name;
        public string transactionId;
    }

    // request body object of the transaction Api call
    public class TransactionBodyRequest {

        public string routerNumber;
        public string transactionNumber;
        public Integer prepaidPeriod;
        public string operator;
        public string referenceNumber;
        public double amount;
        public string sender;
        public string senderPhone;
        public string transactionTime;
    }

    // response object of the verify User Subscription Api call
    public class VerifyUserResponse {

        public boolean success;
        public string message;
        public list<UserSubscription> subscriptions;
    }
    public class Usersubscription {
        public String name;
        public String endDate;
        public String status;
        public string boxNumber;
        public string coupon;
        public string freeDays;
        public string currentCurrency;
        public boolean inMoveProcess;
        public string countrycodeValue;
    }

    // response object of the fetch offers Api call
    public class OfferAPIResponse {

        public boolean success;
        public string message;
        public list<ProductObject> offers;
    }
    public class ProductObject {

        public string name;
        public double price;
        public string currentCurrency;
        public string description;
    }
    
    // response to the MTN API request get Offers WS04_USSDMTNOffers
    public class OfferMTNAPIResponse {

        public list<listOfarguments> argumentsList;
        public boolean success;
        public String message;
    }
    public class ListOfarguments {

        public list<Argument> arguments;
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

    // request body object of the preview Api call (For MTN and other)
    public class PreviewAmountRequest {
        public List<Argument> arguments; 
        public String languageCode;
        public String sessionIdentifier;
        public String journeyIdentifier;
        public String  routerNumber;
        public String prepaidPeriod;
        public String operator;
        public String referenceNumber; // base product to add (Premium & Start)
        public String renewtype;
    }

    // response of the preview request
    public class RequestToPayPreviewResponse {

        public list<Argument> arguments;
        public boolean success;
        public string message;
        public String amount;
        public String currentCurrency;
        public String currentCountryCode;
        public String currentBoxNumber;
        public String previewDateTime;
        public String oldOffer;
        public String newOffer;
    }


    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public class ValidAccountRequest {
        public String BoxNumber;
        public String AccountCurrency;
        public String OperatorName;
        public integer OperationType;
        public string CountryCode;
    }

    public class MTNAPIResponse {

        public boolean Success;
        public list<String> Errors;
        public string SubscriptionNumber;
        public string SubscriptionId;
        public string AccountId;
        public string AccountCurrency;
        public double Amount;
        public date EndDate;
        public string Message;
    }

    public class SubscriptionRenewalRequest {
        public String SubscriptionId;
        public String AccountCurrency;
        public String OperatorName;
        public integer Duration;
        public integer OperationType;
        public string CountryCode;
        public string TransactionNumber;

    }
    public class SuiviDetails {

        // Nombre de période prépayée en mois
        public integer Periode;
        // Numéro de la transaction
        public string NumeroDeTransaction;
        // Mode de paiement
        public string ModeDePaiement;
        // ID de l'abonnement
        public string IDSouscription;
        //Erreur
        public string Erreur;
        // Nom de l'operateur
        public string Operateur;
        public integer typeOperation;

    }

}