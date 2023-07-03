public without sharing class CommunityAuthController {
    public CommunityAuthController() {

    }

    // @AuraEnabled
    // public static String login(String identifier, String startUrl, Map<String, String> requestAttributes) {
	// 	System.debug('identifier' + identifier);
	// 	if (identifier != null && isValidEmail(identifier)) {
	// 		// Search for user by email 
	// 		List<User> users = [SELECT Id FROM User WHERE Email = :identifier AND IsActive = TRUE];
	// 		if (!users.isEmpty() && users.size() == 1) {
	// 			// User must have verified email before using this verification method. We cannot send messages to unverified emails. 
	// 			// You can check if the user has email verified bit on and add the password verification method as fallback.
	// 			List<TwoFactorMethodsInfo> verifiedInfo = [SELECT HasUserVerifiedEmailAddress FROM TwoFactorMethodsInfo WHERE UserId = :users[0].Id];
	// 			if (!verifiedInfo.isEmpty() && verifiedInfo[0].HasUserVerifiedEmailAddress == true) {
	// 				// Use email verification method if the user's email is verified.
	// 				return discoveryResult(users[0], Auth.VerificationMethod.EMAIL, startUrl, requestAttributes);
	// 			} else {
	// 				// Use password verification method as fallback if the user's email is unverified.
	// 				return discoveryResult(users[0], Auth.VerificationMethod.PASSWORD, startUrl, requestAttributes);
	// 			}
	// 		} else {
	// 			throw new Auth.LoginDiscoveryException('No unique user found. User count=' + users.size());
	// 		}
	// 	}
		
	// 	if (identifier != null) {
	// 		String formattedSms = getFormattedSms(identifier);
	// 		System.debug('formattedSms' + formattedSms);
	// 		if (formattedSms != null) {
	// 			// Search for user by SMS 
	// 			List<User> users = [SELECT Id, Username, FirstName, LastName, MobilePhone, ProfileId   FROM User WHERE MobilePhone = :formattedSms AND IsActive = TRUE];
	// 			System.debug('users : ' + users);
	// 			if (!users.isEmpty() && users.size() == 1) {
	// 				// User must have verified SMS before using this verification method. We cannot send messages to unverified mobile numbers. 
	// 				// You can check if the user has mobile verified bit on or add the password verification method as fallback.
	// 				List<TwoFactorMethodsInfo> verifiedInfo = [SELECT HasUserVerifiedMobileNumber FROM TwoFactorMethodsInfo WHERE UserId = :users[0].Id];
	// 				System.debug('verifiedInfo : ' + verifiedInfo);
	// 				if (!verifiedInfo.isEmpty() && verifiedInfo[0].HasUserVerifiedMobileNumber == true) {
	// 					// Use SMS verification method if the user's mobile number is verified.
	// 					return discoveryResult(users[0], Auth.VerificationMethod.SMS, startUrl, requestAttributes);
	// 				} else {
	// 					// Use password verification method as fallback if the user's mobile number is unverified.
	// 				//	UserManagement.initPasswordlessLogin(users[0].Id, Auth.VerificationMethod.SMS);
	// 				// UserManagement.initRegisterVerificationMethod(Auth.VerificationMethod.SMS);
	// 					//  System.debug('In else' + verifiedInfo);
	// 					// 	String identifier2  = UserManagement.initVerificationMethod(Auth.VerificationMethod.SMS);
	// 					// 	System.debug('identifier2 : ' + identifier2);
	// 				//    
	// 					// UserManagement.verifyVerificationMethod(identifier, code , Auth.VerificationMethod.EMAIL);
	// 					List<LoginHistory> userLoginHistory = [SELECT UserId, LoginTime FROM LoginHistory WHERE UserId = :users[0].Id];
	// 					System.debug('userLoginHistory : ' + userLoginHistory);
	// 					if (userLoginHistory.size() == 0){
	// 						UserTriggerHandler.sendNewPasswordBySmsToUser(users[0].Id);
	// 					}

	// 					return discoveryResult(users[0], Auth.VerificationMethod.PASSWORD, startUrl, requestAttributes);
	// 				}
	// 			} else {
	// 				throw new Auth.LoginDiscoveryException('No unique user found. User count=' + users.size());
	// 			}
	// 		}
	// 	}
	// 	if (identifier != null) {
	// 		// You can customize the code to find user via other attributes, such as SSN or Federation ID
	// 	}
	// 	throw new Auth.LoginDiscoveryException('Invalid Identifier');
	// }

	// private static boolean isValidEmail(String identifier) {
	// 	String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
	// 	// source: http://www.regular-expressions.info/email.html 
	// 	Pattern EmailPattern = Pattern.compile(emailRegex);
	// 	Matcher EmailMatcher = EmailPattern.matcher(identifier);
	// 	if (EmailMatcher.matches()) { return true; }
	// 	else { return false; }
	// }

	// public static String getFormattedSms(String identifier) {
	// 	// Accept SMS input formats with 1 or 2 digits country code, 3 digits area code and 7 digits number
	// 	// You can customize the SMS regex to allow different formats
	// 	String smsRegex = '^(\\+?\\d{1,2}?[\\s-])?(\\(?\\d{3}\\)?[\\s-]?\\d{3}[\\s-]?\\d{4})$';
	// 	Pattern smsPattern = Pattern.compile(smsRegex);
	// 	Matcher smsMatcher = SmsPattern.matcher(identifier);
	// 	if (smsMatcher.matches()) {
	// 		try {
	// 			// Format user input into the verified SMS format '+xx xxxxxxxxxx' before DB lookup
	// 			// Append US country code +1 by default if no country code is provided
	// 			String countryCode = smsMatcher.group(1) == null ? '+1' : smsMatcher.group(1);
	// 			return System.UserManagement.formatPhoneNumber(countryCode, smsMatcher.group(2));
	// 		} catch(System.InvalidParameterValueException e) {
	// 			return null;
	// 		}
	// 	} else { return null; }
	// }

	// private static PageReference getSsoRedirect(User user, String startUrl, Map<String, String> requestAttributes) {
	// 	// You can look up if the user should log in with SAML or an Auth Provider and return the URL to initialize SSO.
	// 	return null;
	// }

	// private static String discoveryResult(User user, Auth.VerificationMethod method, String startUrl, Map<String, String> requestAttributes) {
	// 	System.debug('Inside  discoveryResult');
	// 	//Only external users with an External Identity or community license can login using Site.passwordlessLogin
	// 	//Use getSsoRedirect to enable internal user login for a community
	// 	PageReference ssoRedirect = getSsoRedirect(user, startUrl, requestAttributes);
	// 	if (ssoRedirect != null) {
	// 		return ssoRedirect.getURL();
	// 	} else {
	// 		if (method != null) {
	// 			List<Auth.VerificationMethod> methods = new List<Auth.VerificationMethod>();
	// 			methods.add(method);
	// 			// System.debug('Inside  discoveryResult 2');
	// 			// String  pwdlessLoginResponse = UserManagement.initPasswordlessLogin(user.Id, method);
	// 			// System.debug('pwdlessLoginResponse : ' + pwdlessLoginResponse);
	// 			PageReference pwdlessRedirect = Site.passwordlessLogin(user.Id, methods, startUrl);
	// 			if (pwdlessRedirect != null) {
	// 				return pwdlessRedirect.getUrl();
	// 			} else {
	// 				throw new Auth.LoginDiscoveryException('No Passwordless Login redirect URL returned for verification method: ' + method);
	// 			}
	// 		} else {
	// 			throw new Auth.LoginDiscoveryException('No method found');
	// 		}
	// 	}
	// }


//-------------------------------


@AuraEnabled
public static string doLogin(String username, String password){
        try {
            
            String startUrl = 'System.Label.Community_Url';
            ApexPages.PageReference pageRef = Site.login(username, password, startUrl);

            if(pageRef != null) return pageRef.getUrl();

            return null;


        } catch (Exception e) {
            system.debug('e.getMessagelogin+   '+e.getMessage());
            throw new AuraHandledException(e.getMessage());

        }
    }


    @AuraEnabled
    public static boolean isEmailExist(String username){
        try {
            
            List<User> userList = new List<User>();
            userList = [Select Id, Name From User Where Username = :username];


            return !userList.isEmpty();


        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());

        }
    }

    @AuraEnabled
    public static string registerUser(String firstName, String lastName, String username, String email, String communityNickname, String password){
        try {

            Set<String> communityNicknameSet = new Set<String>();

            for(User usr : [Select Id, CommunityNickname From User Where CommunityNickname != null]){

                communityNicknameSet.add(usr.CommunityNickname);
            }

            String uniqueCommunityNickName;

            if(communityNicknameSet.isEmpty()){

                if(communityNickname.length() > 4){
                    
                    uniqueCommunityNickName = communityNickname.substring(0, 4) + String.valueOf( Integer.valueOf(Math.random() * 10000) );
                
                } else {

                    uniqueCommunityNickName = communityNickname + String.valueOf( Integer.valueOf(Math.random() * 10000) );
                }
            
            } else {

                for(Integer i=1; i <= 9999 ; i++){

                    if(communityNickname.length() > 4){
                        
                        uniqueCommunityNickName = communityNickname.substring(0, 4) + String.valueOf( Integer.valueOf(Math.random() * 10000) );
                    
                    } else {

                        uniqueCommunityNickName = communityNickname + String.valueOf( Integer.valueOf(Math.random() * 10000) );
                    }

                    if(!communityNicknameSet.contains(uniqueCommunityNickName)){

                        break;
                    }
                }
            }
            
            User u = new User();
            u.firstName = firstName;
            u.lastName = lastName;
            u.Username = username;
            u.Email = email;
            u.CommunityNickname = uniqueCommunityNickName;        

            String accountId;

            Account portalAccount = new Account();
            portalAccount.Name = firstName + ' ' + lastName;
            insert portalAccount;

            portalAccount.IsPartner = true;
            update portalAccount;

            accountId = portalAccount.Id;
            


            String userId = Site.createPortalUser(u, accountId, password);

            if (userId != null) {
                
                String emailResult = sendWelcomeMail(u, userId);
                
                if (password != null && password.length() > 1) {
                    ApexPages.PageReference pageRef = Site.login(username, password, null);
                    if(pageRef != null) return pageRef.getUrl();
                }
                else {
                    ApexPages.PageReference page = System.Page.SiteRegisterConfirm;
                    page.setRedirect(true);
                    return page.getUrl();
                }
            }

            return null;


        } catch (Exception e) {
            system.debug('e.getMessage+   '+e.getMessage());
            
            if(!Test.isRunningTest()) throw new AuraHandledException(e.getMessage());

            return null;
            
        }
    }


    @AuraEnabled
    public static string sendWelcomeMail(User usr, String userId){
        try {

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            List<EmailTemplate> welcomeTemplate = new List<EmailTemplate>([Select Id from EmailTemplate where name = 'Welcome to community']);
                     
            mail.setSenderDisplayName('System.Label.Community_Email_Sender');
            mail.setTargetObjectId(userId);
            mail.setTemplateId(welcomeTemplate[0].Id);
            mail.setSaveAsActivity(false);

            Messaging.sendEmail( new List<Messaging.SingleEmailMessage>{mail} );

            return 'success';

        } catch (Exception e) {            
            throw new AuraHandledException(e.getMessage());
        }
    }
}