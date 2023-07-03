declare module "@salesforce/apex/ZuoraSubscriptionActions.checkAccountEligibility" {
  export default function checkAccountEligibility(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.createSubscriptionInZuora" {
  export default function createSubscriptionInZuora(param: {quoteId: any, previewOnly: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.createPreviewSubscription" {
  export default function createPreviewSubscription(param: {prepaidPeriod: any, country: any, accountCurrency: any, listSubProduct: any, quoteId: any, fiscalId: any, chargeId: any, collabId: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.createTechnicalSubscription" {
  export default function createTechnicalSubscription(param: {selectedJSON: any, subscriptionId: any, isPreview: any, CDFPayment: any, dollarPayment: any, exchangeRate: any, returnInCDF: any, returnInDollar: any, transactionNumber: any, operator: any, aggregator: any, paymentMethod: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.getCustomerAccountId" {
  export default function getCustomerAccountId(param: {quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.createPayment" {
  export default function createPayment(param: {subscriptionId: any, zuoraAccountId: any, quoteId: any, orderNumber: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.activateSubscription" {
  export default function activateSubscription(param: {subscriptionId: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.cancelSubscription" {
  export default function cancelSubscription(param: {subscriptionId: any, newQuoteId: any, reasons: any, isResiliation: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.supspendSubscription" {
  export default function supspendSubscription(param: {subscriptionId: any, newQuoteID: any, periodType: any, period: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.getProductRatePlans" {
  export default function getProductRatePlans(): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.addDefaultPaymentMethod" {
  export default function addDefaultPaymentMethod(param: {AccountId: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.addOrderNumberToQuote" {
  export default function addOrderNumberToQuote(param: {orderNumber: any, quoteId: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.getZuoraAccountInfo" {
  export default function getZuoraAccountInfo(param: {accountNumber: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.addPaymentIdToQuote" {
  export default function addPaymentIdToQuote(param: {quoteId: any, paymentId: any}): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.sendFundReport" {
  export default function sendFundReport(): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.checkRDCUser" {
  export default function checkRDCUser(): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.userCountryCode" {
  export default function userCountryCode(): Promise<any>;
}
declare module "@salesforce/apex/ZuoraSubscriptionActions.insertLogs" {
  export default function insertLogs(param: {logs: any}): Promise<any>;
}
