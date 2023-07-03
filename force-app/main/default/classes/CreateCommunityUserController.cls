public with sharing class CreateCommunityUserController {

    public Account account { get; set; }
    public Boolean isShowActivateCustomerUserButton { get; set; }

    public CreateCommunityUserController(ApexPages.StandardController controller) {
        account =  (Account) controller.getRecord();
        isShowActivateCustomerUserButton = false;
    }

    public PageReference createCommunityUser(){
        System.debug('account : ' + account);
       // System.debug('account.PersonContactId : ' + account.PersonContactId);
        account = [SELECT id, PersonEmail, Suffix, FirstName, PersonContactId, LastName, MiddleName, Phone, BillingStreet,
                BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingCountryCode,
                CurrencyIsoCode, ACC_Indicatif__c, PersonMobilePhone, ACC_LatLong__Latitude__s,
                ACC_LatLong__Longitude__s
                FROM Account
                WHERE Id = : account.Id  //    RecordTypeId = :personAccountId
                LIMIT 1];
        
       List<User> users = [SELECT Id, IsActive FROM User WHERE ContactId = :account.PersonContactId];
       Boolean isUserExist = (users != null && users.size() == 1);

       if(!isUserExist){
           System.debug('In !isUserExist');
            User user = CreateUserHandler.createACommunityUser(account);
            if(user != null){
                insert user;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'CONFIRM: Customer portal user was successfully created.');
                ApexPages.addMessage(myMsg);
                return null;
            }
           
       }

       if(isUserExist){
            System.debug('In  isUserExist');
            User user = users[0];
            if(user.IsActive == false){
                System.debug('In  isUserExist user.IsActive == false');
                user.IsActive = true;
                update user;
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'CONFIRM: Customer portal user successfully activate.');
                ApexPages.addMessage(myMsg);
                return null;
            }

            if(user.IsActive == true){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Customer portal user is already active.');
                ApexPages.addMessage(myMsg);
                return null;
            }
            
       }
       
       ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Unknow error.');
       ApexPages.addMessage(myMsg);
       return null;

    }

    public PageReference deactivateCommunityUser(){
        account = [SELECT id, PersonContactId
                    FROM Account
                    WHERE Id = : account.Id  //    RecordTypeId = :personAccountId
                    LIMIT 1];
        
       List<User> users = [SELECT Id, IsActive FROM User WHERE ContactId = :account.PersonContactId];

       Boolean isUserExist = (users != null && users.size() == 1);

       if(isUserExist){
            System.debug('In  isUserExist');
            User user = users[0];
            if(user.IsActive == true){
                System.debug('In  isUserExist user.IsActive == false');
                user.IsActive = false;
                update user;

                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'CONFIRM: Customer portal user deactivate.');
                ApexPages.addMessage(myMsg);
                return null;
            }

            if(user.IsActive == false){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Customer portal user already deactivate.');
                ApexPages.addMessage(myMsg);
                return null;
            }
        }

        if(!isUserExist){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Customer portal user does not exist.');
            ApexPages.addMessage(myMsg);
            return null;
        }

        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Unknow error.');
        ApexPages.addMessage(myMsg);
        return null;
    }

}