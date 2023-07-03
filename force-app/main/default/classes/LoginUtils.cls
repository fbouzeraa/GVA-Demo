public with sharing class LoginUtils {
    
    
    public static boolean isValidEmail(String identifier) {
		String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,6}$';
		// source: http://www.regular-expressions.info/email.html 
		Pattern EmailPattern = Pattern.compile(emailRegex);
		Matcher EmailMatcher = EmailPattern.matcher(identifier);
		if (EmailMatcher.matches()) { return true; }
		else { return false; }
	}

	public static String getFormattedSms(String identifier) {
		// Accept SMS input formats with 1 or 2 digits country code, 3 digits area code and 7 digits number
		// You can customize the SMS regex to allow different formats
		if(identifier.containsNone(' ')){
			identifier = addSpaceAfterCountryCallingCode(identifier);
		}
		
		String smsRegex = '^(\\+?\\d{1,3}?[\\s-])?(\\(?\\d{1,3}\\)?[\\s-]?\\d{3}[\\s-]?\\d{4})$';
		Pattern smsPattern = Pattern.compile(smsRegex);
		Matcher smsMatcher = SmsPattern.matcher(identifier);
		if (smsMatcher.matches()) {
			try {
				// Format user input into the verified SMS format '+xx xxxxxxxxxx' before DB lookup
				// Append US country code +1 by default if no country code is provided
				String countryCode = smsMatcher.group(1) == null ? '+1' : smsMatcher.group(1);
				return System.UserManagement.formatPhoneNumber(countryCode, smsMatcher.group(2));
			} catch(System.InvalidParameterValueException e) {
				return null;
			}
		} else { return null; }
	}


    private static String addSpaceAfterCountryCallingCode(String identifier){
        if(identifier.contains(System.label.COUNTRY_CALLING_CODE_UGANDA) 
            || identifier.contains(System.label.COUNTRY_CALLING_CODE_TOGO) 
            || identifier.contains(System.label.COUNTRY_CALLING_CODE_RWANDA) 
            || identifier.contains(System.label.COUNTRY_CALLING_CODE_RDC) 
            || identifier.contains(System.label.COUNTRY_CALLING_CODE_GABON)
            || identifier.contains(System.label.COUNTRY_CALLING_CODE_COTE_IVOIRE) 
            || identifier.contains(System.label.COUNTRY_CALLING_CODE_CONGO) 
            || identifier.contains(System.label.COUNTRY_CALLING_CODE_BURKINA_FASO)){
                identifier = identifier.substring(0, 4) + ' ' +  identifier.substring(4);
        }
        if(identifier.contains(System.label.COUNTRY_CALLING_CODE_FRANCE)){
            identifier = identifier.substring(0, 3) + ' ' +  identifier.substring(3);
        }
        return identifier;
    }
}