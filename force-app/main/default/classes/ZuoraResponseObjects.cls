public class ZuoraResponseObjects {

    public class ZuoraGetAccount {
        public boolean success;
        public ZuoraAccountInfo basicInfo;
        public list<ZuoraPayment> payments;
        public ZuoraBillingAndPayment billingAndPayment;
        public list<ZuoraSub> subscriptions;
        public list<ZuoraInvoices> invoices;
        public list<ZuoraReasons> reasons;

    }

    public class ZuoraBillingAndPayment {
        public integer billCycleDay;
        public string paymentTerm;
        public string defaultPaymentMethodId;
    }

    public class ZuoraSub {
        public String Id;
        public string subscriptionNumber;
    }
    public class ZuoraUpdateAccountResponse {
        public boolean success;
        public list<ZuoraReasons> reasons;
        public String Id;
    }

    public class ZuoraAccountResponse {
        public boolean success;
        public String AccountId;
        public String accountNumber;
        public String billToContactId;
        public String soldToContactId;
        public list<ZuoraReasons> reasons;
    }

    public class ZuoraCreateOrderResponse {
        public boolean success;
        public String processId;
        public string boxNumber;
        public String orderNumber;
        public String accountNumber;
        public list<String> creditMemoIds;
        public list<String> invoiceIds;
        public string article;
        public set<Log__c> zuoraLogs;
        public list<string> subscriptionNumbers;
        public list<string> invoiceNumbers;
        public list<ZuoraSubscriptions> subscriptions;
        public list<ZuoraReasons> reasons;
    }
    public class ZuoraPreviewResponse {
        public boolean success;
        public list<ZuoraReasons> reasons;
        public ZuoraPreviewResult previewResult;
        public double conversionRate;
        public set<Log__c> zuoraLogs;

    }
    public class ZuoraPreviewResult {
        public list<ZuoraPreviewInvoice> invoices;
        public list<ZuoraChargeMetrics> chargeMetrics;
        public list<ZuoraCreditMemos> creditMemos;
    }
    public class ZuoraPreviewInvoice {
        public double amount;
        public double amountWithoutTax;
        public double taxAmount;
        public string targetDate;
        public double contractedMrr;
        public list<ZuoraInvoiceItems> invoiceItems;
    }
    public class ZuoraCreditMemos {
        public double amount;
        public double amountWithoutTax;
        public string targetDate;
        public double taxAmount;
    }

    public class ZuoraChargeMetrics {
        public list<ZuoraCharges> charges;
        public string subscriptionNumber;
    }

    public class ZuoraCharges {
        public string chargeNumber;
        public string originRatePlanId;
        public string productRatePlanId;
        /*public ZuoraTax tax;
           public ZuoraTcb tcb;
           public zuoraTcv tcv;*/
    }

    public class ZuoraSubscriptions {
        public string subscriptionNumber;
        public string status;
        public string boxNumber;
        public boolean success;
        public set<Log__c> zuoraLogs;
        public list<ZuoraReasons> reasons;
    }
    public class ZuoraReasons {
        public string message;
        public string code;
    }
    public class ZuoraBill {
        public list<ZuoraInvoices> invoices;
        public boolean success;
        public list<ZuoraReasons> reasons;
        public list<InvoiceDocuments> documents;
        public set<Log__c> zuoraLogs;
    }
    public class ZuoraInvoices {
        public string AccountId;
        public double Balance;
        public double amount;
        public double amountWithoutTax;
        public blob Body;
        public double CreditBalanceAdjustmentAmount;
        public string id;
        public boolean IncludesUsage;
        public string InvoiceDate;
        public string InvoiceNumber;
        public double PaymentAmount;
        public string PostedDate;
        public string Status;
        public string TargetDate;
        public double TaxAmount;
        public double TaxExemptAmount;
        public string UpdatedDate;
        public string UpdatedById;

    }
    public class InvoiceDocuments {
        public string id;
        public string documentType;
        public string documentNumber;
        public string accountId;
        public double amount;
        public double balance;
    }
    public class ZuoraAccountInfo {
        public string accountNumber;
        public list<string> additionalEmailAddresses;
        public string balance;
        public integer remainedBalance;
        public string batch;
        public string billCycleDay;
        public string currency_toReplace;
        public string id;
        public boolean invoiceDeliveryPrefsEmail;
        public boolean invoiceDeliveryPrefsPrint;
        public string lastInvoiceDate;
        public string lastPaymentAmount;
        public string lastPaymentDate;
        public string name;
        public string status;
        public string tags;

    }
    public class ZuoraPayment {
        public string accountId;
        public double amount;
        public double appliedAmount;
        public string authTransactionId;
        public boolean bankIdentificationNumber;
        public string cancelledOn;
        public string creditBalanceAmount;
        public string currency_toReplace;
        public string effectiveDate;
        public string id;
        public string number_toReplace;
        public string status;
        public boolean success;
        public string type;
        public double unappliedAmount;
        public string paymentNumber;
        public string DistributorOriginalPaymentSource_Reserved;
        public list<ZuoraReasons> reasons;
        public list<ZuoraPaymentInvoice> paidInvoices;
        public set<Log__c> zuoraLogs;
        public retryPayment paymentParam;
    }
    public class retryPayment {
        public string zuoraAccountId;
        public integer nbPeriodes;
        public double currentAmount;
        public string transactionNumber;
        public string operator;
        public string orderNumber;
        public string invoiceId;
        public string accountCurrency;
        public string paymentMode;
        public string CDFPayment;
        public string dollarPayment;
        public string currencyRate;
        public string dollarRefund;
        public string CDFRefund;
        public boolean fromDistributor;
        public string AccountId;
    }
    public class ZuoraPaymentInvoice {
        public string invoiceId;
        public string invoiceNumber;
        public double appliedPaymentAmount;
    }
    public class ZuoraInvoiceItems {
        public string ratePlanName;
        public string bandwidth;
        public string appliedToChargeNumber;
        public double amountWithoutTax;
        public string chargeDescription;
        public string chargeName;
        public string chargeNumber;
        public string processingType;
        public string productName;
        public string productRatePlanChargeId;
        public string serviceEndDate;
        public string serviceStartDate;
        public string subscriptionNumber;
        public double taxAmount;
    }

    public class ZuoraRefund {
        public string accountId;
        public double amount;
        public string cancelledOn;
        public string comment;
        public string createdById;
        public string createdDate;
        public string creditMemoId;
        public string gatewayId;
        public string gatewayResponse;
        public string gatewayResponseCode;
        public string gatewayState;
        public string id;
        public string markedForSubmissionOn;
        public string methodType;
        public string number_toReplace;
        public string paymentId;
        public string paymentMethodId;
        public string paymentMethodSnapshotId;
        public string reasonCode;
        public string referenceId;
        public string refundDate;
        public string refundTransactionTime;
        public string secondRefundReferenceId;
        public string settledOn;
        public string softDescriptor;
        public string status;
        public boolean success;
        public string type;
        public list<ZuoraReasons> reasons;
    }

    public class ZuoraTriggerDate {
        public boolean success;
        public string orderNumber;
        public string accountNumber;
        public string status;
        public list<ZuoraSubscriptions> subscriptions;
        public list<ZuoraReasons> reasons;
    }
    public class ZuoraNullFields {
        public boolean Success;
        public string Id;
        public list<ZuoraWorkflowErrors> errors;
    }

    public class ZuoraPreviewSubscription {
        public string accountId;
        public string accountName;
        public string accountNumber;
        public string autoRenew;
        public date contractEffectiveDate;
        public Double contractedMrr;
        public integer currentTerm;
        public string currentTermPeriodType;
        public date customerAcceptanceDate;
        public string id;
        public integer initialTerm;
        public string initialTermPeriodType;
        public string invoiceOwnerAccountId;
        public string invoiceOwnerAccountName;
        public string invoiceOwnerAccountNumber;
        public string invoiceSeparately;
        public string notes;
        public list<ZuoraRatePlans> ratePlans;
        public string renewalSetting;
        public integer renewalTerm;
        public string renewalTermPeriodType;
        public date serviceActivationDate;
        public string status;
        public date subscriptionEndDate;
        public string subscriptionNumber;
        public date subscriptionStartDate;
        public boolean success;
        public string type;
        public date termEndDate;
        public string termType;
        public Double totalContractedValue;
    }
    public class ZuoraProductRatePlan {
        public string id;
        public string name;
        public string status;
        public date effectiveEndDate;
        public date effectiveStartDate;
        public string Category_Reserved;
        public list<ZuoraproductRatePlanCharge> productRatePlanCharges;
    }
    public class ZuoraproductRatePlanCharge {
        public string id;
    }
    public class ZuoraPRPResponse {
        public list<ZuoraProductRatePlan> productRatePlans;
        public boolean success;
    }
    public class ZuoraRatePlans {
        public string id;
        public string lastChangeType;
        public string productId;
        public string productName;
        public string productRatePlanId;
        public string productSku;
        public string ratePlanName;
        public date effectiveEndDate;
        public date effectiveStartDate;
        public string category_Reserved;
        public list<ZuoraRatePlanCharges> ratePlanCharges;
    }

    public class ZuoraRatePlanCharges {
        public string applyDiscountTo;
        public string billingDay;
        public string billingPeriod;
        public string billingPeriodAlignment;
        public string billingTiming;
        public date chargedThroughDate;
        public date effectiveEndDate;
        public date effectiveStartDate;
        public string endDateCondition;
        public date processedThroughDate;
        public string id;

    }

    public class ZuoraWorkflowResponse {
        public integer id;
        public string name;
        public integer originalWorkflowId;
        public string status;
        public string createdAt;
        public string updatedAt;
        public string message;
        public list<ZuoraWorkflowErrors> errors;

    }
    public class ZuoraWorkflowErrors {
        public string code;
        public string status;
        public string title;
        public string message;
    }
    public class OauthenticationResponse {
        public string access_token;
        public string token_type;
        public string expires_in;
        public string scope;
        public string jti;

    }
    public class ZuoraLog {

        public String LG_Body_toReplace;
        public string LG_Account_toReplace;
        public String LG_Subscription_toReplace;
        public String LG_Method_URL_toReplace;
        public String LG_Subscription_Number_toReplace;
        public string LG_Response_toReplace;
        public String LG_Interface_toReplace;
        public String LG_Error_Message_toReplace;
        public String LG_Method_Type_toReplace;
        public Attributes attributes;

    }
    public class Attributes {
        public String type;
    }

    public class handleError {
        public string message;
        public set<Log__c> zuoraLog;
    }
    public class ZuoraUsage {
        public boolean Success;
        public string id;
        public list<ZuoraReasons> reasons;
    }
}