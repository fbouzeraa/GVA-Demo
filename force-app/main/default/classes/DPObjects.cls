public with sharing class DPObjects {
    public static String post = 'POST';
    public static String get = 'GET';
    public static string getTransactionAPIUrl = '/API/v7/';
    public static string newTokenAPIUrl = '/API/v6/';

    public class PushPaymentResponse {

        public string Result;
        public string ResultExplanation;
        public string TransactionToken;
        public string TransactionRef;
        public string CustomerName;
        public string CustomerEmail;
        public string CustomerCredit;
        public string CustomerCreditType;
        public string TransactionApproval;
        public string TransactionCurrency;
        public double TransactionAmount;
        public string FraudAlert;
        public string FraudExplnation;
        public double TransactionNetAmount;
        public string TransactionSettlementDate;
        public double TransactionRollingReserveAmount;
        public string TransactionRollingReserveDate;
        public string CustomerPhone;
        public string CustomerCountry;
        public string CustomerAddress;
        public string CustomerCity;
        public string CustomerZip;
        public string MobilePaymentRequest;
        public string AccRef;
        public string CompanyToken;

    }
    public class Response {
        public boolean Success;
        public list<String> Erreurs;
        public String Message;
    }
    public class newTokenResponse {
        public API3GResponse API3G;
    }
    public class API3GResponse {
        public String Result;
        public String ResultExplanation;
        public String TransToken;
        public String TransRef;
    }

    public class getTransactionByRef {
        public API3G API3G;
    }

    public class API3G {
        /**
         * Token you got from 3G to operate this API
         */
        public string CompanyToken;
        /**
         * getTransactionByRef
         */
        public string Request;
        /**
         * Booking Reference
         */
        public string CompanyRef;
        /**
         * Using this field will return all transactions created by specified user
         */
        public string userToken;
        /**
         * Status of transaction
         */
        public integer allTrans;
        /**
         * Sending this with true will return all results in the opposite order
         */
        public integer descOrder;
        /**
         * Transaction Token
         */
        public string TransactionToken;

        public string Code;

        public string Explanation;

        public Transactions Transactions;

        public TransactionObject Transaction_toReplace;

        public Services Services;

    }

    public class transactionByRefResponse {

        public API3G API3G;

    }

    public class Transactions {

        public Transaction_toReplace Transaction_toReplace;
    }

    public class Transaction_toReplace {
        public string TransactionBookRef;

        public string TransactionToken;

        public string TransactionCreatedDate;

        public string TransactionAmount;

        public string TransactionCurrency;

        public string TransactionFinalAmount;

        public string TransactionFinalCurrency;

        public string TransactionCreditCard;

        public double TransactionPartPayment;

        public string TransactionCityId;

        public string TransactionPhone;

        public string TransactionPhonePrefix;

        public string TransactionRef;

        public string TransactionStatus;

        public string TransactionPaymentDate;

        public string TransactionCardType;

        public string TransactionUserName;

        public string TransactionApprovalNumber;

        public TransactionServiceDescription TransactionServiceDescription;

        public string TransactionCustomerPhone;

        public string TransactionCustomerEmail;

        public string TransactionCustomerName;

        public string TransactionFraudAlert;

        public string TransactionFraudExplanation;

        public string TransactionExpiryDate;

        //public TransactionAdditionalAirlineFields TransactionAdditionalAirlineFields;

        public Additional Additional;

        public string RedirectUrl;

        public string BackUrl;

        public string DeclinedUrl;
    }

    public class TransactionServiceDescription {
        public string ServiceDescription;
    }

    public class TransactionAdditionalAirlineFields {
        public string TicketType;

        public string DocumentType;

        public string DateIssued;

        public string IATACarrierCode;

        public string IATATravelAgencyNbr;

        public string TicketCarrierName;

        public string TicketIssuerCityName;

        public string PassengerCount;

        public string ConjTicketIndicator;

        public string ElecTicketIndicator;

        public string ExchTicketIndicator;

        public list<FlightLeg> FlightLegDetails;

        public list<Traveler> Travelers;
    }

    public class FlightLeg {
        public string FlightDescription;

        public string FlightType;

        public string FlightDate;

        public string FlightFrom;

        public string FlightTo;

        public string FlightRef;

        public string CarrierCode;

        public string ServiceClass;

        public string FlightNumber;

        public string FareBasisCode;

        public string StopOverCode;

    }

    public class Traveler {
        public string TravelerFirstName;

        public string TravelerLastName;

        public string TravelerPhone;

        public string TravelerPhonePrefix;

        public string TravelerCountryCode;

        public Date TravelerDateOfBirth;

    }
    public class Additional {
        public string BlockPayment;

    }
    public class TransactionObject {
        public string CompanyAccRef;
        //Total amount in the selected currency.No more than 2 digits after the comma
        // required
        public double PaymentAmount;
        //From table of options as accepted from DPO
        // required
        public string PaymentCurrency;
        //Company reference number, i.e also referred to as Booking ref
        public string CompanyRef;
        //URL to redirect the customer after the payment.
        //The customer will be redirected to this URL with the below variables in GET method .
        public string RedirectURL;
        //URL to let the customer go back from the payment page.
        //The customer will be redirected to this URL with "TransactionToken" and "CompanyRef" variables in GET method .
        public string BackURL;
        //Tells the system to verify if the company reference number (transaction ID given by the provider) given is already in the system and paid, if so, returns error to API result.This is to prevent double payments
        public boolean CompanyRefUnique;
        //E - mail of the customer to send the link
        public string customerEmail;
        //Customer name
        public string customerFirstName;
        //Customer last name
        public string customerLastName;
        //Customer city
        public string customerCity;
        //Customer country
        public string customerCountry;
        public string customerPhone;

    }

    public class ServiceObject {
        //The description of the payment made
        public string ServiceDescription;
        //Service type number according to the options accepted from DPO
        public integer ServiceType;
        //Service type name according to the options accepted from DPO
        public string ServiceTypeName;
        //Service date of the booked service Format: YYYY / MM / DD HH: MM
        public Date ServiceDate;

    }
    public class createToken {
        public API3G API3G;
    }
    public class Services {
        public ServiceObject Service;
    }

    public class SuiviDetails {
        public string operateur;
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
        public integer typeOperation;

    }
}