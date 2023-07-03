trigger QuoteTrigger on Quote (after insert,before insert, before update,after delete) {
	switch on Trigger.operationType {
		when BEFORE_INSERT {
			if(PAD.canTrigger('AP01_Quotes')) {
				AP01_Quotes.fillQuoteContactInfo(trigger.new);
			}
			if(PAD.canTrigger('AP02_Quote')) {
				AP02_Quote.addDateOfStatusUpdate(trigger.new, null);
			}
		}
		when AFTER_INSERT {
			// if(PAD.canTrigger('AP01_Quotes')) {
				//   AP01_Quotes.syncQuoteHandler(trigger.new);
			// }
		}
		when BEFORE_UPDATE {
			if(PAD.canTrigger('AP02_Quote')) {
				AP02_Quote.addDateOfStatusUpdate(trigger.new, trigger.oldMap);
			}
		}
		when AFTER_DELETE{
			if(PAD.canTrigger('AP02_Quote')) {
				AP02_Quote.liberateBoxOnQuoteDeleted(Trigger.oldMap);
			}
			if(PAD.canTrigger('BundleCSubscription')) {
				BundleCSubscription.libarateEquipsOnQuoteDelete(Trigger.old);
			}
		}
	}

}