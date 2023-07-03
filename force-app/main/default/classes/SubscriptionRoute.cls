public class SubscriptionRoute extends RestRoute {

   /* protected override Object doGet() {

        String countryCode = RestContext.request.params.get('countryCode');
        USSDObjects.OfferAPIResponse response = new USSDObjects.OfferAPIResponse();

        if(countryCode != null) {
            List<Pricebook2> pbs = [SELECT ID, Name FROM Pricebook2 WHERE IsStandard = false AND IsActive = true AND Pays__c = :countryCode LIMIT 1];

            if(!pbs.isEmpty()) {
                Id productId = [SELECT Product2Id
                                FROM PriceBookEntry
                                WHERE Pricebook2Id = : pbs[0].id AND isActive = true
                                ORDER BY Product2.Name
                                LIMIT 1].Product2Id;
                // get list of available offers for the requested Country
                list<zqu__ProductRatePlan__c> listPRP = [  SELECT Id, Name, zqu__Product__r.Name, zqu__ZuoraId__c, Type__c, Category__c
                                                           FROM zqu__ProductRatePlan__c
                                                           WHERE (zqu__EffectiveStartDate__c  <= today AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) ) AND
                                                               (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY)) AND
                                                           zqu__Deleted__c = FALSE AND zqu__ProductRatePlanFullName__c != : system.label.Rate_Plan_Timbre_Fiscal AND
                                                           Type__c = 'Base' AND zqu__Product__c = : productId ];
                list<Id> listPrpId = new list<Id>();
                for(zqu__ProductRatePlan__c prp : listPRP) {
                    listPrpId.add(prp.Id);
                }
                //Get price of product rate plan charge
                list<zqu__productrateplanchargetier__c> listProductRatePlanPrice = [ SELECT zqu__Price__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c, zqu__DiscountAmount__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name
                                                                                     FROM zqu__productrateplanchargetier__c
                                                                                     WHERE zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c IN :listPrpId AND
                                                                                         (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) AND
                                                                                         (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY))];
                list<USSDObjects.ProductObject> listOffersWithPrice = new list<USSDObjects.ProductObject>();
                for(zqu__productrateplanchargetier__c prpPrice : listProductRatePlanPrice) {
                    USSDObjects.ProductObject prod = new USSDObjects.ProductObject();
                    prod.price = prpPrice.zqu__Price__c;
                    prod.name = prpPrice.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name;
                    listOffersWithPrice.add(prod);
                }
                response.Success = true;
                response.offers = listOffersWithPrice;

            } else {
                response.Success = false;
                response.Message = Label.PB_NO_PRICEBOOK_FOUND;
            }
        } else {
            response.Success = false;
            response.Message = 'Country Code not provided';
        }

        return json.serialize(response, true);

    }*/

//     //define downstream route
//     protected override Map<String, RestRoute> getNextRouteMap() {
//         return new Map<String, RestRoute> {
//                    'GetOffers' => new USSDOffers(RestContext.request.params.get('countryCode'))
//                    //'CheckAccount' => new MTNValidation(RestContext.request.requestBody.toString()),
//                    // 'VerifyRenewalOffer' => new MTNRenewalPreview(RestContext.request.requestBody.toString())
//         };
//     }
}