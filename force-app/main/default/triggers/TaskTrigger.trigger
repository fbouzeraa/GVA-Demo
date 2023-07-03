trigger TaskTrigger on Task (after insert,before insert) {
	switch on Trigger.operationType {

		when BEFORE_INSERT {
			if(PAD.canTrigger('AP01_Task')) {
				AP01_Task.addBuildingId(trigger.new);
			}
		}
		
		when AFTER_INSERT {
			if(PAD.canTrigger('AP01_Task')) {
				AP01_Task.triggerHandler(trigger.new, trigger.oldMap);
				
			}
		}
	}
}