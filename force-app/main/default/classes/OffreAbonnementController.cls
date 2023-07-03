public without sharing class OffreAbonnementController {

    @AuraEnabled //(Cacheable=false)
    public static List<ProductRatePlanWrapperResponse> getAvailableProductRatePlans(String zuoraSubscriptionId){
        User currentUser = getCurrentUser();
        List<PricebookEntry> pricebookEntries = getPricebookEntries(currentUser.countryCode);

        if(pricebookEntries != null && pricebookEntries.size() > 0) {
            Map<Id, PriceBookEntry> pbePerProductMap = createPriceBookEntryPerProductMap(pricebookEntries);

            // Get all product rate plan for the selected Price Book
            List<zqu__ProductRatePlan__c> listPrp = getProductRatePlans(pbePerProductMap);

            System.debug('listPrp 1: ' + listPrp);

            if(Test.isRunningTest()) {
                listPrp = [SELECT Name, Id, Bandwidth__c, CurrencyIsoCode, zqu__Product__c
                           FROM zqu__ProductRatePlan__c LIMIT 1];
            }
            System.debug('listPrp 2: ' + listPrp);

            List<ProductRatePlanWrapperResponse> productRatePlanWrapperResponses = createProductRatePlanWrapperResponses(listPrp, zuoraSubscriptionId);

            productRatePlanWrapperResponses = setProductRatePlanCurrencyIsoCode(productRatePlanWrapperResponses, zuoraSubscriptionId);
            Zuora__Subscription__c zuoraSubscription = [SELECT IsCollaborator__c FROM Zuora__Subscription__c WHERE Id = :zuoraSubscriptionId];
            if(zuoraSubscription.isCollaborator__c == 'Y') {
                productRatePlanWrapperResponses = setProductRatePlanPrices(productRatePlanWrapperResponses, zuoraSubscriptionId);
            }

            return productRatePlanWrapperResponses;
        }

        return null;
    }

    private static List<zqu__ProductRatePlan__c> getProductRatePlans(Map<Id, PriceBookEntry> pbePerProductMap){
        List<zqu__ProductRatePlan__c> listProductPlan = [SELECT Name, Id, Bandwidth__c, CurrencyIsoCode
        FROM zqu__ProductRatePlan__c
        WHERE zqu__Product__c IN : pbePerProductMap.keyset()
        AND (zqu__EffectiveStartDate__c  <= today
             AND (zqu__EffectiveEndDate__c = null OR zqu__EffectiveEndDate__c > TODAY) )
        AND (SellingEffectiveStartDate__c  <= today AND (SellingEffectiveEndDate__c = null OR SellingEffectiveEndDate__c > TODAY))
        AND zqu__Deleted__c = FALSE
        AND zqu__ProductRatePlanFullName__c != : system.label.Rate_Plan_Timbre_Fiscal
        AND Type__c = 'Base'
        AND (Category__c = 'Offer' OR Category__c= 'Installation service')
        AND Bandwidth__c != null
        ORDER BY Name DESC];
        return listProductPlan;
    }

    private static User getCurrentUser(){
        String userId = UserInfo.getUserId();

        return [SELECT Id, CountryCode FROM USER WHERE Id = : userId];
    }

    private static List<PricebookEntry> getPricebookEntries(String countryCode){
        return [SELECT Id, Pricebook2Id, Product2Id, UnitPrice, Name, Product2.Name
                FROM PricebookEntry
                WHERE Pricebook2.Pays__c = : countryCode
                AND IsActive = true];
    }

    private static List<ProductRatePlanWrapperResponse> setProductRatePlanCurrencyIsoCode(List<ProductRatePlanWrapperResponse> productRatePlanWrapperResponses, String zuoraSubscriptionId){
        String currencyIsoCode = [SELECT CurrencyIsoCode FROM Zuora__Subscription__c WHERE Id = :zuoraSubscriptionId LIMIT 1].currencyIsoCode;
        for(ProductRatePlanWrapperResponse productRatePlanWrapperResponse : productRatePlanWrapperResponses) {
            productRatePlanWrapperResponse.currencyIsoCode = currencyIsoCode;
        }

        return productRatePlanWrapperResponses;
    }

    private static List<ProductRatePlanWrapperResponse> setProductRatePlanPrices(List<ProductRatePlanWrapperResponse> productRatePlanWrapperResponses, String zuoraSubscriptionId){
        Zuora__SubscriptionProductCharge__c zuoraSubscription = [SELECT Name
                                                                 FROM Zuora__SubscriptionProductCharge__c
                                                                 WHERE Zuora__Subscription__c = :zuoraSubscriptionId
                                                                 AND (Name = 'Start' OR Name = 'Premium')
                                                                 LIMIT 1];

        for(ProductRatePlanWrapperResponse productRatePlanWrapperResponse : productRatePlanWrapperResponses) {
            if(productRatePlanWrapperResponse.name ==  'Start') {
                productRatePlanWrapperResponse.price = setProductRatePlanPriceRenew(zuoraSubscriptionId);
            }

            if(productRatePlanWrapperResponse.name ==  'Premium') {
                if(zuoraSubscription.name == 'Start') {
                    productRatePlanWrapperResponse.price = setProductRatePlanPriceRenewUpgrade(zuoraSubscriptionId);
                }
                if(zuoraSubscription.name == 'Premium') {
                    productRatePlanWrapperResponse.price = setProductRatePlanPriceRenew(zuoraSubscriptionId);
                }

            }
        }

        return productRatePlanWrapperResponses;
    }

    private static List<ProductRatePlanWrapperResponse> createProductRatePlanWrapperResponses(List<zqu__ProductRatePlan__c> listPrp, String zuoraSubscriptionId){
        List<Id> listPrpId = new List<Id>();
        List<ProductRatePlanWrapperResponse> productRatePlanWrapperResponses = new List<ProductRatePlanWrapperResponse>();
        Zuora__SubscriptionProductCharge__c zuoraSubscription = [SELECT Name
                                                                 FROM Zuora__SubscriptionProductCharge__c
                                                                 WHERE Zuora__Subscription__c = :zuoraSubscriptionId
                                                                 AND (Name = 'Start' OR Name = 'Premium')
                                                                 LIMIT 1];
        if(listPrp.size() != null && listPrp.size() > 0) {
            System.debug('In if listPrp');
            for(zqu__ProductRatePlan__c currentPrp : listPrp) {
                listPrpId.add(currentPrp.Id);
                System.debug('zuoraSubscription.name : ' + zuoraSubscription.name);
                if(zuoraSubscription.name == 'Start') {
                    ProductRatePlanWrapperResponse productRatePlanWrapperResponse =
                    new ProductRatePlanWrapperResponse(currentPrp.name,
                                                       currentPrp.bandwidth__c,
                                                       null,
                                                       currentPrp.currencyIsoCode);
                    productRatePlanWrapperResponses.add(productRatePlanWrapperResponse);
                }
                if(zuoraSubscription.name == 'Premium' && zuoraSubscription.name == currentPrp.name) {
                    ProductRatePlanWrapperResponse productRatePlanWrapperResponse =
                    new ProductRatePlanWrapperResponse(currentPrp.name,
                                                       currentPrp.bandwidth__c,
                                                       null,
                                                       currentPrp.currencyIsoCode);
                    productRatePlanWrapperResponses.add(productRatePlanWrapperResponse);
                }

            }

            // Get price of product rate plan charge
            List<zqu__productrateplanchargetier__c> listProductRatePlanPrice = [ SELECT zqu__Price__c, zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c, zqu__ProductRatePlanCharge__r.name, name
                                                                                 FROM zqu__productrateplanchargetier__c
                                                                                 WHERE zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c IN :listPrpId  ];
            Map<Id, Double> pricePerProductRatePlanMap = new Map<Id, Double>();
            for(zqu__productrateplanchargetier__c PRPC : listProductRatePlanPrice) {
                Double price = Double.valueof(PRPC.zqu__Price__c);
                pricePerProductRatePlanMap.put(PRPC.zqu__ProductRatePlanCharge__r.zqu__ProductRatePlan__c, price);
                for(ProductRatePlanWrapperResponse productRatePlanWrapperResponse : productRatePlanWrapperResponses) {
                    if(productRatePlanWrapperResponse.name ==  PRPC.zqu__ProductRatePlanCharge__r.name) {
                        productRatePlanWrapperResponse.price = price;
                    }
                }
            }
        }

        return productRatePlanWrapperResponses;
    }

    private static Map<Id, PriceBookEntry> createPriceBookEntryPerProductMap(List<PricebookEntry> pricebookEntries){
        Map<Id, PriceBookEntry> pbePerProductMap = new Map<Id, PricebookEntry>();
        for(PricebookEntry pricebookEntry : pricebookEntries) {
            Boolean isPriceBookEntrySME = pricebookEntry.Name.contains('SME');
            if(!isPriceBookEntrySME) {
                pbePerProductMap.put(pricebookEntry.Product2Id, pricebookEntry);
            }
        }
        return pbePerProductMap;
    }

    private static Double setProductRatePlanPriceRenew(Id zuoraSubscriptionId){
        System.debug('In start');
        Boolean withoutTax = false;
        Integer numberOfPeriod = 1;
        String paymentMode = 'Credit_Card';
        Boolean fromUI = false;
        String PRPChargeId =  null;
        Zuora__Subscription__c zuoraSubscription = [SELECT IsCollaborator__c FROM Zuora__Subscription__c WHERE Id = :zuoraSubscriptionId];
        if(zuoraSubscription.IsCollaborator__c == 'Y') {
            PRPChargeId = SubscriptionRenewalActions.getCollaboratorCharge(zuoraSubscriptionId);
            PRPChargeId = PRPChargeId.substring (0, PRPChargeId.indexOf(','));
        }
        String renewSubPreviewResponseJson
            = SubscriptionRenewalActions.renewSubPreview(zuoraSubscriptionId, numberOfPeriod, withoutTax, paymentMode, fromUI, PRPChargeId, null, null, null);
        System.debug('renewSubPreviewResponseJson : ' + renewSubPreviewResponseJson);
        RenewSubPreviewResponse renewSubPreviewResponse = RenewSubPreviewResponse.parse(renewSubPreviewResponseJson);

        return renewSubPreviewResponse.previewResult.invoices[0].amount;
    }

    private static Double setProductRatePlanPriceRenewUpgrade(Id zuoraSubscriptionId){
        Boolean withoutTax = false;
        Integer numberOfPeriod = 1;
        Boolean isPreview = true;
        Boolean withRenew  = true;
        Boolean immediateUpgrade  = false;
        String paymentMode = 'Credit_Card';
        String transactionNumber = null;
        String operator = null;
        Double dollarPayment = null;
        Integer CDFPayment = null;
        Integer dollarRefund = null;
        Integer CDFRefund = null;
        String bizaoOrderId = null;
        String renewSubPreviewResponseJson = SubscriptionRenewalActions.upgradeSubscriptionProduct(zuoraSubscriptionId, numberOfPeriod, isPreview,
                                                                                                   withRenew, immediateUpgrade,  paymentMode,  transactionNumber, operator,
                                                                                                   dollarPayment, CDFPayment,  dollarRefund, CDFRefund, bizaoOrderId, null, null, null);
        RenewSubPreviewResponse renewSubPreviewResponse = RenewSubPreviewResponse.parse(renewSubPreviewResponseJson);

        return renewSubPreviewResponse.previewResult.invoices[0].amount;
    }

    @TestVisible
    private class ProductRatePlanWrapperResponse {

        @AuraEnabled
        public String name {get; set;}

        @AuraEnabled
        public String bandwidth {get; set;}

        @AuraEnabled
        public Double price {get; set;}

        @AuraEnabled
        public String currencyIsoCode {get; set;}

        ProductRatePlanWrapperResponse(String name, String bandwidth, Double price, String currencyIsoCode){
            this.name = name;
            this.bandwidth = bandwidth;
            this.price = price;
            this.currencyIsoCode = currencyIsoCode;
        }
    }

}