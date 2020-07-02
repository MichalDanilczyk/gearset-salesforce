@isTest
public with sharing class ProductPortfolioTriggerHandler_Test {

  @testSetup
  static void setup() {
    Account involvedAccount = UtilityTests.getPersonAccount();
    involvedAccount.RICSC_IsGoldenRecord__c = true;
    involvedAccount.RICSC_HasLocalRecords__c = true;
    insert involvedAccount;
  }

  static testmethod void classCodeWholesaler() {
    //Class code is wholesaler if all assets are without transaction id
    Test.startTest();
    Account acc = [SELECT Id FROM Account LIMIT 1];
    Asset involvedAsset = UtilityTests.getAsset();
    involvedAsset.Name = 'Involved Asset';
    involvedAsset.RICSC_GoldenRecord__c = acc.Id;
    insert involvedAsset;
    Asset involvedAsset2 = UtilityTests.getAsset();
    involvedAsset2.Name = 'Involved Asset 2';
    involvedAsset2.RICSC_GoldenRecord__c = acc.Id;
    insert involvedAsset2;
    Test.stopTest();

    System.assertEquals(UtilityConstants.CLASS_CODE_WHLSL, [SELECT RICSC_ClassCode__c FROM Account LIMIT 1].RICSC_ClassCode__c,0);
  }

   static testmethod void classCodeProspect() {
    Account acc = [SELECT Id, RICSC_ClassCode__c FROM Account LIMIT 1];
    //if no transaction related and class code not already wholesaler then CLASS CODE is Prospect
    System.assertEquals(UtilityConstants.CLASS_CODE_PROSP, acc.RICSC_ClassCode__c);
    Test.startTest();
    RICSC_Transaction__c tr = new RICSC_Transaction__c(RICSC_GoldenRecord__c = acc.Id,RICSC_Account__c = acc.Id,RICSC_TransactionCategory__c = UtilityConstants.TRANSACTION_TYPE_REPAIR);
    insert tr;
    acc = [SELECT Id, RICSC_ClassCode__c FROM Account LIMIT 1];
    //if no transaction related and class code not already wholesaler then CLASS CODE is Prospect
    System.assertEquals(UtilityConstants.CLASS_CODE_SCLNT, acc.RICSC_ClassCode__c);
    acc = [SELECT Id FROM Account LIMIT 1];
    Test.stopTest();
  }

   static testmethod void assertCreationAndPreviousDeletion() {

     Account acc = [SELECT Id FROM Account LIMIT 1];
	
     Test.startTest();  
     Asset ast1 = UtilityTests.getAsset();
     ast1.Name = 'Asset That is Going To Be Deleted';
     ast1.AccountId = acc.Id;
     ast1.SerialNumber = '1234';
     ast1.Price	= 20;
     insert ast1;

     Asset ast2 = UtilityTests.getAsset();
     ast2.Name = 'Asset That is Going To Be Inserted';
     ast2.AccountId = acc.Id;
     ast2.SerialNumber = '1234';
     ast2.Price = 30;
     insert ast2;
	 Test.stopTest();
       
     //Since the two assets got same serial number, the excisting asset is going to be deleted
     System.assertEquals(1,[SELECT count() FROM Asset WHERE isDeleted = false]);

     //The Second Asset that is being imported is going actually to take place of the first one
     System.assertEquals(30, [SELECT Price FROM Asset WHERE isDeleted = false].Price);

   }


}