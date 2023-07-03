/**
 * Classe permettant de définir les Objets Apex correspondant aux objets Zuora utilisés pour
 * effectuer les appels API.
 *
 * Chaque Objet Apex présent dans la classe correspondera à un Objet Zuora et chaque Propriété Apex correspond à un
 * champ dans l'Objet Zuora
 *
 * @author Bilal El Aly
 * @date 2 Novembre 2020
 */
public class ZuoraObjects {
    public enum OrderType {
        NEW_SUBSCRIPTION,
        UPDATE_SUBSCRIPTION,
        ADD_PRODUCT,
        REMOVE_PRODUCT,
        UPDATE_PRODUCT,
        CANCEL_SUBSCRIPTION,
        RENEW_SUBSCRIPTION,
        TERMS_CONDITIONS,
        SUSPEND,
        RESUME
    }
    public static String post = 'POST';
    public static String put = 'PUT';
    public static String get = 'GET';
    public static String accountAPIUrl = '/v1/accounts/';
    public static String contactAPIUrl = '/v1/object/contact/';
    public static string ordersAPIUrl = '/v1/orders/';
    public static string previewOrdersAPIUrl = '/v1/orders/preview';
    public static string activateOrdersAPIUrl = '/triggerDates';
    public static string paymentAPIUrl = '/v1/payments/';
    public static string invoiceAPIUrl = '/v1/object/invoice/';
    public static string updateAccountAPIUrl = '/v1/object/account/';
    public static string billAPIUrl = '/billing-documents/generate';
    public static string subscriptionAPIUrl = '/v1/subscriptions/';
    public static string nullFieldsAPIUrl = '/v1/action/update';
    public static string workflowAPIUrl = '/workflows/';
    public static string tokenAPIUrl = '/oauth/token';
    public static string ratePlanAPIUrl = '/v1/rateplan/';
    public static string prpAPIUrl = '/productRatePlan';
    public static string creditMemoAPIURL = '/v1/creditmemos/';
    public static string usageAPIURL = '/v1/object/usage';
    //public static string getInvoiceAPIUrl = '/v1/billing-documents?accountId=';

    public class ZuoraOrder {
        /**
         * A description of the order.
         */
        public String description;
        /**
         * The account number that this order will be created under. It can be either the accountNumber or the account info provided.
         * It will return an error if both are specified.
         * Note that this actually specifies the invoice owner account of the subscriptions included in this order.
         */
        public String existingAccountNumber;
        /**
         * The information of the new account to be created with the order.
         * Note that this actually specifies the invoice owner account of the subscriptions included in this order.
         */
        public ZuoraAccount newAccount;
        /**
         * The date when the order is signed.
         * All the order actions under this order will use this order date as the contract effective date if the contract effective
         * date field is skipped or its value is left as null.
         */
        public String orderDate;
        /*
         *  Information about the account that will own the order
         * */
        public ZuoraPreviewAccount previewAccountInfo;
        /**
         * The order number of the new order. If not provided, system will auto-generate a number for this order.
         */
        public String orderNumber;
        /**
         * Invoice or Payment.
         */
        public ZuoraProcessingOptions processingOptions;
        /**
         * Each item includes a set of order actions, which will be applied to the same base subscription.
         */
        public List<ZuoraOrderSubscription> subscriptions;

        public ZuoraPreviewOptions previewOptions;

        public ZuoraOrderCustomFields customFields;
    }
    public class ZuoraOrderCustomFields {
        public string OperatorAgent_Reserved;
        public string SourceOperator_Reserved;
        public string Source_Reserved;
    }

    public class ZuoraPreviewAccount {
        /*
         * Day of the month that the account prefers billing periods to begin on. If set to 0, the bill cycle day will be set as "AutoSet".
         * */
        public integer billCycleDay;
        /**
         * 3 uppercase character currency code
         */
        public String currency_toReplace;
        /**
         * Contact details associated with an account.
         */
        public ZuoraContact soldToContact;
        /**
         * Information about the tax exempt status of a customer account.
         */
        public ZuoraTaxInfo taxInfo;
    }
    public class ZuoraUpdateAccount {
        /*
         * Day of the month that the account prefers billing periods to begin on. If set to 0, the bill cycle day will be set as "AutoSet".
         * */
        public integer BillCycleDay;
        /*
         * Billing cycle day setting option. Character limit: 9 Values: AutoSet, ManualSet
         */
        public string BcdSettingOption;
        /**
         * The ID of the payment method associated with this account. The payment method specified for this field will be set as the default payment method of the account.
         * If the autoPay field is set to true, you must provide the credit card payment method ID for either this field or the creditCard field, but not both.
         */
        public String DefaultPaymentMethodId;

    }
    public class ZuoraPreviewOptions {
        /*
         * The number of periods to preview when the value of the previewThroughType field is set to NumberOfPeriods
         * */
        public integer previewNumberOfPeriods;
        /*
         * Enum:"SpecificDate" "TermEnd" "NumberOfPeriods"
         * The options on how the preview through date is calculated. Available for preview only. The 'TermEnd' option is invalid when any subscription included in this order is evergreen.
         * */
        public string previewThruType;
        /*
         * Items Enum:"ChargeMetrics" "BillingDocs" "OrderMetrics" "RampMetrics" "RampDeltaMetrics". One or more types of the preview.
         * */
        public list<string> previewTypes;
        /*
         * The end date of the order preview. You can preview the invoice charges through the preview through date. (Invoice preview only)
         * */
        public string specificPreviewThruDate;
    }

