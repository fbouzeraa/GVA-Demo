/**
* Test Classe : WS03_SouscriptionAPI_Test
* @author Yara Bourdoukan
* @date 2021-10-13
*/
@RestResource(urlMapping='/v1/souscriptions/*')
global class WS03_SouscriptionAPI {

	/* Methode permettant GVAdmin de faire un appel à Salesforce via API pour demander
	 * la liste des Souscriptions
	 * @return Liste des Souscriptions
	 * */
	@HttpPost
	global static List<Zuora__Subscription__c> doGet() {
		RestRequest req = RestContext.request;
	
        System.debug(RestContext.request.requestBody.toString());
		SuiviObjects.SouscriptionListRequest subscriptionsRequest = (SuiviObjects.SouscriptionListRequest) JSON.deserialize(RestContext.request.requestBody.toString(), SuiviObjects.SouscriptionListRequest.class);
		
		//RestResponse res = RestContext.response;
		List<Zuora__Subscription__c> results = new List<Zuora__Subscription__c>();

		// Check if Object is accessible by calling user.
		if(Schema.sObjectType.Zuora__Subscription__c.isAccessible())
		{
			String query = 'SELECT Id,Zuora__SubscriptionNumber__c,Zuora__Status__c, Zuora__ServiceActivationDate__c,Zuora__Account__r.Name,';
			query += 'Zuora__ContractAcceptanceDate__c, Zuora__ContractEffectiveDate__c, ExpectedRenewalDate__c,Zuora__NextRenewalDate__c, Zuora__CancelledDate__c,CancelReason__c, Zuora__Zuora_Id__c,';
			query +='CompensationDaysAtNextRenewal__c, Type__c, BoxNumber__c, WarrantyEndDate__c, RenewalSequenceNumber__c, SUB_Numero_de_transaction__c';
            query += ' FROM Zuora__Subscription__c';
            query += ' WHERE Zuora__SubscriptionNumber__c != null ';
		
	
            System.debug('query' + query);
			// Add filters for status
			if(subscriptionsRequest.Statut != null && subscriptionsRequest.Statut.size() > 0)
			{
				List<String> status = subscriptionsRequest.Statut;
				query += ' AND Zuora__Status__c IN :status';
			}

			// Add filters for Subscription codes
			if(subscriptionsRequest.CodeSouscription != null && subscriptionsRequest.CodeSouscription.size() > 0)
			{
				List<String> code = subscriptionsRequest.CodeSouscription;
				query += ' AND Zuora__SubscriptionNumber__c IN :code';

			}

            // Add filters for Accounts
			if(subscriptionsRequest.Compte != null && subscriptionsRequest.Compte.size() > 0)
			{
				List<String> accountsId = subscriptionsRequest.Compte;
				query += ' AND Zuora__Account__c IN :accountsId';
                system.debug(query);
			}
			// Add filters for Countries
			if(subscriptionsRequest.Pays != null && subscriptionsRequest.Pays.size() > 0)
			{
				List<String> accountsCountries = subscriptionsRequest.Pays;
				query += ' AND Zuora__Account__r.BillingCountryCode IN :accountsCountries';
                system.debug(query);
			}
			
			

			query += ' ORDER BY CreatedDate DESC ';
			query += ' LIMIT 1000'; //can be up to 50 000
			results = Database.query(query);
		}
		return results;
	}


	
}