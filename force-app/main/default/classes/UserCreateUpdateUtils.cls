public with sharing class UserCreateUpdateUtils {
  
    private static final String TOGO_COUNTRY_CODE = System.label.COUNTRY_CODE_TOGO;
    private static final String COTE_IVOIRE_COUNTRY_CODE = System.label.COUNTRY_CODE_COTE_IVOIRE;
    private static final String GABON_COUNTRY_CODE = System.label.COUNTRY_CODE_GANA;
    private static final String CONGO_COUNTRY_CODE = System.label.COUNTRY_CODE_CONGO;
    private static final String BURKINA_FASO_COUNTRY_CODE = System.label.COUNTRY_CODE_BURKINA_FASO;
    private static final String RDC_COUNTRY_CODE = System.label.COUNTRY_CODE_RDC;
    private static final String RWANDA_COUNTRY_CODE = System.label.COUNTRY_CODE_RWANDA;
    private static final String FRANCE_COUNTRY_CODE = System.label.COUNTRY_CODE_FRANCE;

    private static final String AFRICA_LIBREVILLE_TIME_ZONE_SID_KEY = System.label.TIME_ZONE_SID_KEY_AFRICA_LIBREVILLE;
    private static final String AFRICA_BRAZAVILLE_TIME_ZONE_SID_KEY = System.label.TIME_ZONE_SID_KEY_AFRICA_BRAZAVILLE;
    private static final String AFRICA_KINSHASA_TIME_ZONE_SID_KEY = System.label.TIME_ZONE_SID_KEY_AFRICA_KINSHASA;
    private static final String AFRICA_ABIDJAN_TIME_ZONE_SID_KEY = System.label.TIME_ZONE_SID_KEY_AFRICA_ABIDJAN;
    private static final String AFRICA_KIGALI_TIME_ZONE_SID_KEY = System.label.TIME_ZONE_SID_KEY_AFRICA_KIGALI;
    private static final String AFRICA_OUAGADOUGOU_TIME_ZONE_SID_KEY = System.label.TIME_ZONE_SID_KEY_AFRICA_OUAGADOUGOU;
    private static final String AFRICA_LOME_TIME_ZONE_SID_KEY = System.label.TIME_ZONE_SID_KEY_AFRICA_LOME;

    private static final String FRENCH_LANGUAGE_LOCALE_KEY = System.label.LANGUAGE_LOCALE_KEY_FRENCH;
    private static final String ENGLISH_US_LANGUAGE_LOCALE_KEY = System.label.LANGUAGE_LOCALE_KEY_ENGLISH_US;

    private static final String FRENCH_LOCALE_SID_KEY = System.label.LOCALE_SID_KEY_FRENCH;
    private static final String ENGLISH_RWANDA_LOCALE_SID_KEY = System.label.LOCALE_SID_KEY_ENGLISH_RWANDA;

    private static final String EMAIL_DOMAIN_NAME = '@canalbox.com';

    public static String setCommunityNickname(String userMobilePhone){
        String username = userMobilePhone.replace('+', '');
        username = username.replaceAll(' ', '');
        return username;
    }

    public static String setUsername(String userMobilePhone){
        String username = userMobilePhone.replace('+', '');
        username = username.replaceAll(' ', '');

        return username + EMAIL_DOMAIN_NAME;
    }

    public static String setTimeZoneSidKey(String countryCode){
        if(countryCode == GABON_COUNTRY_CODE) {
            return AFRICA_LIBREVILLE_TIME_ZONE_SID_KEY;
        }
        if(countryCode == CONGO_COUNTRY_CODE) {
            return AFRICA_BRAZAVILLE_TIME_ZONE_SID_KEY;
        }
        if(countryCode == RDC_COUNTRY_CODE) {
            return AFRICA_KINSHASA_TIME_ZONE_SID_KEY;
        }
        if(countryCode == COTE_IVOIRE_COUNTRY_CODE) {
            return AFRICA_ABIDJAN_TIME_ZONE_SID_KEY;
        }
        if(countryCode == RWANDA_COUNTRY_CODE) {
            return AFRICA_KIGALI_TIME_ZONE_SID_KEY;
        }
        if(countryCode == BURKINA_FASO_COUNTRY_CODE) {
            return AFRICA_OUAGADOUGOU_TIME_ZONE_SID_KEY;
        }
        if(countryCode == TOGO_COUNTRY_CODE) {
            return AFRICA_LOME_TIME_ZONE_SID_KEY;
        }

        return '';
    }

    public static String setLanguageLocaleKey(String countryCode){
        Boolean isUserLanguageFrench = setIsUserLanguageFrench(countryCode);
        if(isUserLanguageFrench) {
            return FRENCH_LANGUAGE_LOCALE_KEY;
        }
        if(countryCode == RWANDA_COUNTRY_CODE) {
            return ENGLISH_US_LANGUAGE_LOCALE_KEY;
        }

        return '';
    }

    public static String setLocalSideKey(String countryCode){
        Boolean isUserLanguageFrench = setIsUserLanguageFrench(countryCode);
        if(isUserLanguageFrench) {
            return FRENCH_LOCALE_SID_KEY;
        }
        if(countryCode == RWANDA_COUNTRY_CODE) {
            return ENGLISH_RWANDA_LOCALE_SID_KEY;
        }

        return '';
    }

    public static Boolean setIsUserLanguageFrench(String countryCode){
        return (countryCode == GABON_COUNTRY_CODE
                || countryCode == TOGO_COUNTRY_CODE
                || countryCode == CONGO_COUNTRY_CODE
                || countryCode == RDC_COUNTRY_CODE
                || countryCode == COTE_IVOIRE_COUNTRY_CODE
                || countryCode == BURKINA_FASO_COUNTRY_CODE
                || countryCode == FRANCE_COUNTRY_CODE);
    }

    public static String setMobilePhone(String personMobilePhone, String phone, String countryCallingCode){
        if(String.isNotBlank(personMobilePhone) && String.isNotBlank(phone)) {
            return formatPhone(countryCallingCode, personMobilePhone);
        }
        return '';

    }

    public static String setPhone(String personMobilePhone, String phone, String countryCallingCode ){
        if(String.isNotBlank(phone)) {
            return formatPhone(countryCallingCode, phone);
        }
        if(String.isBlank(phone) && String.isNotBlank(personMobilePhone)){
            return formatPhone(countryCallingCode, personMobilePhone);
        }
        return '';
    }

    private static String formatPhone(String countryCallingCode, String phone){
        // phone.trim();
        // if(phone.substring(0, 1) == '0') {
        //     phone = phone.substring(1);
        // }

        return countryCallingCode.trim() + ' ' + phone.trim();
    }

    /*public static AuraHandledException getAuraHandledException(String errorMessage){
        if(errorMessage.contains('DUPLICATE_COMM_NICKNAME')){
            errorMessage =  errorMessage.replace('DUPLICATE_COMM_NICKNAME','DUPLICATE_PHONE_OR_MOBILE_PHONE');
        }
        AuraHandledException ex = new AuraHandledException('');
        ex.setMessage(errorMessage);
        return ex;
    }*/

}