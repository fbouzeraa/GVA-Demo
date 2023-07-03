trigger KnowledgeTrigger on Knowledge__kav (before insert) {

    if(trigger.isBefore){
        if(trigger.isInsert){
            KnowledgeTriggerHandler.setArticlesCurrency(Trigger.new);

        }
    }

}