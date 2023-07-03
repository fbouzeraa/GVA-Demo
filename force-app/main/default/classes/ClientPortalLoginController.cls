/**
 * An apex page controller that exposes the site login functionality
 */
global without sharing class ClientPortalLoginController {
    global String identifier {get; set;}
    global String password {get; set;}
    public String orgId {get; set;}
    public String siteURL  {get; set;}
    public String startURL {get; set;}
    public List<AuthProvider> authProviders {get;set;}
    global Boolean isIdentifierCode {get;set;}
    private String identifierCode {get; set;}
    
    global ClientPortalLoginController () {
        isIdentifierCode = false;
        orgId = UserInfo.getOrganizationId();
        siteURL  = Site.getBaseUrl();
        startURL = System.currentPageReference().getParameters().get('startURL');  // /customerportal/apex/CommunitiesLanding
        if (startURL == null) startURL = '/';
        authProviders = [SELECT Id,DeveloperName,FriendlyName,ProviderType FROM AuthProvider];
    }

    global PageReference login() {
        if (identifier != null && LoginUtils.isValidEmail(identifier)) {
            // Search for user by email 
            List<User> users = [SELECT Id, Username FROM User WHERE Email = :identifier AND IsActive = TRUE];
            if (!users.isEmpty() && users.size() == 1) {
                // User must have verified email before using this verification method. We cannot send messages to unverified emails. 
                // You can check if the user has email verified bit on and add the password verification method as fallback.
                List<TwoFactorMethodsInfo> verifiedInfo = [SELECT HasUserVerifiedEmailAddress FROM TwoFactorMethodsInfo WHERE UserId = :users[0].Id];
                if (!verifiedInfo.isEmpty() && verifiedInfo[0].HasUserVerifiedEmailAddress == true) {
                    // Use email verification method if the user's email is verified.
                    return Site.login(users[0].Username, password, startUrl);
                } else {
                    // Use password verification method as fallback if the user's email is unverified.
                    return Site.login(users[0].Username, password, startUrl);
                }
            } else {
            //  throw new Auth.LoginDiscoveryException('No unique user found. User count=' + users.size());
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No unique user found. User count=' + users.size()));
                return ApexPages.currentPage();
            }
        }
        
        if (identifier != null) {
            String formattedSms = LoginUtils.getFormattedSms(identifier);
            if (formattedSms != null) {
                // Search for user by SMS 
                List<User> users = [SELECT Id, Username, FirstName, LastName, MobilePhone, ProfileId   FROM User WHERE MobilePhone = :formattedSms AND IsActive = TRUE];
            
                if (!users.isEmpty() && users.size() == 1) {
                    // User must have verified SMS before using this verification method. We cannot send messages to unverified mobile numbers. 
                    // You can check if the user has mobile verified bit on or add the password verification method as fallback.
                    //List<TwoFactorMethodsInfo> verifiedInfo = [SELECT HasUserVerifiedMobileNumber FROM TwoFactorMethodsInfo WHERE UserId = :users[0].Id];
                        System.debug('User '+users[0]);
                        //System.debug('verified info '+verifiedInfo[0]);
                        //if (!verifiedInfo.isEmpty() && verifiedInfo[0].HasUserVerifiedMobileNumber == true) {
                        // Use SMS verification method if the user's mobile number is verified.
						if (!users.isEmpty() && users.size() == 1) {

                        	System.debug('Verified');
                        	return Site.login(users[0].Username, password, startUrl);
                    	} else {
                        System.debug(' Not Verified');
                        List<LoginHistory> userLoginHistory = [SELECT UserId, LoginTime FROM LoginHistory WHERE UserId = :users[0].Id];
                        if (userLoginHistory.size() == 0){
                            UserTriggerHandler.sendNewPasswordBySmsToUser(users[0].Id);
                        }

                        return Site.login(users[0].Username, password, startUrl);
                    }
                } else {
                //  throw new Auth.LoginDiscoveryException('No unique user found. User count=' + users.size());
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'No unique user found. User count=' + users.size()));
                    return ApexPages.currentPage();
                }
            }
        }
        if (identifier != null) {
            // You can customize the code to find user via other attributes, such as SSN or Federation ID
        }
    //  throw new Auth.LoginDiscoveryException('Invalid Identifier');
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid Identifier'));
        return ApexPages.currentPage();
        //return Site.login(identifier,password, startUrl);
    }

    global String getEncodedSiteUrl(){
        return EncodingUtil.urlEncode(siteURL, 'UTF-8');
    }

    global String getEncodedStartUrl(){
        return EncodingUtil.urlEncode(startURL, 'UTF-8');
    }



}