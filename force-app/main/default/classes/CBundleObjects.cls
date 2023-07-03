/**
 * Classe permettant de définir les Objets Apex correspondant aux objets cBundle utilisés pour
 * effectuer les appels API.
 *
 * Chaque Objet Apex présent dans la classe correspondera à un Objet cBundle et chaque Propriété Apex correspond à un
 * champ dans l'Objet cBundle
 *
 * @author Jackie Abi Nassif
 * @date 13 Juin 2022
 */

public class CBundleObjects {

    // URL: https://cgaweb-afrique.canalbox.net:1445
    // 1445 --> port preprod /// 1443 --> port prod

    public static String post = 'POST';
    public static String put = 'PUT';
    public static String get = 'GET';
    public static String patch = 'PATCH';
    public static String cancellationAPIUrl = '/v1/cancellation';
    public static String materialExchangeAPIUrl = '/v1/materialExchange';
    public static String modifyContactsAPIUrl = '/v1/contacts';
    public static String modifyOffersAPIUrl = '/v1/offers';
    public static String subscriptionAPIUrl = '/v1/subscription';
    public static String fastReactivationAPIUrl = '/v1/fastReactivation';
    public static String reactivationAPIUrl = '/v1/renewal';
    public static String suspensionAPIUrl = '/v1/suspension';
    public static String activationAPIUrl = '/v1/activation';
    public static String eligMigrationAPIUrl = '/api/v1/partners/check-eligibility';
    public static String requMigrationAPIUrl = '/api/v1/management-acts/request-migration';
    public static String cancelMigrationAPIURL = '/api/v1/migration/cancellation';