    public class ZuoraAccount {
        /**
         * This variable is used to define if the Zuora Account already exists.
         * If yes, the callout will do automatic update. If not, the callout will create a new Account.
         */
        public String existingID;
        /**
         * The number of the Account.
         */
        public String accountNumber;
        /**
         * List of additional email addresses to receive emailed invoices. Values should be a comma-separated list of email addresses.
         */
        public String additionalEmailAddresses;
        /**
         * Indicates if associated invoices can be edited. Values are: true or false.
         */
        public Boolean allowInvoiceEdit;
        /**
         * Specifies whether future payments are to be automatically billed when they are due.
         */
        public boolean autoPay;
        /**
         * The grouping batch of the Account.
         */
        public String batch;
        /**
         * Day of the month that the account prefers billing periods to begin on. If set to 0, the bill cycle day will be set as "AutoSet".
         */
        public Integer billCycleDay;
        /*
         * Billing cycle day setting option. Character limit: 9 Values: AutoSet, ManualSet
         */
        public string BcdSettingOption;
        /**
         * Contact details associated with an account.
         */
        public ZuoraContact billToContact;
        /**
         * Default payment method associated with an account. Only credit card payment methods are supported.
         */
        public ZuoracreditCard creditCard;
        /*
         * Note: This field is only available if you have the Invoice Settlement feature enabled.
         * The Invoice Settlement feature is in Limited Availability.
         */
        public string creditMemoTemplateId;
        /**
         * The Salesforce ID for the corresponding Account in Salesforce
         */
        public String crmId;
        /**
         * 3 uppercase character currency code
         */
        public String currency_toReplace;
        /**
         * Name of the account's customer service representative, if applicable.
         */
        public String customerServiceRepName;
        /**
         * The unique ID of the debit memo template, configured in Billing Settings > Manage Billing
         * <b>Note: This field is only available if you have the Invoice Settlement feature enabled. The Invoice Settlement feature is in Limited Availability.
         * If you wish to have access to the feature, submit a request at Zuora Global Support.</b>
         */
        public String debitMemoTemplateId;
        /**
         * ID of the default payment method for the account. This field is required if the AutoPay field is set to true.
         * Character limit: 32 Values: a valid ID for an existing payment method
         *
         */
        public String DefaultPaymentMethodId;
        /**
         * The ID of the payment method associated with this account. The payment method specified for this field will be set as the default payment method of the account.
         * If the autoPay field is set to true, you must provide the credit card payment method ID for either this field or the creditCard field, but not both.
         */
        public String hpmCreditCardPaymentMethodId;
        /**
         * Specifies whether to turn on the invoice delivery method 'Email' for the new account. Values are: true or false
         */
        public Boolean invoiceDeliveryPrefsEmail;
        /**
         * Specifies whether to turn on the invoice delivery method 'Print' for the new account.
         */
        public Boolean invoiceDeliveryPrefsPrint;
        /**
         * The ID of the invoice template used for this account
         */
        public String invoiceTemplateId;
        /**
         * The name of the Account
         */
        public String name;
        /**
         * The notes for the Account
         */
        public String notes;
        /**
         * Identifier of the parent customer account for this Account object. Use this field if you have customer hierarchy enabled.
         */
        public String parentId;
        /**
         * The name of the payment gateway used for this account
         */
        public String paymentGateway;
        /**
         * Payment method to create for this new account.
         * Supports all the payment methods that are supported in the "Create payment method" operation.
         */
        public ZuoraPaymentMethod paymentMethod;
        /**
         * The payment term.
         */
        public String paymentTerm;
        /**
         * The number of the purchase order associated with this account. Purchase order information generally comes from customers.
         */
        public String purchaseOrderNumber;
        /**
         * The name of the sales representative associated with this account, if applicable.
         */
        public String salesRep;
        /**
         * The ID of the billing document sequence set to assign to the customer account.
         */
        public String sequenceSetId;
        /**
         * EU Value Added Tax ID.This feature is in Limited Availability.If you wish to have access to the feature, submit a request at Zuora Global Support .
         */
        public string VATId;
        /**
         * Contact details associated with an account.
         */
        public ZuoraContact soldToContact;
        /**
         * Information about the tax exempt status of a customer account.
         */
        public ZuoraTaxInfo taxInfo;

        public string communicationProfileId;

        public string Segment_Reserved;
        public string Company_Reserved;
        public string DataAccess_h;
        public string Type_Reserved;
        public string TaxID_Reserved;

        public ZuoraAccountCustomFields customFields;
    }
    public class ZuoraAccountCustomFields {
        public string Segment_Reserved;
        public string Company_Reserved;
        public string DataAccess_h;
        public string Type_Reserved;
        public string DistributorNumber_Reserved;
        public string TaxID_Reserved;

    }
    public class ZuoraPayment {
        /*
         * The ID of the customer account that the payment is created for.
         * */
        public string accountId;
        /*
         * The total amount of the payment.
         * */
        public double amount;
        /*
         * Additional information related to the payment.
         * */
        public string comment;
        /**
         * The transaction ID returned by the payment gateway for an electronic refund. Use this field to reconcile refunds between your gateway and Zuora Payments.
         */
        public string referenceId;
        /*
         *  currency defined in the web-based UI administrative settings
         * */
        public string currency_toReplace;
        /*
         * The date when the payment takes effect, in yyyy-mm-dd format
         * */
        public string effectiveDate;
        /*
         * The ID of the gateway instance that processes the payment. The ID must be a valid gateway instance ID and this gateway must support the specific payment method.
         * When creating electronic payments, this field is required.
         * When creating external payments, this field is optional.
         **/
        public string gatewayId;
        /*
         * Enum:"External" "Electronic"
         * The type of the payment.
         **/

        public string type;
        /*
         * The unique ID of the payment method that the customer used to make the payment.
         * If no payment method ID is specified in the request body, the default payment method for the customer account is used automatically.
         * If the default payment method is different from the type of payments that you want to create, an error occurs
         **/
        public string paymentMethodId;
        /*
         * Array of object (invoices)
         * Container for invoices.
         */
        public list<ZuoraBilling> invoices;
        // Custom Fields
        public string OperatorAgent_Reserved;
        public string SourceOperator_Reserved;
        public string Source_Reserved;
        public string OrderNumber_Reserved;
        public string Processing_Reserved;
        public string PrepaidPeriods_Reserved;
        public string AccountCurrencyAmount_Reserved;
        public string HomeCurrencyAmount_Reserved;
        public string HomeCurrencyRate_Reserved;
        public string HomeCurrency_Reserved;
        public string PaymentProcessor_Reserved;
        public string DistributorOriginalPaymentSource_Reserved;
        public string DistributorPaymentSource_Reserved;
    }

    public class ZuoraRefundPayment {
        /*
         * string [ 0 .. 255 ] characters.Comments about the refund.
         * */
        public string comment;
        /**
         * string Enum:"ACH" "Cash" "Check" "CreditCard" "PayPal" "WireTransfer" "DebitCard" "CreditCardReferenceTransaction" "BankTransfer" "Other"
         */
        public string methodType;
        /**
         * A code identifying the reason for the transaction. The value must be an existing reason code or empty. If you do not specify a value, Zuora uses the default reason code.
         */
        public string reasonCode;
        /**
         * The transaction ID returned by the payment gateway for an electronic refund. Use this field to reconcile refunds between your gateway and Zuora Payments.
         */
        public string referenceId;
        /**
         * The date when the refund takes effect, in yyyy-mm-dd format. The date of the refund cannot be before the payment date. Specify this field only for external refunds. Zuora automatically generates this field for electronic refunds.
         */
        public string refundDate;
        /**
         * The transaction ID returned by the payment gateway if there is an additional transaction for the refund. Use this field to reconcile payments between your gateway and Zuora Payments.
         */
        public string secondRefundReferenceId;
        /**
         * A payment gateway-specific field that maps to Zuora for the gateways, Orbital, Vantiv and Verifi.
         */
        public string softDescriptor;
        /**
         * A payment gateway-specific field that maps to Zuora for the gateways, Orbital, Vantiv and Verifi.
         */
        public string softDescriptorPhone;
        /**
         * The total amount of the refund. The amount cannot exceed the unapplied amount of the associated payment. If the original payment was applied to one or more invoices or debit memos, you have to unapply a full or partial payment from the invoices or debit memos, and then refund the full or partial unapplied payment to your customers.
         */
        public double totalAmount;
        /**
         * Enum:"External" "Electronic"
         * The type of the refund.
         */
        public string type;

        public string AccountCurrencyAmount_Reserved;
        public string HomeCurrencyAmount_Reserved;
        public string HomeCurrencyRate_Reserved;
        public string HomeCurrency_Reserved;
        public string OperatorAgent_Reserved;
        public string SourceOperator_Reserved;
        public string Source_Reserved;
        public string DistributorOriginalPaymentSource_Reserved;
        public string DistributorPaymentSource_Reserved;
    }
    public class ZuoraContact {
        /**
         * This variable is used to define if the Zuora Contact already exists.
         * If yes, the callout will do automatic update. If not, the callout will create a new Contact.
         */
        public String existingID;

