public with sharing class RenewSubPreviewResponse {
    
    public String bizaoOrderId;

    public List<Log__c> zuoraLogs;
	public Boolean success;
	public PreviewResult previewResult;
	public Double conversionRate;

	public class PreviewResult {
		public List<Invoices> invoices;
	}

	public class Attributes {
		public String type;
		public String url;
	}

	public class InvoiceItems {
		public Double taxAmount;
		public String subscriptionNumber;
		public String serviceStartDate;
		public String serviceEndDate;
		public String ratePlanName;
		public String productRatePlanChargeId;
		public String productName;
		public String processingType;
		public String chargeName;
		public String chargeDescription;
		public Double amountWithoutTax;
	}

	public class Invoices {
		public Double taxAmount;
		public String targetDate;
		public List<InvoiceItems> invoiceItems;
		public Double amountWithoutTax;
		public Double amount;
	}
    


	// public class ZuoraLogs {
	// 	public Attributes attributes;
	// 	public String LG_Body__c;
	// 	public String LG_Account__c;
	// 	public String LG_Subscription__c;
	// 	public String LG_Method_URL__c;
	// 	public String LG_Subscription_Number__c;
	// 	public String LG_Response__c;
	// 	public String LG_Interface__c;
	// 	public Boolean LG_Success__c;
	// 	public Object LG_Error_Message__c;
	// 	public String LG_Method_Type__c;
	// 	public Boolean LG_Retry__c;
	// 	public String Id;
	// }

	
	public static RenewSubPreviewResponse parse(String json) {
		return (RenewSubPreviewResponse) System.JSON.deserialize(json, RenewSubPreviewResponse.class);
	}
}