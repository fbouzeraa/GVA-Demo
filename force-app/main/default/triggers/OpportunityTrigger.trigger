trigger OpportunityTrigger on Opportunity (before insert,after insert) {

	switch on Trigger.operationType {
		when BEFORE_INSERT {
			if(PAD.canTrigger('AP01_Opportunity')) {
				AP01_Opportunity.addPriceBookToOpportunity(trigger.new);
			}
		}
	}
}