        public string AccountID;
        /**
         * First line of the contact's address. This is often a street address or a business name
         */
        public String address1;
        /**
         * Second line of the contact's address.
         */
        public String address2;
        /**
         * City of the contact's address.
         */
        public String city;
        /**
         * A description for the contact.
         */
        public String contactDescription;
        /**
         * Country; must be a valid country name or abbreviation.
         * If using Zuora Tax, you must specify a country in the bill-to contact to calculate tax.
         */
        public String country;
        /**
         * First name of the contact.
         */
        public String firstName;
        /**
         * Home phone number of the contact.
         */
        public String homePhone;
        /**
         * Last name of the contact.
         */
        public String lastName;
        /**
         * Mobile phone number of the contact.
         */
        public String mobilePhone;
        /**
         * Nickname of the contact.
         */
        public String nickname;
        /**
         * Additional phone number of the contact. Use the otherPhoneType field to specify the type of phone number.
         */
        public String otherPhone;
        /**
         * Specifies the type of phone number in the otherPhone field.
         */
        public String otherPhoneType;
        /**
         * Personal email address of the contact.
         */
        public String personalEmail;
        /**
         * ZIP code or other postal code of the contact's address.
         */
        public String postalCode;
        /**
         * State or province of the contact's address.
         */
        public String state;
        /**
         * Region defined in your taxation rules. Only applicable if you use Zuora Tax.
         */
        public String taxRegion;
        /**
         * Business email address of the contact.
         */
        public String workEmail;
        /**
         * Business phone number of the contact.
         */
        public String workPhone;
        /*
         * Zip code, 20 characters or less.
         */
        public string zipCode;
    }

    public class ZuoracreditCard {
        /**
         * Information about the cardholder of a credit card payment method associated with an account.
         * If you do not provide information about the cardholder, Zuora uses the account's bill-to contact.
         */
        public ZuoracardHolderInfo cardHolderInfo;
        /**
         * Card number. Once set, you cannot update or query the value of this field. The value of this field is only available in masked format.
         * For example, XXXX-XXXX-XXXX-1234 (hyphens must not be used when you set the credit card number).
         */
        public String cardNumber;
        /**
         * Enum:"Visa" "MasterCard" "AmericanExpress" "Discover" "JCB" "Diners" "CUP" "Maestro" "Electron" "AppleVisa"
         * "AppleMasterCard" "AppleAmericanExpress" "AppleDiscover" "AppleJCB" "Elo" "Hipercard" "Naranja" "Nativa"
         * "TarjetaShopping" "Cencosud" "Argencard" "Cabal" Type of card.
         */
        public String cardType;
        /**
         * Expiration date of the card.
         */
        public Integer expirationMonth;
        /**
         * Expiration year of the card.
         */
        public Integer expirationYear;
        /**
         * VV or CVV2 security code of the card. To ensure PCI compliance, Zuora does not store the value of this field.
         */
        public Integer securityCode;
    }

    public class ZuoracardHolderInfo {
        /**
         * First line of the cardholder's address.
         */
        public String addressLine1;
        /**
         * Second line of the cardholder's address.
         */
        public String addressLine2;
        /**
         * Full name of the cardholder as it appears on the card. For example, "John J Smith".
         */
        public String cardHolderName;
        /**
         * City of the cardholder's address.
         */
        public String city;
        /**
         * Country of the cardholder's address. The value of this field must be a valid country name or abbreviation.
         */
        public String country;
        /**
         * Email address of the cardholder.
         */
        public String email;
        /**
         * Phone number of the cardholder.
         */
        public String phone;
        /**
         * State or province of the cardholder's address.
         */
        public String state;
        /**
         * ZIP code or other postal code of the cardholder's address.
         */
        public String zipCode;
    }

    public class ZuoraPaymentMethod {
        /**
         * Enum:"PayPalEC" "PayPalNativeEC" "PayPalAdaptive" "CreditCard" "ACH" "SEPA" "Betalingsservice" "Autogiro" "Bacs"
         * Type of payment method.
         */
        public String type;
        /**
         * ID of a PayPal billing agreement. For example, I-1TJ3GAGG82Y9.
         */
        public String BAID;
        /**
         * Email address associated with the payment method.
         * This field is required if you want to create a PayPal Express Checkout payment method or a PayPal Adaptive payment method.
         */
        public String email;
        /**
         * The PayPal preapproval key.
         */
        public String preapprovalKey;
        /**
         * Container for cardholder information. If provided, Zuora will only use this information for this card.
         * Otherwise, Zuora will use the account''s existing bill-to contact information for this card.
         */
        public ZuoracardHolderInfo cardHolderInfo;
        /**
         * Credit card number.
         */
        public String cardNumber;
        /**
         * The type of the credit card. Possible values include Visa, MasterCard, AmericanExpress, Discover, JCB, and Diners.
         */
        public String cardType;
        /**
         * Indicates whether the duplication check is performed when you create a new credit card payment method. The default value is false.
         */
        public Boolean checkDuplicated;
        /**
         * One or two digit expiration month (1-12) of the credit card.
         */
        public String expirationMonth;
        /**
         * Four-digit expiration year of the credit card.
         */
        public String expirationYear;
        /**
         * FSpecifies your reference for the stored credential consent agreement that you have established with the customer.
         * Only applicable if you set the mitProfileAction field.
         */
        public String mitConsentAgreementRef;
        /**
         * Value:"External". Required if you set the mitProfileAction field.
         */
        public String mitConsentAgreementSrc;
        /**
         * Specifies the ID of a network transaction. Only applicable if you set the mitProfileAction field to Persist.
         */
        public String mitNetworkTransactionId;
        /**
         * Enum:"Activate" "Persist". If you set this field, Zuora creates a stored credential profile within the payment method.
         */
        public String mitProfileAction;
        /**
         * The date on which the profile is agreed. The date format is yyyy-mm-dd.
         */
        public String mitProfileAgreedOn;
        /**
         * Value:"Recurring". Required if you set the mitProfileAction field.
         */
        public String mitProfileType;
        /**
         * CVV or CVV2 security code of the credit card. To ensure PCI compliance, this value is not stored and cannot be queried.
         */
        public String securityCode;
        /**
         * First address line, 255 characters or less.
         */
        public String addressLine1;
        /**
         * Second address line, 255 characters or less.
         */
        public String addressLine2;
        /**
         * The nine-digit routing number or ABA number used by banks. This field is only required if the type field is set to ACH.
         */
        public String bankABACode;
        /**
         * The name of the account holder, which can be either a person or a company. This field is only required if the type field is set to ACH.
         */
        public String bankAccountName;
        /**
         * The bank account number associated with the ACH payment. This field is only required if the type field is set to ACH.
         */
        public String bankAccountNumber;
        /**
         * Enum:"BusinessChecking" "Checking" "Saving".
         * The type of bank account associated with the ACH payment. This field is only required if the type field is set to ACH.
         */
        public String bankAccountType;
        /**
         * The name of the bank where the ACH payment account is held. This field is only required if the type field is set to ACH.
         */
        public String bankName;
        /**
         * City, 40 characters or less.
         */
        public String city;
        /**
         * Country, must be a valid country name or abbreviation.
         */
        public String country;
        /**
         * Phone number, 40 characters or less.
         */
        public String phone;
        /**
         * State, must be a valid state name or 2-character abbreviation.
         */
        public String state;
        /**
         * Zip code, 20 characters or less.
         */
        public String zipCode;
        /**
         * Internal ID of the customer account that will own the payment method.
         */
        public String accountKey;
        /**
         * Internal ID of the payment gateway that Zuora will use to authorize the payments that are made with the payment method.
         */
        public String authGateway;
        /**
         * Specifies whether the payment method will be the default payment method of the customer account that owns the payment method.
         */
        public String makeDefault;
        /**
         * The International Bank Account Number. This field is used to create the SEPA payment method.
         */
        public String IBAN;
        /**
         * Information on the account holder.
         */
        public ZuoraAccountHolderInfo accountHolderInfo;
        /**
         * The number of the customer's bank account. Use this field for direct debit payment methods
         */
        public String accountNumber;
        /**
         * The sort code or number that identifies the bank. This is also known as the sort code.
         */
        public String bankCode;
        /**
         * The branch code of the bank used for direct debit.
         */
        public String branchCode;
        /**
         * The BIC code used for SEPA.
         */
        public String businessIdentificationCode;
        /**
         * The identity number used for Bank Transfer.
         */
        public String identityNumber;
    }

