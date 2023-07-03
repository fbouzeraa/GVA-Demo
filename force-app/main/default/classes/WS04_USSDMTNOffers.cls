/**
 * Classe utiliser pour recuperer les produits et les prix du catalogue Zuora et les envoyer vers le USSD MTN Congo
 * Classe de test: WS04_USSDMTNOffers_Test
 * @date 2023-04-11
 */
@RestResource(urlMapping = '/v1/MTNOffers/*')
global class WS04_USSDMTNOffers {

    @HttpPost
    global static string handleGet() {

        USSDObjects.OfferMTNAPIResponse response = new USSDObjects.OfferMTNAPIResponse();
        list<USSDObjects.ListOfarguments> listOffersWithPrice = new list<USSDObjects.ListOfarguments>();

        if(RestContext.request.requestBody == null){
            response.success = false;
            response.message = 'No request body received';
            return json.serialize(response, true);
        }
        MTNObjects.getOffersReq transactionRequest = (MTNObjects.getOffersReq) JSON.deserialize(RestContext.request.requestBody.toString(), MTNObjects.getOffersReq.class);


        // check if the box number is provided
        if(transactionRequest.arguments[0].value.value != '' && transactionRequest.arguments[0].value.value != null)
        {
            // get all needed info based on the box number
            String boxNumber = transactionRequest.arguments[0].value.value;
            list<zuora__subscriptionProductCharge__c> subPrCharge = [SELECT Id, Name, Zuora__Subscription__r.BoxNumber__c, Zuora__Subscription__r.Zuora__Account__r.Name,Zuora__Subscription__c,
                                                                        Zuora__Subscription__r.Name, Zuora__Subscription__r.SUB_T_Produit_De_Base__c, Zuora__Subscription__r.SUB_T_Account_Country__c,
                                                                        Zuora__Subscription__r.Zuora__Status__c, Zuora__Subscription__r.Zuora__Account__c,
                                                                        IsDeleted, Zuora__ListPriceBase__c, Zuora__Product__c,Zuora__Product__r.Name,
                                                                        Zuora__Subscription__r.Zuora__CustomerAccount__r.Zuora__AccountNumber__c,
                                                                        Zuora__Subscription__r.Zuora__SubscriptionNumber__c,Zuora__RatePlanId__c,
                                                                        Zuora__Subscription__r.ExpectedRenewalDate__c,Zuora__Subscription__r.isCollaborator__c
                                                                    FROM zuora__subscriptionProductCharge__c
                                                                    WHERE Zuora__Subscription__r.BoxNumber__c =: boxNumber
                                                                    AND (Zuora__Subscription__r.Zuora__Status__c = :System.Label.Sub_Status_Active OR Zuora__Subscription__r.Zuora__Status__c = :System.Label.Sub_Status_Suspended)];
            if(subPrCharge != null && !subPrCharge.isEmpty())
            {
                // check the current base product and if the current sub is collab.
                String baseProduct = subPrCharge[0].Zuora__Subscription__r.SUB_T_Produit_De_Base__c; 
                String likeSubProdCountry = subPrCharge[0].Zuora__Product__r.Name;
                String pRPChargeId;
                Boolean isCollab = false;
                if(subPrCharge[0].Zuora__Subscription__r.isCollaborator__c == 'Y'){
                    //    pRPChargeId = SubscriptionRenewalActions.getCollaboratorCharge(subPrCharge[0].Zuora__Subscription__c);
                    isCollab = true;
                }  
                // get the available products(amount, name, bandwidth) of the current subscription
                list<zqu__productrateplanchargetier__c> listOfChargeTier = [SELECT Name, zqu__DiscountAmount__c, zqu__Price__c, zqu__DiscountPercentage__c,
                                                                            zqu__ProductRatePlanCharge__r.Name, zqu__ProductRatePlanCharge__r.zqu__Type__c, 
                                                                            zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Bandwidth__c, zqu__Currency__c,
                                                                            zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.type__c,
                                                                            zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name
                                                                            FROM zqu__productrateplanchargetier__c
                                                                            WHERE zqu__Price__c != 0 AND zqu__ProductRatePlanCharge__r.zqu__Type__c = 'Recurring'
                                                                            AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__ZProduct__r.Name LIKE :likeSubProdCountry 
                                                                            AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.type__c = 'Base'
                                                                            AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Bandwidth__c != null
                                                                            AND (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveStartDate__c  <= today AND (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c = null OR zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__EffectiveEndDate__c > TODAY) ) 
                                                                            AND (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SellingEffectiveStartDate__c  <= today AND (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SellingEffectiveEndDate__c = null OR zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.SellingEffectiveEndDate__c > TODAY))
                                                                            AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE];
                if(listOfChargeTier != null && !listOfChargeTier.isEmpty()){
                    listOffersWithPrice = getAllProducts(listOfChargeTier, isCollab, likeSubProdCountry);
                }    

                // if products found success true
                if(listOffersWithPrice != null && listOffersWithPrice.size() > 0){
                    response.argumentsList = listOffersWithPrice;
                    response.success = true;
                }else{
                    response.success = false;
                    response.message = System.Label.WS_Message_NoProducts;
                }
            } else {
                response.success = false;
                response.message = System.Label.WS_Message_NoSub;
            }
        } else {
            response.success = false;
            response.message = System.Label.WS_Message_NoBoxNumber;
        }

        return json.serialize(response, true);
    }

    // get the available products ---- and if it's a collaborator get the AddOn product (Discount)
    public static list<USSDObjects.ListOfarguments> getAllProducts(list<zqu__productrateplanchargetier__c> listOfBaseProducts, Boolean isCollab, String likeSubProdCountry){
        
        list<USSDObjects.ListOfarguments> listOffersWithPrice = new list<USSDObjects.ListOfarguments>();
        
        Decimal productDiscount;

        if(isCollab){
            String currentCurrency = listOfBaseProducts[0].zqu__Currency__c;
            list<zqu__productrateplanchargetier__c> listOfAddOnProduct = [SELECT Name, zqu__Price__c, zqu__DiscountPercentage__c, zqu__ProductRatePlanCharge__r.Name, zqu__Currency__c
                                                                        FROM zqu__productrateplanchargetier__c
                                                                        WHERE zqu__Price__c != 0 AND zqu__Currency__c =:currentCurrency
                                                                        AND zqu__ProductRatePlanCharge__r.zqu__Type__c = 'Recurring'
                                                                        AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.type__c = 'AddOn'
                                                                        AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Category__c = 'Collaborator'
                                                                        AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Product__r.Name like :likeSubProdCountry 
                                                                        AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE];
            if(listOfAddOnProduct != null && listOfAddOnProduct.size() > 0){
                productDiscount = listOfAddOnProduct[0].zqu__DiscountPercentage__c;            
            }else{
                return listOffersWithPrice; // return an empty list
            }
        }

        for (zqu__productrateplanchargetier__c item : listOfBaseProducts){

            if(item.zqu__ProductRatePlanCharge__r.Name == System.Label.Start_BaseProduct || item.zqu__ProductRatePlanCharge__r.Name == System.Label.Premium_BaseProduct){
                
                list<USSDObjects.Argument> listArgument = new list<USSDObjects.Argument>();
                USSDObjects.ListOfarguments listOFProdInfo = new USSDObjects.ListOfarguments();

                // Product name
                USSDObjects.Argument argument = new USSDObjects.Argument();
                USSDObjects.Value argValue = new USSDObjects.Value();
                USSDObjects.Key argKey = new USSDObjects.Key();
                argKey.value = 'prodName';
                argValue.value = item.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name;
                argument.value = argValue;
                argument.key = argKey;
                listArgument.add(argument);

                // Product Price
                USSDObjects.Argument argument2 = new USSDObjects.Argument();
                USSDObjects.Key argKey2= new USSDObjects.Key();
                USSDObjects.Value argValue2= new USSDObjects.Value();
				argKey2.value = 'prodPrice';
                if(isCollab){
                    argValue2.value = String.valueOf((item.zqu__Price__c * (100 - productDiscount)) / 100).split('\\.')[0];
                }else{
                    argValue2.value = String.valueOf(item.zqu__Price__c).split('\\.')[0];
                }
                argument2.value = argValue2;
                argument2.key = argKey2;
                listArgument.add(argument2);

                // Product Currency
                USSDObjects.Argument argument3 = new USSDObjects.Argument();
                USSDObjects.Key argKey3= new USSDObjects.Key();
                USSDObjects.Value argValue3= new USSDObjects.Value();
				argKey3.value = 'prodCurrency';
                argValue3.value = item.zqu__Currency__c;
                argument3.value = argValue3;
                argument3.key = argKey3;
                listArgument.add(argument3);

                // Product Bandwidth
                USSDObjects.Argument argument4 = new USSDObjects.Argument();
                USSDObjects.Key argKey4= new USSDObjects.Key();
                USSDObjects.Value argValue4= new USSDObjects.Value();
				argKey4.value = 'prodBandwidth';
                argValue4.value = item.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Bandwidth__c;
                argument4.value = argValue4;
                argument4.key = argKey4;
                listArgument.add(argument4);

                listOFProdInfo.arguments = listArgument;
                listOffersWithPrice.add(listOFProdInfo);
            }
        }

        return listOffersWithPrice;
    }

}