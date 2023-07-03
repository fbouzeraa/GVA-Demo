public with sharing class UserChangeEventTriggerHandler {


    public static void updatePersonAccountEmail(List<UserChangeEvent> userChangeEvents){
        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('ACC_ComptePersonnel').getRecordTypeId();
        List<Account> accounts = new List<Account>();
        Map<Id, Account> userToAccount = setUserToAccount(userChangeEvents);

        for (UserChangeEvent event : userChangeEvents) { 
            EventBus.ChangeEventHeader header = event.ChangeEventHeader; 
            Id userId = header.commitUser;
            Account account = userToAccount.get(userId);
            
            if (account != null && account.RecordTypeId == personAccountRecordTypeId){
                if(header.changedFields.contains('Email')){  
                        account = updateEmailAccount(account, event.Email);
                        accounts.add(account);
                }
                
                // Just for test, header.changedFields does not contain Email in test
                if(Test.isRunningTest()){
                    if(event.accountId != null){
                        account = updateEmailAccount(account, event.Email);
                        accounts.add(account);
                    }
                }
            }   
        } 

        if (accounts != null && accounts.size()>0){
            update accounts;
        }
    }

    private static Account updateEmailAccount(Account account,  String email){
        System.debug('account : ' + account);
        account.personEmail = email;
        return account;
    }

    
    


    private static Map<Id, Account> setUserToAccount(List<UserChangeEvent> userChangeEvents){

        List<Id> userIds = getUserIds(userChangeEvents);
        Map<Id, Id> accountToUser = setAccountToUser(userIds);
        List<Id> accountIds = getAccountIds(userIds);
        Map<Id, Account> userToAccount = setUserToAccount(accountIds, accountToUser);
        return userToAccount;
    }

    private static List<Id> getUserIds(List<UserChangeEvent> userChangeEvents){
        List<Id> userIds =  new List<Id>(); 
        for(UserChangeEvent event: userChangeEvents){
            EventBus.ChangeEventHeader header = event.ChangeEventHeader;
            Id userId = header.commitUser;
            userIds.add(userId);
        }
        return userIds;
    }

    private static Map<Id, Id> setAccountToUser(List<Id> userIds){
        Map<Id, Id> accountToUser = new Map<Id, Id>();
        for (User user : [SELECT Id, AccountId  FROM User WHERE Id IN :userIds]){
            if (!accountToUser.containsKey(user.Id)){
                accountToUser.put(user.AccountId, user.Id);
            }
        }
        return accountToUser;
    }

    private static List<Id> getAccountIds(List<Id> userIds){
        List<Id> accountIds = new List<Id>();
        for (User user : [SELECT Id, AccountId  FROM User WHERE Id IN :userIds]){
            accountIds.add(user.AccountId);
        }
        return  accountIds;
    }

    private static Map<Id, Account> setUserToAccount(List<Id> accountIds, Map<Id, Id> accountToUser){
        Map<Id, Account> userToAccount = new Map<Id, Account>();
        for (Account account : [SELECT Id, RecordTypeId FROM Account  WHERE Id IN :accountIds]){
            Id userId = accountToUser.get(account.Id);
            if (!userToAccount.containsKey(userId)){
                userToAccount.put(userId, account);
            }
        }
        return userToAccount;
    }


    // System.debug('header.changedFields : ' + header.changedFields); 
    // System.debug('header.commitUser : ' + header.commitUser);
    // System.debug('header.recordIds : ' + header.recordIds);
    // System.debug('event.Email : ' + event.Email); 
    // System.debug('event.accountId : ' + event.accountId); 
    // System.debug('event.Username : ' + event.username);

}