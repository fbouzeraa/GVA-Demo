declare module "@salesforce/apex/AP01_Case.getCoupons" {
  export default function getCoupons(param: {AccountId: any, SubscriptionId: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_Case.insertCase" {
  export default function insertCase(param: {AccountId: any, SubscriptionId: any, status: any, reason: any, description: any, subject: any, type: any, cancelReason: any, termnationReason: any, freeDays: any, coupon: any}): Promise<any>;
}
declare module "@salesforce/apex/AP01_Case.getListSub" {
  export default function getListSub(param: {name: any, accountId: any}): Promise<any>;
}
