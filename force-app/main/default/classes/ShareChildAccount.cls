/**
 * give the partner commuity User acces to all child account related to his account
 **/
public with sharing class ShareChildAccount {

    //share account based on parentId
    public static void shareAccount(Map<Id, Account> mapOfNewAccount, Map<Id, Account> mapOfOldAccount){
        list<account>  listAccountToShare = new list<account>();
        set<Id> setParentId = new set<Id>();
        map<Id, Id> mapAccountIdUserId = new map<Id, Id>();
        system.debug('mapOfOldAccount ' + mapOfOldAccount);
        //in case of new account
        if(mapOfOldAccount == null) {
            for(account acc : mapOfNewAccount.values()) {
                // check if account is partner and have parent Account
                if(acc.ParentId != null && acc.RecordType.DeveloperName == System.label.Distributor_RecordType) {
                    listAccountToShare.add(acc);
                    setParentId.add(acc.ParentId);
                }
            }
        }
        //in case of update account
        if(mapOfOldAccount != null) {
            for(account acc : mapOfNewAccount.values()) {

                system.debug(acc.RecordType.DeveloperName);
                // check if parent Id is changes
                if(acc.ParentId != mapOfOldAccount.get(acc.Id).ParentId && acc.ParentId != null) {//&&
                    // acc.RecordType.DeveloperName == System.label.Distributor_RecordType) {
                    listAccountToShare.add(acc);
                    setParentId.add(acc.ParentId);
                }
            }
        }

        if(setParentId.size() > 0 && setParentId != null) {
            //get list of partner User
            list<User> listUser = [SELECT id, Name, AccountId
                                   FROM User
                                   WHERE AccountId IN: setParentId];
            if(listUser.size() > 0 && listUser != null) {
                for(user usr : listUser) {
                    mapAccountIdUserId.put(usr.AccountId, usr.Id);
                }
            }
        }
        // Share accounts with the new ParentsAccount
        List<AccountShare>  recToShareList = new List<AccountShare>();
        if(mapAccountIdUserId.size() > 0 && mapAccountIdUserId != null) {
            for(Account acct : listAccountToShare) {

                AccountShare recToShare = new AccountShare ();
                recToShare.AccountAccessLevel = 'Edit';
                recToShare.OpportunityAccessLevel = 'Read';
                recToshare.AccountId = acct.Id;
                recToShare.UserOrGroupId = mapAccountIdUserId.get(acct.ParentId);//acct.ParentId;
                recToShareList.add(recToShare);

            }

            //insert sharing account
            if(!recToShareList.isEmpty()) {
                insert recToShareList;
            }
        }

    }
}