global without sharing class ClientPortalForgotPasswordController {
    global String identifier {get; set;}
    global Boolean isForgotPasswordSucess {get; set;}

    public ClientPortalForgotPasswordController() {
        isForgotPasswordSucess = false;

    }

    public Pagereference forgotPassword() {
        
        if (identifier != null && LoginUtils.isValidEmail(identifier)) {
            // Search for user by email 
            List<User> users = [SELECT Id FROM User WHERE Email = :identifier AND IsActive = TRUE];
            if (!users.isEmpty() && users.size() == 1) {

                System.resetPassword(users[0].Id, true);
                isForgotPasswordSucess = true;
              //  ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'reset password succesfull=' +  isForgotPasswordSucess));
                return ApexPages.currentPage();
            } else {
            //	throw new Auth.LoginDiscoveryException('No unique user found. User count=' + users.size());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No unique user found. User count=' +  users.size()));
                return ApexPages.currentPage();
                
            }
        }
        
        if (identifier != null) {
            String formattedSms = LoginUtils.getFormattedSms(identifier);
            System.debug('formattedSms' + formattedSms);
            if (formattedSms != null) {
                // Search for user by SMS 
                List<User> users = [SELECT Id   FROM User WHERE MobilePhone = :identifier AND IsActive = TRUE];
                System.debug('users : ' + users);
                if (!users.isEmpty() && users.size() == 1) {
                    UserTriggerHandler.sendNewPasswordBySmsToUser(users[0].Id);
                    isForgotPasswordSucess = true;
                    return ApexPages.currentPage();
                } else {
                //	throw new Auth.LoginDiscoveryException('No unique user found. User count=' + users.size());
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No unique user found. User count=' + users.size()));
                    return ApexPages.currentPage();
                }
            }
        }
    
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid Identifier'));
        return ApexPages.currentPage();

    }
   
}