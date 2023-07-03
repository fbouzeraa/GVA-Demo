trigger PocPlateFormEvents on Subsricption_Activation_Event__e (after insert) {

	System.debug('FBO START POC Platform Events::');

	Zuora__Subscription__c sub = new Zuora__Subscription__c();
	for (Subsricption_Activation_Event__e event : Trigger.new) {

		sub.Id                              = event.id_souscription__c;
		sub.Zuora__ServiceActivationDate__c = date.valueOf(event.activation_date__c);
		sub.Date_De_RDV_Dinstallation__c    = date.valueOf(event.pxo_date_rdv__c);
		sub.SUB_Ref_service__c              = event.service_ref__c;
		sub.Etat_De_Linstallation__c        = event.service_status__c;
	}

	/*{
	    "id_souscription__c": "a0S5r000000pNyXEAU",
	    "activation_date__c": "2023-06-10",
	    "pxo_date_rdv__c": "2023-05-29",
	    "service_ref__c": "POC Platform Events Ref Service",
	    "service_status__c": "POC Platform Events etat"
	   }*/

	System.debug('FBO END POC Platform Events:: sub '+sub);

	update sub;

}