    public class ZuoraAccountHolderInfo {
        /**
         * The full name of the bank account holder.
         */
        public String accountHolderName;
        /**
         * The first line of the address for the account holder.
         */
        public String addressLine1;
        /**
         * The second line of the address for the account holder.
         */
        public String addressLine2;
        /**
         * The city where the account holder stays.
         */
        public String city;
        /**
         * The email address of the account holder.
         */
        public String email;
        /**
         * The first name of the account holder.
         */
        public String firstName;
        /**
         * The last name of the account holder.
         */
        public String lastName;
        /**
         * The phone number of the account holder.
         */
        public String phone;
        /**
         * The state where the account holder stays.
         */
        public String state;
        /**
         * The zip code for the address of the account holder.
         */
        public String zipCode;
    }

    public class ZuoraTaxInfo {
        /**
         * EU Value Added Tax ID.
         * Note: This feature is in Limited Availability. If you wish to have access to the feature, submit a request at Zuora Global Support.
         */
        public String VATId;
        /**
         * Unique code that identifies a company account in Avalara. Use this field to calculate taxes based on origin and sold-to addresses in Avalara.
         */
        public String companyCode;
        /**
         * ID of the customer tax exemption certificate. Applicable if you use Zuora Tax or Connect tax engines.
         */
        public String exemptCertificateId;
        /**
         * Type of tax exemption certificate that the customer holds. Applicable if you use Zuora Tax or Connect tax engines.
         */
        public String exemptCertificateType;
        /**
         * Description of the tax exemption certificate that the customer holds. Applicable if you use Zuora Tax or Connect tax engines.
         */
        public String exemptDescription;
        /**
         * Date when the customer tax exemption starts, in YYYY-MM-DD format. Applicable if you use Zuora Tax or Connect tax engines.
         */
        public String exemptEffectiveDate;
        /**
         * Date when the customer tax exemption expires, in YYYY-MM-DD format. Applicable if you use Zuora Tax or Connect tax engines.
         */
        public String exemptExpirationDate;
        /**
         * Jurisdiction in which the customer tax exemption certificate was issued.
         */
        public String exemptIssuingJurisdiction;
        /**
         * Status of the account tax exemption. Applicable if you use Zuora Tax or Connect tax engines. Required if you use Zuora Tax.
         * Default: "No".
         * Enum:"No" "Yes" "PendingVerification".
         */
        public String exemptStatus;
    }

    public class ZuoraProcessingOptions {
        /**
         * The priority order to apply credit memos and/or unapplied payments to an invoice. Possible item values are: CreditMemo, UnappliedPayment.
         */
        public list<String> applicationOrder;
        /**
         * Whether to automatically apply credit memos or unapplied payments, or both to an invoice.
         */
        public Boolean applyCredit;
        /**
         * Indicates if any credit balance on a customer's account is automatically applied to invoices.
         * If no value is specified then this field defaults to false.
         */
        public Boolean applyCreditBalance;
        /**
         * Indicates if any credit balance on a customer's account is automatically applied to invoices.
         * If no value is specified then this field defaults to false.
         */
        public ZuoraBillingOptions billingOptions;
        /**
         * Indicates if the current request needs to collect payments. This value can not be 'true' when 'runBilling' flag is 'false'.
         */
        public Boolean collectPayment;
        /**
         * Indicates if the current request needs to generate an invoice. The invoice will be generated against all subscriptions included in this order.
         */
        public Boolean runBilling;
        /**
         * Container for the electronic payment options.
         */
        public ZuoraElectronicPaymentOptions electronicPaymentOptions;
    }

    public class ZuoraBillingOptions {
        public String documentDate;
        public String targetDate;
    }

    public class ZuoraElectronicPaymentOptions {
        public String paymentMethodId;
    }
    public class ZuoraCreditMemo {
        public String OperatorAgent_Reserved;
        public String SourceOperator_Reserved;
        public String Source_Reserved;
        public String HomeCurrencyRate_Reserved;
        public String HomeCurrency_Reserved;
        public String TaxAuthStatus_Reserved;
    }

    public class ZuoraOrderSubscription {
        /**
         * Leave this empty to represent new subscription creation. Specify a subscription number to update an existing subscription.
         */
        public String subscriptionNumber;

        /**
         * The actions to be applied to the subscription. Order actions will be stored with the sequence when it was provided in the request.
         */
        public List<ZuoraOrderAction> orderActions;
        /**
         * Container of the ramp definitions. It is used to create, update, or remove the ramp definition for the new subscription.
         */
        public ZuoraRamp ramp;
        /*
         * Container of custom fields
         * */
        public ZuoraSubscriptionCustomFields customFields;
    }
    public class ZuoraSubscriptionCustomFields {
        public string CancelReason_Reserved;
        public string Type_Reserved;
        public string SF_QuoteID_Reserved;
        public string RenewalSequenceNumber_Reserved;
        public date ExpectedRenewalDate_Reserved;
        public string SuspensionReason_Reserved;
        public string CompensationDaysAtNextRenewal_Reserved;
        public string BoxNumber_Reserved;
        public string WarrantyEndDate_Reserved;
        public string isCollaborator_Reserved;
        public string SuspensionResumeDate_Reserved;
    }

