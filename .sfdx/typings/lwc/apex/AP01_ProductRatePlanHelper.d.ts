declare module "@salesforce/apex/AP01_ProductRatePlanHelper.getBaseProductRatePlansList" {
  export default function getBaseProductRatePlansList(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_ProductRatePlanHelper.getAddOnProductRatePlansList" {
  export default function getAddOnProductRatePlansList(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_ProductRatePlanHelper.verifySelectedProducts" {
  export default function verifySelectedProducts(param: {quoteId: any, selectedJSON: any, onlyBase: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_ProductRatePlanHelper.insertQuoteLineItems" {
  export default function insertQuoteLineItems(param: {quoteId: any, selectedJSON: any, paymentMethod: any, nbPeriod: any, transactionNumber: any, operator: any, article: any, creditOption: any, aggregator: any, offerName: any, listOptions: any, equipments: any, category: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_ProductRatePlanHelper.getQuoteLineItemProductRatePlansList" {
  export default function getQuoteLineItemProductRatePlansList(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_ProductRatePlanHelper.getCategoryValues" {
  export default function getCategoryValues(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_ProductRatePlanHelper.getDependentPicklistValues" {
  export default function getDependentPicklistValues(param: {listFieldName: any}): Promise<any>;
}
