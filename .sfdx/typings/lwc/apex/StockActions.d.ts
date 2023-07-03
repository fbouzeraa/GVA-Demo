declare module "@salesforce/apex/StockActions.getBoxesInStock" {
  export default function getBoxesInStock(param: {article: any}): Promise<any>;
}
declare module "@salesforce/apex/StockActions.reserveBox" {
  export default function reserveBox(param: {selectedBox: any, quoteId: any, subscriptionId: any, article: any}): Promise<any>;
}
declare module "@salesforce/apex/StockActions.liberateBox" {
  export default function liberateBox(param: {selectedBox: any, boxNumber: any, article: any}): Promise<any>;
}