    public class ZuoraOrderAction {
        /**
         * Information about an order action of type addProduct.
         */
        public ZuoraAddProduct addProduct;
        /**
         * Information about an order action of type CancelSubscription.
         */
        public ZuoraCancelSubscription cancelSubscription;
        /**
         * Information about an order action of type CreateSubscription.
         */
        public ZuoraCreateSubscription createSubscription;
        /**
         * Information about an order action of type OwnerTransfer.
         */
        public ZuoraOwnerTransfer ownerTransfer;
        /**
         * Information about an order action of type RemoveProduct.
         */
        public ZuoraRemoveProduct removeProduct;
        /**
         * Information about an order action of type Resume.
         */
        public ZuoraResumeAction resume;
        /**
         * Information about an order action of type Resume.
         */
        public ZuoraSuspendAction suspend;
        /**
         * Information about an order action of type TermsAndConditions.
         */
        public ZuoraTermsAndConditions termsAndConditions;
        /**
         * Container for the contract effective, service activation, and customer acceptance dates of the order action.
         */
        public List<ZuoraTriggerDate> triggerDates;
        /**
         * Enum:"CreateSubscription" "TermsAndConditions" "AddProduct" "UpdateProduct" "RemoveProduct" "RenewSubscription" "CancelSubscription" "OwnerTransfer" "Suspend" "Resume"
         * Type of order action.
         * Unless the type of order action is RenewSubscription, you must use the corresponding field to provide information about the order action.
         * For example, if the type of order action is AddProduct, you must set the addProduct field.
         */
        public String type;
        /**
         * Information about an order action of type UpdateProduct.
         */
        public ZuoraUpdateProduct updateProduct;
        /*
         * Identifies which order action will have its triggering dates updated
         */
        public integer sequence;
    }

    public class ZuoraAddProduct {
        /**
         * Internal identifier of the product rate plan that the rate plan is based on.
         */
        public String productRatePlanId;
        /**
         * List of charges associated with the rate plan.
         */
        public List<ZuoraChargeOverride> chargeOverrides;
        /**
         * Unique identifier for the rate plan. This identifier enables you to refer to the rate plan before the rate plan has an internal identifier in Zuora.
         */
        public String uniqueToken;
    }

    public class ZuoraChargeOverride {
        /**
         * Billing information about the charge.
         */
        public ZuoraBilling billing;
        /**
         * Charge number of the charge. For example, C-00000307. If you do not set this field, Zuora will generate the charge number.
         */
        public String chargeNumber;
        /**
         * Description of the charge.
         */
        public String description;
        /**
         * Specifies when a charge becomes inactive.
         */
        public ZuoraEndDate endDate;
        /**
         * Pricing information about the charge.
         */
        public ZuoraPricing pricing;
        /**
         * Internal identifier of the product rate plan charge that the charge is based on.
         */
        public String productRatePlanChargeId;
        /**
         * Revenue Recognition Code
         */
        public String revRecCode;
        /**
         * Enum:"Contract Effective Date" "Service Activation Date" "Customer Acceptance Date".
         * Specifies the revenue recognition
         */
        public String revRecTriggerCondition;
        /**
         * Enum:"Recognize upon invoicing" "Recognize daily over time".
         * Specifies the revenue recognition rule.
         */
        public String revenueRecognitionRuleName;
        /**
         * Specifies when a charge becomes active.
         */
        public ZuoraStartDate startDate;
        /**
         * Unique identifier for the charge. This identifier enables you to refer to the charge before the charge has an internal identifier in Zuora.
         */
        public String uniqueToken;
    }

    public class ZuoraBilling {
        /**
         * Day of the month that each billing period begins on. Only applicable if the value of the billCycleType field is SpecificDayofMonth.
         */
        public Integer billCycleDay;
        /**
         * Enum:"DefaultFromCustomer" "SpecificDayofMonth" "SubscriptionStartDay" "ChargeTriggerDay" "SpecificDayofWeek"
         */
        public String billCycleType;
        /**
         * Enum:"Month" "Quarter" "Semi_Annual" "Annual" "Eighteen_Months" "Two_Years" "Three_Years" "Five_Years" "Specific_Months" "Subscription_Term" "Week" "Specific_Weeks".
         * Billing frequency of the charge. The value of this field controls the duration of each billing period.
         */
        public Integer billingPeriod;
        /**
         * Enum:"AlignToCharge" "AlignToSubscriptionStart" "AlignToTermStart".
         * Specifies how Zuora determines when to start new billing periods. You can use this field to align the billing periods of different charges.
         */
        public Integer billingPeriodAlignment;
        /**
         * Enum:"IN_ADVANCE" "IN_ARREARS"
         * Specifies whether to invoice for a billing period on the first day of the billing period (billing in advance) or the first day of the next billing period (billing in arrears).
         */
        public Integer billingTiming;
        /**
         * Duration of each billing period in months or weeks, depending on the value of the billingPeriod field.
         * Only applicable if the value of the billingPeriod field is Specific_Months or Specific_Weeks.
         */
        public Integer specificBillingPeriod;
        /**
         * Enum:"Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday"
         * Day of the week that each billing period begins on. Only applicable if the value of the billCycleType field is SpecificDayofWeek.
         */
        public Integer weeklyBillCycleDay;
        /*Default: false
         * Enum:true false
         * Whether to automatically post the billing documents after the draft billing documents are generated.
         * If an error occurs during posting billing documents, the draft billing documents are not generated too.
         */
        public Boolean autoPost;
        /*
         * Whether to automatically renew the subscriptions with Auto Renew set to Yes.
         */
        public Boolean autoRenew;
        /*
         * The types of the charges to be excluded from the generation of billing documents. The field values are case insensitive.
         * Supported values include onetime, recurring, and usage.
         */
        public list<String> chargeTypeToExclude;
        /*
         * The date on which to generate the billing documents, in yyyy-mm-dd format.
         */
        public string effectiveDate;
        /*
         * The IDs of the subscriptions that you want to create the billing documents for.
         */
        public list<String> subscriptionIds;
        /*
         * The date used to determine which charges are to be billed, in yyyy-mm-dd format.
         */
        public String targetDate;
        /*
         * The unique ID of the invoice that the payment is applied to.
         */
        public String invoiceId;
        /*
         * The amount that is applied from the payment to the invoice.
         */
        public double amount;
        // Custom Fields
        public string OperatorAgent_Reserved;
        public string SourceOperator_Reserved;
        public string Source_Reserved;
        public string PrepaidPeriods_Reserved;
        public string HomeCurrencyRate_Reserved;
        public string HomeCurrency_Reserved;
    }
    public class ZuoraEndDate {
        /**
         * Enum:"Subscription_End" "Fixed_Period" "Specific_End_Date".
         * Condition for the charge to become inactive.
         */
        public String endDateCondition;
        /**
         * Date in YYYY-MM-DD format. Only applicable if the value of the endDateCondition field is Specific_End_Date.
         */
        public String specificEndDate;
        /**
         * Duration of the charge in billing periods, days, weeks, months, or years, depending on the value of the upToPeriodsType field.
         * Only applicable if the value of the endDateCondition field is Fixed_Period.
         */
        public Integer upToPeriods;
        /**
         * Enum:"Billing_Periods" "Days" "Weeks" "Months" "Years".
         * Unit of time that the charge duration is measured in. Only applicable if the value of the endDateCondition field is Fixed_Period.
         */
        public Integer upToPeriodsType;
    }

