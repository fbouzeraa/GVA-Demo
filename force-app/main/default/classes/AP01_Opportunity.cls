public class AP01_Opportunity {

    public static void addPriceBookToOpportunity(list<Opportunity> listOpportunity){
        // Get default Pricebook for the current User

        // Country Code of the User should be as the country Code of the Quote/Account
        try {
            Id pbID = ZuoraSubscriptionActions.getUserPricebookID(UserInfo.getUserId());
            for(Opportunity newOpprotunity : listOpportunity) {
                newOpprotunity.Pricebook2Id = pbID;
            }
        } catch (Exception e) {
            system.debug(e.getMessage());
        }
    }
}