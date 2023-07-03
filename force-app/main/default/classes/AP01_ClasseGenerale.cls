/**
 * Classe contenant les methodes generales utiliser a chaque fois.
 * 
 * @author Jackie Abi Nassif
 * @date 1 Avril 2023
 */
public with sharing class AP01_ClasseGenerale {

    // methode utilise pour verifier du profil de l'utilisateur courant
    @AuraEnabled(cacheable=true)
    public static String userProfile(){

        String currentUserProfileId = UserInfo.getProfileId();
        String profileName = [SELECT Name FROM Profile WHERE Id =: currentUserProfileId].Name;

        return profileName;
    }

    // methode utilise pour verifier si l'utilisateur actuel est un utilisateur portail distributeur
    @AuraEnabled(cacheable = true)
    public static boolean isPartnerUser(){
        user currentUser = [SELECT Id, Profile.Name FROM User WHERE Id =: UserInfo.getUserId()];
        if(currentUser.Profile.Name == System.Label.Distributor_Profile) {
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled(cacheable=true)
    public static String userCountryCode(){
        try {
            user currentUser = [SELECT CountryCode, Profile.Name
                                FROM User
                                WHERE id =:UserInfo.getUserId()];

            return currentUser.CountryCode;
        } catch(Exception e) {
            throw new CustomException(e.getMessage());
        }
    }
    
    /**
     * Methode pour faire un preview de reabo
     * <p>
     * @param subId  id de la souscription,
     * @param nbPeriodes nombre de periode en cas de reabo,
     * @param isPreview choix du preview
     * @param withRenew pour indiquer si le upgrade est avec ou sans reabonnement,bizaOrder
     * @param immediateUpgrade boolean pout l'upgrade immediat
     * @param modeDePaiement mode de paiement
     * @param transactionNumber Numéro de transaction
     * @param offerCanal  produit bundle
     * @param optionsCanal produit bundle
     * @param categoryCanal produit bundle
     * @return resultat de l'appel API
     * */
    @AuraEnabled
    public static String handleAllPreviews(String renewType, Id subId, Integer nbPeriodes, Boolean withoutTax, String modeDePaiement, Boolean fromUI, 
                                        String offerCanal, list<string> optionsCanal, String categoryCanal, String transactionNumber, String operator, String aggregator,
                                        String dollarPayment, String CDFPayment, String dollarRefund, String CDFRefund){
        
        String previewResponse;

        if(renewType == 'Renew'){
            // call to get preview result of simple renew sub
            previewResponse = SubscriptionRenewalActions.renewSubPreview(subId, nbPeriodes, withoutTax, modeDePaiement, fromUI, null, offerCanal, optionsCanal, categoryCanal);
        }
        else if(renewType == 'Downgrade'){

            system.debug('here optionsCanal '+optionsCanal);
            previewResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(subId, null, nbPeriodes, true,  modeDePaiement, transactionNumber, 
                                aggregator == null ? operator : aggregator, dollarPayment != null ? double.valueOf(dollarPayment) : null, 
                                CDFPayment != null ? integer.valueOf(CDFPayment) : null,  dollarRefund != null ? integer.valueOf(dollarRefund) : null, 
                                CDFRefund != null ? integer.valueOf(CDFRefund) : null, null, offerCanal, optionsCanal, categoryCanal
                            );
        }
        else if(renewType == 'Upgrade'){

            previewResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(subId, nbPeriodes, true, true, false, modeDePaiement, transactionNumber,
                                aggregator == null ? operator : aggregator, dollarPayment!= null ? double.valueOf(dollarPayment) : null, 
                                CDFPayment != null ? integer.valueOf(CDFPayment) : null, dollarRefund != null ? integer.valueOf(dollarRefund) : null, 
                                CDFRefund != null ? integer.valueOf(CDFRefund) : null, null, offerCanal, optionsCanal, categoryCanal
                            );
        }else{
            previewResponse = System.Label.Preveiw_Error_RenewType;
        }

        return previewResponse;
    }

    public class CustomException extends Exception {}
}