    public class ZuoraPricing {
        /**
         * Container for charge model configuration data.
         * Note: This field is only available if you have the High Water Mark, Pre-Rated Pricing, or Multi-Attribute Pricing charge models enabled.
         */
        public ZuoraChargeModelData chargeModelData;
        /**
         * Pricing information about a discount charge.
         */
        public ZuoraDiscount discount;
        /**
         * Pricing information about a one-time charge that uses the "flat fee" charge model. In this charge model, the charge has a fixed price.
         */
        public ZuoraOneTimeFlatFee oneTimeFlatFee;
        /**
         * Pricing information about a one-time charge that uses the "per unit" charge model.
         * In this charge model, the charge has a fixed price per unit purchased.
         */
        public ZuoraOneTimePerUnit oneTimePerUnit;
        /**
         * Pricing information about a one-time charge that uses the "tiered pricing" charge model.
         * In this charge model, the charge has cumulative pricing tiers that become effective as units are purchased.
         */
        public ZuoraOneTimeTiered oneTimeTiered;
        /**
         * Pricing information about a one-time charge that uses the "volume pricing" charge model.
         * In this charge model, the charge has a variable price per unit, depending on how many units are purchased.
         */
        public ZuoraOneTimeTiered oneTimeVolume;
        /**
         * Pricing information about a recurring charge that uses the "flat fee" charge model. In this charge model, the charge has a fixed price.
         */
        public ZuoraRecurringFlatFee recurringFlatFee;
        /**
         * Pricing information about a recurring charge that uses the "per unit" charge model.
         * In this charge model, the charge has a fixed price per unit purchased.
         */
        public ZuoraRecurringFlatFee recurringPerUnit;
        /**
         * Pricing information about a recurring charge that uses the "tiered pricing" charge model.
         * In this charge model, the charge has cumulative pricing tiers that become effective as units are purchased.
         */
        public ZuoraRecurringFlatFee recurringTiered;
        /**
         * Pricing information about a recurring charge that uses the "volume pricing" charge model.
         * In this charge model, the charge has a variable price per unit, depending on how many units are purchased.
         */
        public ZuoraRecurringFlatFee recurringVolume;
        /**
         * Pricing information about a usage charge that uses the "flat fee" charge model. In this charge model, the charge has a fixed price.
         */
        public ZuoraRecurringFlatFee usageFlatFee;
        /**
         * Pricing information about a usage charge that uses the "overage" charge model.
         * In this charge model, the charge has an allowance of free units and a fixed price per additional unit consumed.
         */
        public ZuoraUsageOverage usageOverage;
        /**
         * Pricing information about a usage charge that uses the "per unit" charge model.
         * In this charge model, the charge has a fixed price per unit consumed.
         */
        public ZuoraRecurringFlatFee usagePerUnit;
        /**
         * Pricing information about a usage charge that uses the "tiered pricing" charge model.
         * In this charge model, the charge has cumulative pricing tiers that become effective as units are consumed.
         */
        public ZuoraRecurringFlatFee usageTiered;
        /**
         * Pricing information about a usage charge that uses the "volume pricing" charge model.
         * In this charge model, the charge has a variable price per unit, depending on how many units are consumed.
         */
        public ZuoraRecurringFlatFee usageVolume;
    }

    public class ZuoraChargeModelData {
        /**
         * Container for charge model configuration data.
         * Note: This field is only available if you have the High Water Mark, Pre-Rated Pricing, or Multi-Attribute Pricing charge models enabled.
         */
        public ZuoraChargeModelConfiguration chargeModelConfiguration;
        /**
         * List of cumulative pricing tiers in the charge.
         * Note: When you override tiers of the charge with a High Water Mark Pricing charge model,
         * you have to provide all of the tiers, including the ones you do not want to change. The new tiers will completely override the previous ones.
         */
        public List<ZuoraTier> tiers;
    }

    public class ZuoraChargeModelConfiguration {
        /**
         * The custom field that carries the per-unit rate for each usage record. For example, perUnitAmount__c.
         */
        public String customFieldPerUnitRate;
        /**
         * The custom field that carries the total amount to charge for a usage record. For example, totalAmount__c.
         */
        public String customFieldTotalAmount;
        /**
         * The pricing formula to calculate actual rating amount for each usage record.
         * This field is only available for the usage-based charges that use the Multi-Attribute Pricing charge model.
         */
        public String formula;
    }

    public class ZuoraTier {
        /**
         * Limit on the number of units for which the tier is effective.
         */
        public Decimal endingUnit;
        /**
         * Price or per-unit price of the tier, depending on the value of the priceFormat field.
         */
        public Decimal price;
        /**
         * Specifies whether the tier has a fixed price or a per-unit price.
         * Enum:"FlatFee" "PerUnit".
         */
        public String priceFormat;
        /**
         * Number of units at which the tier becomes effective.
         */
        public Decimal startingUnit;
        /**
         * Index of the tier in the charge.
         */
        public Integer tier;
    }

    public class ZuoraDiscount {
        /**
         * Enum:"ONETIME" "RECURRING" "USAGE" "ONETIMERECURRING" "ONETIMEUSAGE" "RECURRINGUSAGE" "ONETIMERECURRINGUSAGE".
         * Specifies which type of charge the discount charge applies to.
         */
        public String applyDiscountTo;
        /**
         * Only applicable if the discount charge is a fixed-amount discount.
         */
        public String discountAmount;
        /**
         * Enum:"rateplan" "subscription" "account".
         * Application scope of the discount charge. For example, if the value of this field is
         * subscription and the value of the applyDiscountTo field is RECURRING, the discount charge applies to all recurring charges in the
         * same subscription as the discount charge.
         */
        public String discountLevel;
        /**
         * Only applicable if the discount charge is a percentage discount.
         */
        public String discountPercentage;
        /**
         * Enum:"NoChange" "UseLatestProductCatalogPricing".
         * Specifies how Zuora changes the price of the charge each time the subscription renews.
         */
        public String priceChangeOption;
    }

    public class ZuoraOneTimeFlatFee {
        /**
         * Price of the charge.
         */
        public Decimal listPrice;
    }

    public class ZuoraOneTimePerUnit {
        /**
         * Per-unit price of the charge.
         */
        public Decimal listPrice;
        /**
         * Number of units purchased.
         */
        public Decimal quantity;
    }

    public class ZuoraOneTimeTiered {
        /**
         * Number of units purchased.
         */
        public Decimal quantity;
        /**
         * List of cumulative pricing tiers in the charge
         */
        public List<ZuoraTier> tiers;
    }

    public class ZuoraRecurringFlatFee {
        /**
         * Enum:"NoChange" "SpecificPercentageValue" "UseLatestProductCatalogPricing".
         * Specifies how Zuora changes the price of the charge each time the subscription renews.
         */
        public String priceChangeOption;
        /**
         * Specifies the percentage by which the price of the charge should change each time the subscription renews.
         * Only applicable if the value of the priceChangeOption field is SpecificPercentageValue.
         */
        public Decimal priceIncreasePercentage;
        /**
         * Price of the charge in each recurring period.
         * NOT APPLICABLE FOR recurringTiered, recurringVolume
         */
        public Decimal listPrice;
        /**
         * Enum:"Per_Billing_Period" "Per_Month" "Per_Week".
         * Specifies the duration of each recurring period.
         */
        public String listPriceBase;
        /**
         * Number of units purchased.
         * ONLY APPLICABLE FOR recurringPerUnit, recurringVolume
         */
        public String quantity;
        /**
         * List of cumulative pricing tiers in the charge.
         * ONLY APPLICABLE FOR recurringTiered, recurringVolume
         */
        public List<ZuoraTier> tiers;
        /**
         * Enum:"ByBillingPeriod" "ByUsageStartDate" "ByUsageRecord" "ByUsageUpload".
         * Specifies how Zuora groups usage records when rating usage.
         * ONLY APPLICABLE FOR usagePerUnit
         */
        public String ratingGroup;
    }