    public class ELIGIBILITY_MIGRATION {
        // GVA
        public String partnerIdId;
        public String equipmentId;
    }
    public class REQUEST_MIGRATION {
        public PartnerObject partner;
        public ContractObject contract;
        public ProductObjectMigration product;
        public String distributorId;
        public String equipmentId;
    }
    public class CANCEL_MIGRATIION {
        public String orderId;
        // Status Success 204
        // in the Header : UserID: WS_GVA && saleDeviceId: PARTENAIRE && countryCode: CI...
    }
    public class PERSON_IDENTIFICATION {
        public PartnerObject partner;
        public identificationKeyObject identificationKey;
    }
    public class CESAR_CANCELLATION {
        /**
         * Mandatory: Yes, Description: Partner customer identifier
         */
        public String externalClientId;
        /**
         * Mandatory: Yes, Description: Partner contract identifier
         */
        public String externalContractId;
        /**
         * Mandatory: Yes, Description: Partner user identifier used to connect to CANAL SI
         */
        public String userId;
        /**
         * Mandatory: Yes, Description: Partner identifier, used to retrieve mapped parameters
         */
        public String partnerId;
        /**
         * Mandatory: No, Description: Sales channel identifier, currently not used in Cancellation
         */
        public String salesDevice;
        /**
         * Mandatory: No, Description: Unique transaction identifier, used by replay service
         */
        public String transactionId;
        /**
         * Mandatory: No, Description: Partner-defined cancellation reason code
         */
        public String cancelReason;
        /**
         * Mandatory: Yes, Description: Date of cancellation. A date in future is not allowed
         */
        public String cancellationDate;
        /**
         * Object {internetProviderId, distributorId}
         */
        public ProviderInfosObject providerInfos;
    }
    public class CESAR_EXCHANGE_MATERIAL {
        /**
         * Mandatory: No, Description: Unique transaction identifier, used by replay service
         */
        public String transactionId;
        /**
         * Mandatory: Yes, Description: Partner customer identifier
         */
        public String externalClientId;
        /**
         * Mandatory: Yes, Description: Partner contract identifier
         */
        public String externalContractId;
        /**
         * Object {equipmentId, equipmentType}
         */
        public OldEquipment oldEquipment;
        /**
         * Object {equipmentId, equipmentType}
         */
        public NewEquipment newEquipment;
        /**
         * Mandatory: No, Description: Sales channel identifier, currently not used in Exchange Material
         */
        public String salesDevice;
        /**
         * Object {internetProviderId, distributorId}
         */
        public ProviderInfosObject providerInfos;
        /**
         * Mandatory: Yes, Description: Partner user identifier used to connect to CANAL SI
         */
        public String userId;
        /**
         * Mandatory: Yes, Description: Partner identifier, used to retrieve mapped parameters
         */
        public String partnerId;
    }
    public class CESAR_MODIFY_CONTACTS {
        /**
         * Mandatory: Yes, Description: Unique transaction identifier, used by replay service
         */
        public String transactionId;
        /**
         * Mandatory: Yes, Description: Partner customer identifier
         */
        public String externalClientId;
        /**
         * Mandatory: No, Description: Partner contract identifier
         */
        public String externalContractId;
        /**
         * Mandatory: Yes, Description: Sales channel identifier, currently not used in Cancellation
         */
        public String salesDevice;
        /**
         * Object {internetProviderId, distributorId}
         */
        public ProviderInfosObject providerInfos;
        /**
         * Object {externalClientId, civility, firstName, lastName, suscriberCategory, companyId, companyName}
         */
        public PersonObject person;
        /**
         * List Of Object {internetProviderId, distributorId}
         */
        public list<PhoneObject> phones;
        /**
         * Object {internetProviderId, distributorId}
         */
        public AddressObject address;
        /**
         * List Of Object {internetProviderId, distributorId}
         */
        public list<EmailObject> email;
        /**
         * Mandatory: Yes, Description: Partner user identifier used to connect to CANAL SI
         */
        public String userId;
        /**
         * Mandatory: Yes, Description: Partner identifier used to retrieve mapped parameters
         */
        public String partnerId;
    }
    public class CESAR_MODIFYOFFER {
        /**
         * Mandatory: Yes, Description: Partner customer identifier
         */
        public String externalClientId;
        /**
         * Mandatory: Yes, Description: Partner contract identifier
         */
        public String externalContractId;
        /**
         * Mandatory: Yes, Description: Partner user identifier used to connect to CANAL SI
         */
        public String userId;
        /**
         * Mandatory: Yes, Description: Partner identifier, used to retrieve mapped parameters
         */
        public String partnerId;
        /**
         * Mandatory: No, Description: Sales channel identifier, currently not used in Cancellation
         */
        public String salesDevice;
        /**
         * Mandatory: No, Description: Unique transaction identifier, used by replay service
         */
        public String transactionId;
        /**
         * Object {mainOffer(Mandatory: yes), options(Mandatory: No)}
         */
        public ProductObject products;
        /**
         * Object {internetProviderId, distributorId}
         */
        public ProviderInfosObject providerInfos;
    }
    public class CESAR_RENEWAL {
        /**
         * Mandatory: Yes, Description: Partner contract identifier
         */
        public String transactionId;
        /**
         * Mandatory: Yes, Description: Partner customer identifier
         */
        public String externalClientId;
        /**
         * Mandatory: Yes, Description: Partner contract identifier
         */
        public String externalContractId;
        /**
         * Mandatory: No, Description: Sales channel identifier, currently not used in Cancellation
         */
        public String salesDevice;
        /**
         * Mandatory: No, Description: Duration of the renewal
         */
        public integer duration;
        /**
         * Object {internetProviderId, distributorId}
         */
        public ProviderInfosObject providerInfos;
        /**
         * Object {mainOffer(Mandatory: No), options(Mandatory: No)}
         */
        public ProductObject products;
        /**
         * Mandatory: Yes, Description: Partner user identifier used to connect to CANAL SI
         */
        public String userId;
        /**
         * Mandatory: Yes, Description: Partner identifier used to retrieve mapped parameters
         */
        public String partnerId;
    }
    public class CESAR_SUBSCRIPTION {
        /**
         * Mandatory: Yes, Description: Partner contract identifier (Check existence of transactionID and the state of the last transaction)
         */
        public String transactionId;
        /**
         * Mandatory: No, Description: (not mandatory because Not-used)
         */
        public String creationDate;
        /**
         * Mandatory: Yes, Description: The canal through which the subscription has been made
         */
        public String salesDevice;
        /**
         * Object {}
         */
        public SubscriptionObject subscription;
        /**
         * Mandatory: Yes, Description: Partner user identifier used to connect to CANAL SI
         */
        public String userId;
        /**
         * Mandatory: Yes, Description: Partner identifier used to retrieve mapped parameters
         */
        public String partnerId;
    }
    public class CESAR_ACTIVATION {
        /**
         * Mandatory: Yes, Description: Partner customer identifier
         */
        public String externalClientId;
        /**
         * Mandatory: Yes, Description: Partner contract identifier
         */
        public String externalContractId;
        /**
         * Mandatory: Yes, Description: Partner user identifier used to connect to CANAL SI
         */
        public String userId;
        /**
         * Mandatory: Yes, Description: Partner identifier used to retrieve mapped parameters
         */
        public String partnerId;
        /**
         * Mandatory: No, Description: Sales channel identifier, currently not used in Cancellation
         */
        public String salesDevice;
        /**
         * Mandatory: No, Description: Unique transaction identifier, used by replay service
         */
        public String transactionId;
        /**
         * Mandatory: No, Description: Date of activation.
         */
        public String activationDate;
        /**
         * Object {internetProviderId, distributorId}
         */
        public ProviderInfosObject providerInfos;
    }
    public class CESAR_FAST_REACTIVATION {
        /**
         * Mandatory: Yes, Description: Partner customer identifier
         */
        public String externalClientId;
        /**
         * Mandatory: Yes, Description: Partner contract identifier
         */
        public String externalContractId;
        /**
         * Mandatory: Yes, Description: Partner user identifier used to connect to CANAL SI
         */
        public String userId;
        /**
         * Mandatory: Yes, Description: Partner identifier used to retrieve mapped parameters
         */
        public String partnerId;
        /**
         * Mandatory: No, Description: Sales channel identifier, currently not used in Cancellation
         */
        public String salesDevice;
        /**
         * Mandatory: No, Description: Unique transaction identifier, used by replay service
         */
        public String transactionId;
        /**
         * Object {internetProviderId, distributorId}
         */
        public ProviderInfosObject providerInfos;
    }
    public class CESAR_SUSPENSION {
        /**
         * Mandatory: Yes, Description: Partner customer identifier
         */
        public String externalClientId;
        /**
         * Mandatory: Yes, Description: Partner contract identifier
         */
        public String externalContractId;
        /**
         * Mandatory: Yes, Description: Partner user identifier used to connect to CANAL SI
         */
        public String userId;
        /**
         * Mandatory: Yes, Description: Partner identifier used to retrieve mapped parameters
         */
        public String partnerId;
        /**
         * Mandatory: No, Description: Sales channel identifier, currently not used in Cancellation
         */
        public String salesDevice;
        /**
         * Mandatory: No, Description: Unique transaction identifier, used by replay service
         */
        public String transactionId;
        /**
         * Mandatory: No, Description: Date of suspension.
         */
        public String suspensionDate;
        /**
         * Mandatory: No, Description: Reason of suspension.
         */
        public String suspensionReason;
        /**
         * Object {internetProviderId, distributorId}
         */
        public ProviderInfosObject providerInfos;
    }
    public class OldEquipment {
        /**
         * Mandatory: Yes, Description: Numdec of actual equipment belongs to subscriber
         */
        public String equipmentId;
        /**
         * Mandatory: Yes, Description: Ctypde of actual equipment belongs to subscriber
         */
        public String equipmentType;
    }
    public class NewEquipment {
        /**
         * Mandatory: Yes, Description: Future numdec assigned to subscriber
         */
        public String equipmentId;
        /**
         * Mandatory: Yes, Description: Future ctypde assigned to subscriber
         */
        public String equipmentType;
    }
    public class ProviderInfosObject {
        /**
         * Mandatory: Yes, Description: Unique local operator identifier
         */
        public String internetProviderId;
        /**
         * Mandatory: Yes, Description: Logistic operator identifier
         */
        public String distributorId;
    }
    public class PersonObject {
        /**
         * Mandatory: Yes, Description:
         */
        public String externalClientId;
        /**
         * Mandatory: Yes, Description: The civility of the customer
         */
        public String civility;
        /**
         * Mandatory: Yes, Description: First name of the customer
         */
        public String firstName;
        /**
         * Mandatory: Yes, Description: Last name of the customer
         */
        public String lastName;
        /**
         * Mandatory: No, Description: If the value is null or empty, the value is retrieved from COD_DEFAULTVALUE
         */
        public String subscriberCategory;
        /**
         * Mandatory: No, Description: not used
         */
        public String companyId;
        /**
         * Mandatory: No, Description: not used
         */
        public String companyName;
    }
    public class AddressObject {
        /**
         * Mandatory: Yes, Description: search input parameters "CITY" in ABO_CONVERTCPOSTAL.INPUT for the PARTNERID
                                        > If found, then register COMMUNE, CPAYS, CPOSTAL defined pour this input
                                        > if not found, then delete the last element after the last separator and search again in ABO_CONVERTCPOSTAL.INPUT
                                        > If found, then register COMMUNE, CPAYS, CPOSTAL defined pour this input
                                        > if not found, then delete the last element after the last separator and search again in ABO_CONVERTCPOSTAL.INPUT
                                        At the end, if not found, then COMMUNE is fullfilled with distributor's adress
         */
        public String city;
        /**
         * Mandatory: Yes, Description: Customer Country following the pattern ISO 3166-1 alpha-2. example: FR for France
         */
        public String countryId;
        /**
         * Mandatory: No, Description: Customer Postal Code using mapping table : cod_convertcpostal
         */
        public String postalCode;
        /**
         * Mandatory: No, Description: More information about customer address.
         */
        public String street1;
        /**
         * Mandatory: Yes, Description: Information about customer address.
         */
        public String street2;
        /**
         * Mandatory: No, Description: More information about customer address.
         */
        public String street3;
    }
    public class PhoneObject {
        /**
         * Mandatory: Yes, Description: Customer Phone
         */
        public String phoneNumber;
        /**
         * Mandatory: Yes, Description: Phone Number Type
         */
        public String phoneType;
    }
    public class EmailObject {
        /**
         * Mandatory: Yes, Description: customer email
         */
        public String email;
        /**
         * Mandatory: Yes, Description: Email type
         */
        public String emailType;
    }
    public class ProductObject {
        /**
         * Description: New main offer to apply to subscription
         */
        public String mainOffer;
        /**
         * Description: If any, options associated to main offer
         */
        public List<String> options;
    }
    public class SubscriptionObject {
        /**
         * Object {internetProviderId, distributorId}
         */
        public ProviderInfosObject providerInfos;
        /**
         * Object {externalClientId, civility, firstName, lastName, suscriberCategory, companyId, companyName}
         */
        public PersonObject person;
        /**
         * List Of Object {equipmentType, equipmentId}
         */
        public List<EquipmentCommon> equipments;
        /**
         * List Of Object {internetProviderId, distributorId}
         */
        public list<PhoneObject> phones;
        /**
         * Object {internetProviderId, distributorId}
         */
        public AddressObject address;
        /**
         * List Of Object {internetProviderId, distributorId}
         */
        public list<EmailObject> email;
        /**
         * Object {}
         */
        public ContractObject contract;
    }
    public class EquipmentCommon {
        /**
         * Mandatory: Yes, Description: Equipment type
         */
        public String equipmentType;
        /**
         * Mandatory: Yes, Description: Equipment identifier
         */
        public String equipmentId;
    }
    public class ContractObject {
        /**
         * Mandatory: Yes, Description: Partner contrat identifier
         */
        public string externalContractId;
        /**
         * Mandatory: Yes, Description: Technology used by the partner to broadcast: ADSL,SAT,TNT.
         */
        public string broadcastVectorId;
        /**
         * Mandatory: Yes, Description: Commercial Operator
         */
        public string commercialOperator;
        /**
         * Mandatory: Yes, Description: Duration of the contract
         */
        public integer duration;
        /**
         * Object {mainOffer(Mandatory: No), options(Mandatory: No)}
         */
        public ProductObject products;
        /**
         * Mandatory: Yes, Description: Date of the subscription to our service by the partner customers. format 'YYYY/MM/DD 24H:MI:SS'
         */
        public string startDate;
        /**
         * Mandatory: Yes, Description: Indicator to allow adult programs
         */
        public Boolean fifthCategoryIndicator;
        /**
         * Mandatory: Yes, Description: Indicator for date to date subscription
         */
        public Boolean dateToDateIndicator;

