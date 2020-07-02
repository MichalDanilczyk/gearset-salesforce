@isTest
public with sharing class WishlistTriggerHandler_Test {

@testSetup

static void setup() {
  Account accWithoutGoldenRecord = UtilityTests.getPersonAccount();
  accWithoutGoldenRecord.LastName = 'accWithoutGoldenRecord';
  insert accWithoutGoldenRecord;

  Account goldenRecordAcc =  UtilityTests.getPersonAccount();
  GoldenRecordAcc.LastName = 'GoldenRecordAcc';
  GoldenRecordAcc.RICSC_HasLocalRecords__c = true;
  GoldenRecordAcc.RICSC_IsGoldenRecord__c = true;
  insert GoldenRecordAcc;

  Account accWithGoldenRecordLookUp =  UtilityTests.getPersonAccount();
  accWithGoldenRecordLookUp.LastName = 'accWithGoldenRecordLookUp';
  accWithGoldenRecordLookUp.RICSC_GoldenRecord__c = GoldenRecordAcc.Id;
  accWithGoldenRecordLookUp.RICSC_IsGoldenRecord__c = false;
  insert accWithGoldenRecordLookUp;

  Case testCase = new Case();
  insert testCase;

}

  static testmethod void populateGoldenRecordWithLocalRecordId() {
    Test.startTest();
    Account accWithoutGoldenRecord = [SELECT Id FROM Account WHERE Name = 'accWithoutGoldenRecord'];
    RICSC_Wishlist__c wslt = UtilityTests.getWishlist();
    wslt.RICSC_Account__c = accWithoutGoldenRecord.Id;
    insert wslt;
    Test.stopTest();

    RICSC_Wishlist__c wishListAfterPopulate = [SELECT RICSC_GoldenRecord__c,RICSC_Account__c FROM RICSC_Wishlist__c];
    System.assertEquals(wishListAfterPopulate.RICSC_GoldenRecord__c,wishListAfterPopulate.RICSC_Account__c);
  }


  static testmethod void populateGoldenRecordWithAccountsGoldenRecordId() {
    Test.startTest();
    Account accWithGoldenRecord = [SELECT Id FROM Account WHERE Name = 'accWithGoldenRecordLookUp'];
    RICSC_Wishlist__c wslt = UtilityTests.getWishlist();
    wslt.RICSC_Account__c = accWithGoldenRecord.Id;
    insert wslt;
    Test.stopTest();

    RICSC_Wishlist__c wishListAfterPopulate = [SELECT RICSC_GoldenRecord__c,RICSC_Account__c,RICSC_Account__r.RICSC_GoldenRecord__c FROM RICSC_Wishlist__c];
    System.assertEquals(wishListAfterPopulate.RICSC_GoldenRecord__c,wishListAfterPopulate.RICSC_Account__r.RICSC_GoldenRecord__c);
  }

}