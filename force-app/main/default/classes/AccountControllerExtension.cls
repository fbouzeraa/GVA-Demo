public with sharing class AccountControllerExtension {
   
    public Account account { get; set; }

    public AccountControllerExtension(ApexPages.StandardController controller) {
        account =  (Account) controller.getRecord();
    }

    public PageReference sendWelcomeSms(){
        account = [SELECT PersonContactId FROM Account WHERE Id = :account.Id];
        List<User> users = [SELECT Id, FirstName, LastName, MobilePhone, phone FROM User WHERE ContactId = :account.PersonContactId];
        System.debug('users  : ' + users);
        if(users != null && users.size() == 1){
            UserTriggerHandler.sendWelcomeSmsToClientPortalUsers(users);
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'CONFIRM: Portal client welcome SMS was send to : ' + users[0].FirstName + ' ' + users[0].LastName + ' ' + users[0].MobilePhone);
            ApexPages.addMessage(myMsg);
            return  null;
        }
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,'Error: No user was associate with this person account');
        ApexPages.addMessage(myMsg);
        return null;
    }
}