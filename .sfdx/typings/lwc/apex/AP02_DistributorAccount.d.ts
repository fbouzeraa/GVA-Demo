declare module "@salesforce/apex/AP02_DistributorAccount.getDistributorProductRatePlansList" {
  export default function getDistributorProductRatePlansList(): Promise<any>;
}
declare module "@salesforce/apex/AP02_DistributorAccount.createDistributorSubscription" {
  export default function createDistributorSubscription(param: {AccountId: any, selectedJSON: any}): Promise<any>;
}
declare module "@salesforce/apex/AP02_DistributorAccount.getListDistributors" {
  export default function getListDistributors(param: {distName: any, distributorId: any}): Promise<any>;
}
declare module "@salesforce/apex/AP02_DistributorAccount.getListParentDistributors" {
  export default function getListParentDistributors(param: {distName: any, distributorId: any}): Promise<any>;
}
declare module "@salesforce/apex/AP02_DistributorAccount.checkAvailableAmount" {
  export default function checkAvailableAmount(param: {wholesalerId: any, amountToTransfer: any}): Promise<any>;
}
declare module "@salesforce/apex/AP02_DistributorAccount.handleCreditTransfer" {
  export default function handleCreditTransfer(param: {transferFrom: any, transferTo: any, amountToTransfer: any}): Promise<any>;
}
declare module "@salesforce/apex/AP02_DistributorAccount.getListSubscription" {
  export default function getListSubscription(param: {searchKey: any}): Promise<any>;
}
