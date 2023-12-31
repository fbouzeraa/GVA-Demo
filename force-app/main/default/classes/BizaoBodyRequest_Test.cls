//
// Generated by JSON2Apex http://json2apex.herokuapp.com/
//

@IsTest
public with sharing class BizaoBodyRequest_Test {
	
	// This test method should give 100% coverage
	static testMethod void testParse() {
		String json = '{'+
		'    \"meta\": {'+
		'        \"type\": \"payment\",'+
		'        \"source\": \"sn_orange_mm\",'+
		'        \"channel\": \"web\"'+
		'    },'+
		'    \"status\": \"Successful\",'+
		'    \"amount\": \"10\",'+
		'    \"order-id\": \"Merchant_Order_id_4\",'+
		'    \"currency\": \"XOF\",'+
		'    \"reference\": \"Your-reference\",'+
		'    \"date\": \"2020-09-29 09:34:32.0\",'+
		'    \"state\": \"param1%3Dvalue1%26param2%3Dvalue2\",'+
		'    \"country-code\": \"sn\",'+
		'    \"intTransaction-id\": \"1601372072771\",'+
		'    \"extTransaction-id \": \"MP200929.0935.A64320\"'+
		'  }';
		BizaoBodyRequest r = BizaoBodyRequest.parse(json);
		System.assert(r != null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		BizaoBodyRequest.Meta objMeta = new BizaoBodyRequest.Meta(System.JSON.createParser(json));
		System.assert(objMeta != null);
		System.assert(objMeta.type == null);
		System.assert(objMeta.source == null);
		System.assert(objMeta.channel == null);

		json = '{\"TestAMissingObject\": { \"TestAMissingArray\": [ { \"TestAMissingProperty\": \"Some Value\" } ] } }';
		BizaoBodyRequest objBizaoBodyRequest = new BizaoBodyRequest(System.JSON.createParser(json));
		System.assert(objBizaoBodyRequest != null);
		System.assert(objBizaoBodyRequest.meta == null);
		System.assert(objBizaoBodyRequest.status == null);
		System.assert(objBizaoBodyRequest.amount == null);
		System.assert(objBizaoBodyRequest.order_id == null);
		System.assert(objBizaoBodyRequest.currency_Z == null);
		System.assert(objBizaoBodyRequest.reference == null);
		System.assert(objBizaoBodyRequest.date_Z == null);
		System.assert(objBizaoBodyRequest.state == null);
		System.assert(objBizaoBodyRequest.country_code == null);
		System.assert(objBizaoBodyRequest.intTransaction_id == null);
		System.assert(objBizaoBodyRequest.extTransaction_id  == null);
	}
}