    public class ZuoraUsageOverage {
        /**
         * Enum:"NoChange" "SpecificPercentageValue" "UseLatestProductCatalogPricing".
         * Specifies how Zuora changes the price of the charge each time the subscription renews.
         */
        public String priceChangeOption;
        /**
         * Specifies the percentage by which the price of the charge should change each time the subscription renews.
         * Only applicable if the value of the priceChangeOption field is SpecificPercentageValue.
         */
        public Decimal priceIncreasePercentage;
        /**
         * Number of free units that may be consumed.
         */
        public Decimal includedUnits;
        /**
         * Number of periods that Zuora considers when calculating overage charges with overage smoothing.
         */
        public Integer numberOfPeriods;
        /**
         * Price per overage unit consumed.
         */
        public Integer overagePrice;
        /**
         * Enum:"NoCredit" "CreditBySpecificRate".
         * Specifies whether to credit the customer for unused units.
         */
        public Integer overageUnusedUnitsCreditOption;
        /**
         * Per-unit rate at which to credit the customer for unused units.
         * Only applicable if the value of the overageUnusedUnitsCreditOption field is CreditBySpecificRate.
         */
        public Decimal unusedUnitsCreditRates;
    }

    public class ZuoraStartDate {
        /**
         * Date in YYYY-MM-DD format. Only applicable if the value of the triggerEvent field is SpecificDate.
         * While this field is applicable, if this field is not set, your CreateSubscription order action creates
         * a Pending order and a Pending Acceptance subscription. If at the same time the service activation date is required and not set, a Pending Activation subscription is created.
         */
        public String specificTriggerDate;
        /**
         * Enum:"ContractEffective" "ServiceActivation" "CustomerAcceptance" "SpecificDate".
         * Condition for the charge to become active.
         */
        public String triggerEvent;
    }

    public class ZuoraCancelSubscription {
        /**
         * The effective date of the cancellation
         */
        public String cancellationEffectiveDate;
        /**
         * Enum:"EndOfCurrentTerm" "EndOfLastInvoicePeriod" "SpecificDate"
         */
        public String cancellationPolicy;
    }

    public class ZuoraCreateSubscription {
        /**
         * Specifies whether the subscription appears on a separate invoice when Zuora generates invoices.
         */
        public boolean invoiceSeparately;
        /**
         * Information about a new account that will own the subscription. Only available if you have enabled the Owner Transfer feature.
         */
        public ZuoraAccount newSubscriptionOwnerAccount;
        /**
         * Notes about the subscription. These notes are only visible to Zuora users.
         */
        public String notes;
        /**
         * List of rate plans associated with the subscription.
         */
        public list<ZuorasubscribeToRatePlans> subscribeToRatePlans;
        /**
         * Subscription number of the subscription. For example, A-S00000001.
         * If you do not set this field, Zuora will generate the subscription number.
         */
        public String subscriptionNumber;
        /**
         * Account number of an existing account that will own the subscription.
         * For example, A00000001.
         */
        public String subscriptionOwnerAccountNumber;
        /**
         * Container for the terms and renewal settings of the subscription.
         */
        public ZuoraTerms terms;
    }

    public class ZuorasubscribeToRatePlans {
        /**
         * List of charges associated with the rate plan.
         */
        public List<ZuoraChargeOverride> chargeOverrides;
        /**
         * Internal identifier of the product rate plan that the rate plan is based on.
         */
        public String productRatePlanId;
        /**
         * Unique identifier for the rate plan.
         * This identifier enables you to refer to the rate plan before the rate plan has an internal identifier in Zuora.
         */
        public String uniqueToken;
    }

    public class ZuoraTerms {
        /**
         * Specifies whether the subscription automatically renews at the end of the each term.
         * Only applicable if the type of the first term is TERMED.
         */
        public boolean autoRenew;
        /**
         * Information about the first term of the subscription.
         */
        public ZuoraInitialTerm initialTerm;
        /**
         * Enum:"RENEW_WITH_SPECIFIC_TERM" "RENEW_TO_EVERGREEN".
         * Specifies the type of the terms that follow the first term if the subscription is renewed. Only applicable if the type of the first term is TERMED.
         */
        public String renewalSetting;
        /**
         * List of renewal terms of the subscription.
         * Only applicable if the type of the first term is TERMED and the value of the renewalSetting field is RENEW_WITH_SPECIFIC_TERM.
         */
        public List<ZuoraRenewalTerm> renewalTerms;
    }

    public class ZuoraInitialTerm {
        /**
         * Duration of the first term in months, years, days, or weeks, depending on the value of the periodType field.
         * Only applicable if the value of the termType field is TERMED.
         */
        public Integer period;
        /**
         * Enum:"Month" "Year" "Day" "Week".
         * Unit of time that the first term is measured in. Only applicable if the value of the termType field is TERMED.
         */
        public String periodType;
        /**
         * Start date of the first term, in YYYY-MM-DD format.
         */
        public String startDate;
        /**
         * Enum:"TERMED" "EVERGREEN".
         * Type of the first term. If the value of this field is TERMED, the first term has a predefined duration based on the value of the period field.
         * If the value of this field is EVERGREEN, the first term does not have a predefined duration.
         */
        public String termType;
    }

    public class ZuoraRenewalTerm {
        /**
         * Duration of the renewal term in months, years, days, or weeks, depending on the value of the periodType field.
         */
        public Integer period;
        /**
         * Enum:"Month" "Year" "Day" "Week".
         * Unit of time that the renewal term is measured in.
         */
        public String periodType;
    }

    public class ZuoraOwnerTransfer {
        /**
         * The account number of the account that the subscription is being transferred to.
         */
        public String destinationAccountNumber;
        /**
         * The account number of the invoice owner account that the subscription is being transferred to.
         */
        public String destinationInvoiceAccountNumber;
    }

    public class ZuoraRemoveProduct {
        /**
         * Internal identifier of the rate plan to remove.
         */
        public String ratePlanId;
        /**
         * A unique string to represent the rate plan charge in the order.
         * The unique token is used to perform multiple actions against a newly added rate plan.
         */
        public String uniqueToken;
    }

    public class ZuoraResumeAction {
        /**
         * Specifies whether to extend the subscription term by the length of time the suspension is in effect.
         */
        public boolean extendsTerm;
        /**
         * This field is applicable only when the resumePolicy field is set to FixedPeriodsFromToday or FixedPeriodsFromSuspendDate.
         * It must be used together with the resumePeriodsType field.
         */
        public Integer resumePeriods;
        /**
         * Enum:"Day" "Week" "Month" "Year"
         * This field is applicable only when the resumePolicy field is set to FixedPeriodsFromToday or FixedPeriodsFromSuspendDate.
         * It must be used together with the resumePeriods field.
         */
        public String resumePeriodsType;
        /**
         * Enum:"Today" "FixedPeriodsFromSuspendDate" "FixedPeriodsFromToday" "SpecificDate" "SuspendDate".
         * Resume methods. Specify a way to resume a subscription. See Resume Date for more information.
         */
        public String resumePolicy;
        /**
         * This field is applicable only when the resumePolicy field is set to SpecificDate.
         */
        public String resumeSpecificDate;
    }