        public string meaningOfPayment;

        public String saleGroupId;

        public Boolean dateToDate;
    }
    public class PartnerObject {
        public string partnerIdId;   
        public string transactionId;   
        public string internetProviderId;   
        public string externalPersonId;  
        public string externalContractId;
    }
    public class ProductObjectMigration {
        public String offerCode;    
        public Boolean adultContent;        
        public list<String> options;
    }
    public class identificationKeyObject {
        public String equipmentId;
        public String email;
        public String phone;
    }
    public class newSubResponse {

        public integer codeHttp;

        public string message;

        public string severity;

        public string returnCode;

        public newData data;
    }
    public class newData {

        public string numabo;

        public string numabont;

        public string transactionId;
    }
    public class acquittementObject {

        public string message;

        public string severity;

        public string returnCode;

        //public string data;
    }
    public class subActionsResponse {

        public integer codeHttp;

        public string severity;

        public acquittementObject acquittementObject;
    }
    public class EligMigrationResponse {
        // Success Status is 200
        public boolean eligible;
        public string endDate;
        // Failure Status is 422
        public string title; // "ERR_ELIGIBILITY_UNPROCESSED",    
        public integer status; // 422,    
        public string detail; //"Eligibility impossible due to functional error",    
        public string instance; //"BOMIESB",    
        public string code; //"Unprocessable Entity",    
    }
    public class RequestMigrationResponse {
        // Success Status is 200
        public String orderId; // Id of order
        public Long personId; // Person Id
        public String activationDate; // The migration date. At this date, the contract will be migrated.
        // Failure Status is 422
        public string title; // "ERR_ELIGIBILITY_UNPROCESSED",    
        public integer status; // 422,    
        public string detail; //"Eligibility impossible due to functional error",    
        public string instance; //"BOMIESB",    
        public string code; //"Unprocessable Entity",
    }
    public class PersonIdentificationResponse{
        public Long personId; // Success Status 200
        // Failure Status is 422 or 400
        public string title; // "ERR_ELIGIBILITY_UNPROCESSED",    
        public integer status; // 422,    
        public string detail; //"Eligibility impossible due to functional error",    
        public string instance; //"BOMIESB",    
        public string code; //"Unprocessable Entity",
    }
    public class Materialobject{
        public string equipment_Id; //21100009172633",
        public string equipment_Type; //G11A",
        public boolean eQ_Decodeur; //false,
        public boolean eQ_Have_Decoder; //true,
        public string id; //a1z5r000000Hn2HAAS",
        public string equipment; //21100009172633",
        public string type; //G11A"
    }
}