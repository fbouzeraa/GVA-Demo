declare module "@salesforce/apex/ChangeBoxHelper.getProducts" {
  export default function getProducts(): Promise<any>;
}
declare module "@salesforce/apex/ChangeBoxHelper.getSubscriptionInfo" {
  export default function getSubscriptionInfo(param: {subScriptionId: any, zuoraProductId: any}): Promise<any>;
}
declare module "@salesforce/apex/ChangeBoxHelper.createTechnicalSubscription" {
  export default function createTechnicalSubscription(param: {subId: any, zuoraProductId: any, paymentMethode: any, transactionNumber: any, operator: any, aggregator: any, paymentDollar: any, paymentRDC: any, conversionRate: any, returnRDC: any, returnDollar: any}): Promise<any>;
}