    public class ZuoraSuspendAction {
        /**
         * This field is applicable only when the suspendPolicy field is set to FixedPeriodsFromToday.
         * It must be used together with the suspendPeriodsType field.
         */
        public Integer suspendPeriods;
        /**
         * Enum:"Day" "Week" "Month" "Year".
         * This field is applicable only when the suspendPolicy field is set to FixedPeriodsFromToday. It must be used together with the suspendPeriods field.
         */
        public String suspendPeriodsType;
        /**
         * Enum:"Today" "EndOfLastInvoicePeriod" "FixedPeriodsFromToday" "SpecificDate".
         * Suspend methods. Specify a way to suspend a subscription. See Suspend Date for more information
         */
        public String suspendPolicy;
        /**
         * This field is applicable only when the suspendPolicy field is set to SpecificDate.
         */
        public String suspendSpecificDate;
    }

    public class ZuoraWorkflow {
        /**
         * Distributor Id
         */
        public string Distributor;
        /**
         * Receiver Email
         */
        public string ReceipientEmail;
        public boolean ManageHomeCurrency;
    }

    public class ZuoraTermsAndConditions {
        public boolean autoRenew;
        /**
         * The length of the period for the current subscription term.
         */
        public ZuoraLastTerm lastTerm;
        /**
         * Enum:"RENEW_WITH_SPECIFIC_TERM" "RENEW_TO_EVERGREEN"
         */
        public String renewalSetting;
        /**
         * The renewal term in months, years, days, or weeks, depending on the value of the periodType
         */
        public ZuoraRenewalTerm RenewalTerm;
    }

    public class ZuoraLastTerm {
        /**
         * Specify only when the termType is 'TERMED'.
         */
        public Integer period;
        /**
         * Enum:"Month" "Year" "Day" "Week".
         * Specify only when the termType is 'TERMED'.
         */
        public String periodType;
        /**
         * The start date of the current term. You can change the term start date of a renewed subscription through a T&Cs order action.
         * However, when changing it to an earlier date, this date must not be earlier than the term start date of the current term before this T&Cs.
         */
        public String startDate;
        /**
         * Enum:"TERMED" "EVERGREEN"
         */
        public String termType;
    }

    public class ZuoraTriggerDate {
        /**
         * Enum:"ContractEffective" "ServiceActivation" "CustomerAcceptance".
         * Name of the trigger date of the order action.
         */
        public String name;
        /**
         * Trigger date in YYYY-MM-DD format.
         */
        public String triggerDate;
    }

    public class ZuoraUpdateProduct {
        /**
         * The list of charges to update
         */
        public List<ZuoraChargeUpdate> chargeUpdates;
        /**
         * The id of the rate plan to be updated.
         * It can be the latest version or any history version id.
         */
        public String ratePlanId;
        /**
         * The date when the Update Product order action takes effect.
         * This field is only applicable if there is already a future-dated Update Product order action on the subscription.
         * The format of the date is yyyy-mm-dd.
         */
        public String specificUpdateDate;
    }

    public class ZuoraChargeUpdate {
        /**
         * The billing Period Alignment
         */
        public ZuoraBilling billing;
        /**
         * Read only. Identifies the charge to be updated.
         */
        public String chargeNumber;
        /**
         * The description of the charge updates
         */
        public String description;
        /**
         * Specifies when a charge becomes active.
         */
        public ZuoraStartDate effectiveDate;
        /**
         * Specifies the pricing model for the charge.
         */
        public ZuoraPricing pricing;
        /**
         * A unique string to represent the rate plan charge in the order.
         * The unique token is used to perform multiple actions against a newly added rate plan.
         */
        public String uniqueToken;
    }

    public class ZuoraRamp {
        /**
         * Container for the rate plan charges that are considered as part of the ramp deal.
         */
        public List<ZuoarRampCharge> charges;
        /**
         * Whether to remove the ramp definition from the new subscription.
         * If you want to remove the ramp definition, this field is the only required field for the ramp object.
         */
        public Boolean delete_toReplace;
        /**
         * The short description of the ramp.
         */
        public String description;
        /**
         * The short description of the ramp.
         */
        public List<ZuoraInterval> intervals;
        /**
         * The name of the ramp.
         */
        public String name;
    }

    public class ZuoarRampCharge {
        /**
         * The number of the rate plan charge.
         */
        public String chargeNumber;
        /**
         * Unique identifier for the charge. This identifier enables you to refer to the charge before the charge has an internal identifier in Zuora.
         */
        public String uniqueToken;
    }

    public class ZuoraInterval {
        /**
         * Unique identifier for the charge. This identifier enables you to refer to the charge before the charge has an internal identifier in Zuora.
         */
        public String description;
        /**
         * The end date of the interval.
         */
        public String endDate;
        /**
         * The name of the interval.
         */
        public String name;
        /**
         * The start date of the interval.
         */
        public String startDate;
    }
    public class ZuoraUsage {
        /*
         * The ID of the account associated with the usage data. This field is only required if no value is specified for the AccountNumber field
         * */
        public string AccountId;
        /*
         * The number of the account associated with the usage data. This field is only required if no value is specified for the AccountId field
         * */
        public string AccountNumber;
        /*
         * The OrginalId of the rate plan charge related to the usage record
         * */
        public string ChargeId;
        /*
         * A unique number for the rate plan charge related to the usage record. For example, C-00000007.
         * */
        public string ChargeNumber;
        /*
         * A description of the usage record.
         * */
        public string Description;
        /*
         * The end date and time of a range of time when usage is tracked. Use this field for reporting; this field doesn't affect usage calculation
         * */
        public string EndDateTime;
        /*
         * Indicates the number of units used. Character limit: 16 Values: a valid decimal amount equal to or greater than 0
         * */
        public double Quantity;
        /*
         * The start date and time of a range of time when usage is tracked. Zuora uses this field value to determine the usage date.
         * Unlike the EndDateTime, the StartDateTime field does affect usage calculation.
         * */
        public string StartDateTime;
        /*
         * The date when usage was submitted. Character limit: 29 Values: automatically generated
         * */
        public string SubmissionDateTime;
        /*
         * The ID of the subscription that contains the fees related to the usage data.
         * The ID of a subscription might change when you create amendments to the subscription.
         * It is good practice to use the unique subscription number that you can specify in the SubscriptionNumber field
         * */
        public string SubscriptionId;
        /*
         * The unique identifier number of the subscription that contains the fees related to the usage data.
         * It is good practice to use this field when creating usage records.
         * */
        public string SubscriptionNumber;
        /*
         * Specifies the units to measure usage. Units of measure are configured in the web-based UI.
         * Your values depend on your configuration in Billing Settings. Character limit: Values: a valid unit of measure
         * */
        public string UOM;
        public string SubscriptionName_Reserved;
        public string InvoiceNumber_Reserved;
        public string PaymentNumber_Reserved;
        public string OrderNumber_Reserved;

    }
    public class ZuoraNullFields {
        /**
         * list of null fields
         */
        public list<ZuoraNullFieldsObjects> objects;
        /**
         * type = object Name
         */
        public string type;
    }
    public class ZuoraNullFieldsObjects {
        /**
         * id of object
         */
        public string Id;
        /**
         * list of fields set to null
         */
        public list<string> fieldsToNull;

    }
}