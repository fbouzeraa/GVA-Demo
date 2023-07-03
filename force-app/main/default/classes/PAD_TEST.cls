@istest
private class PAD_TEST {
    
    private static testmethod void runpad(){
        PAD.canTrigger('1'); 
        Set<String> devsNot2execSet = new Set<String>();
        devsNot2execSet.add('1');
        PAD.doNotExecuteAfterMe(devsNot2execSet);
        PAD.canTrigger('1'); 
        PAD.doNotExecuteAfterMe(devsNot2execSet);
    }
    
}