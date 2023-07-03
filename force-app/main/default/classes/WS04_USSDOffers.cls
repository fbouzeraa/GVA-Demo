/**
 * Test Class : WS04_USSDOffers_Test
 * @author Jackie Abi Nassif
 * @date 2022-09-29
 */
@RestResource(urlMapping = '/v1/Offers/*')
global class WS04_USSDOffers {

    @HttpGet
    global static string handleGet() {

        USSDObjects.OfferAPIResponse response = new USSDObjects.OfferAPIResponse();
        list<USSDObjects.ProductObject> listOffersWithPrice = new list<USSDObjects.ProductObject>();

        // check if the box number is provided
        if(RestContext.request.params.get(System.Label.WS_Param_routerNumber) != '' && RestContext.request.params.get(System.Label.WS_Param_routerNumber) != null)
        {
            // get all needed info based on the box number
            String boxNumber = RestContext.request.params.get(System.Label.WS_Param_routerNumber);
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
            if(!subPrCharge.isEmpty())
            {
                // check the current base product and if the current sub is collab.
                String baseProduct = subPrCharge[0].Zuora__Subscription__r.SUB_T_Produit_De_Base__c; 
                String likeSubProdCountry = subPrCharge[0].Zuora__Product__r.Name;
                String likeSubProdCountryPlus = likeSubProdCountry; // +'%SME'
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
                if(!listOfChargeTier.isEmpty()){
                    listOffersWithPrice.addAll(getAllProducts(listOfChargeTier, isCollab, likeSubProdCountry, likeSubProdCountryPlus));
                }                                                            

                /* get the products directly from Zuora by preview API call
                    // get the product name and price of the current base product
                    String renewResponse = SubscriptionRenewalActions.renewSubPreview(subPrCharge[0].Zuora__Subscription__c, 1, true, 'Mobile_Money', false, 
                                                                            isCollab == true?pRPChargeId.substring (0, pRPChargeId.indexOf(',')) : null);
                    ZuoraResponseObjects.ZuoraPreviewResponse simpleRenewResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                                        renewResponse, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                    if(simpleRenewResponse.success){
                        listOffersWithPrice.addAll(previewResponseSuccessTrue(simpleRenewResponse));
                    }else{
                        return previewResponseSuccessFalse(response, simpleRenewResponse);
                    }

                    // get the product name and price of the other base product
                    if(baseProduct == System.Label.Start_BaseProduct){
                        String upgradeResponse = SubscriptionRenewalActions.upgradeSubscriptionProduct(subPrCharge[0].Zuora__Subscription__c, 1, true, true, false,
                                                                            'Mobile_Money', null, null, null, null, null, null, null);
                        ZuoraResponseObjects.ZuoraPreviewResponse upgradeRenewResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                                                                                upgradeResponse, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                        if(upgradeRenewResponse.success){
                            listOffersWithPrice.addAll(previewResponseSuccessTrue(upgradeRenewResponse));
                        }else{
                            return previewResponseSuccessFalse(response, upgradeRenewResponse);
                        }
                    }else if(baseProduct == System.Label.Premium_BaseProduct){
                        String downgradeResponse = SubscriptionRenewalActions.downgradeSubscriptionProduct(subPrCharge[0].Zuora__Subscription__c, null, 1, true,
                                                                                'Mobile_Money', null, null, null, null, null, null, null);
                        ZuoraResponseObjects.ZuoraPreviewResponse downgradeRenewResponse = (ZuoraResponseObjects.ZuoraPreviewResponse) JSON.deserialize(
                                                                                downgradeResponse, ZuoraResponseObjects.ZuoraPreviewResponse.class);
                        if(downgradeRenewResponse.success){
                            listOffersWithPrice.addAll(previewResponseSuccessTrue(downgradeRenewResponse));
                        }else{
                            return previewResponseSuccessFalse(response, downgradeRenewResponse);
                        }
                    } 
                */

                // if products found success true
                if(listOffersWithPrice != null && listOffersWithPrice.size() > 0){
                    response.Success = true;
                    response.offers = listOffersWithPrice;
                }else{
                    response.Success = false;
                    response.Message = System.Label.WS_Message_NoProducts;
                }
            } else {
                response.Success = false;
                response.Message = System.Label.WS_Message_NoSub;
            }
        } else {
            response.Success = false;
            response.Message = System.Label.WS_Message_NoBoxNumber;
        }

        return json.serialize(response, true);
    }

    /*
        public static String previewResponseSuccessFalse(USSDObjects.OfferAPIResponse response, ZuoraResponseObjects.ZuoraPreviewResponse previewResponse){

            response.Success = false;
            response.Message = previewResponse.reasons[0].message;

            return json.serialize(response, true);
        }
        public static list<USSDObjects.ProductObject> previewResponseSuccessTrue(ZuoraResponseObjects.ZuoraPreviewResponse previewResponse){

            list<USSDObjects.ProductObject> listOffersWithPrice = new list<USSDObjects.ProductObject>();

            for (ZuoraResponseObjects.ZuoraInvoiceItems item : previewResponse.previewResult.invoices[0].invoiceItems){
                system.debug(item.ratePlanName);
                if(item.ratePlanName == System.Label.Start_BaseProduct || item.ratePlanName == System.Label.Premium_BaseProduct){

                    USSDObjects.ProductObject prod = new USSDObjects.ProductObject();
                    prod.price = previewResponse.previewResult.invoices[0].amount;
                    prod.name = item.ratePlanName;
                    prod.description = item.bandwidth;
                    listOffersWithPrice.add(prod);
                }
            }

            return listOffersWithPrice;
        } 
    */

    // get the available products ---- and if it's a collaborator get the AddOn product (Discount)
    public static list<USSDObjects.ProductObject> getAllProducts(list<zqu__productrateplanchargetier__c> listOfBaseProducts, Boolean isCollab, String likeSubProdCountry, String likeSubProdCountryPlus){

        list<USSDObjects.ProductObject> listOffersWithPrice = new list<USSDObjects.ProductObject>();
        Decimal productDiscount;

        if(isCollab){
            String currentCurrency = listOfBaseProducts[0].zqu__Currency__c;
            list<zqu__productrateplanchargetier__c> listOfAddOnProduct = [SELECT Name, zqu__Price__c, zqu__DiscountPercentage__c, zqu__ProductRatePlanCharge__r.Name, zqu__Currency__c
                                                                        FROM zqu__productrateplanchargetier__c
                                                                        WHERE zqu__Price__c != 0 AND zqu__Currency__c =:currentCurrency
                                                                        AND zqu__ProductRatePlanCharge__r.zqu__Type__c = 'Recurring'
                                                                        AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.type__c = 'AddOn'
                                                                        AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Category__c = 'Collaborator'
                                                                        AND (zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Product__r.Name like :likeSubProdCountry 
                                                                            OR zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Product__r.Name like :likeSubProdCountryPlus)
                                                                        AND zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.zqu__Deleted__c = FALSE];
            if(listOfAddOnProduct != null && listOfAddOnProduct.size() > 0){
                productDiscount = listOfAddOnProduct[0].zqu__DiscountPercentage__c;            
            }else{
                return listOffersWithPrice; // return an empty list
            }
        }

        for (zqu__productrateplanchargetier__c item : listOfBaseProducts){

            if(item.zqu__ProductRatePlanCharge__r.Name == System.Label.Start_BaseProduct || item.zqu__ProductRatePlanCharge__r.Name == System.Label.Premium_BaseProduct){
                USSDObjects.ProductObject prod = new USSDObjects.ProductObject();

                if(isCollab){
                    prod.price = (item.zqu__Price__c * (100 - productDiscount)) / 100;
                }else{
                    prod.price = item.zqu__Price__c;
                }
                prod.name = item.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Name;
                prod.currentCurrency = item.zqu__Currency__c;
                prod.description = item.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__r.Bandwidth__c;
                listOffersWithPrice.add(prod);
            }
        }

        return listOffersWithPrice;
    }

}