@isTest
public with sharing class MergeExtension_TEST {
    public MergeExtension_TEST() {
      makeData();
    }

    @TestSetup
    static void makeData(){
      UtilityTests.testSetup();
      Account masterRecord = new Account(FirstName = 'Golden', LastName = 'Account', RICSC_Maison__c = 'Cartier', RICSC_FirstSalesDate__c = Date.today(), RICSC_ConsentTimestamp__c = Datetime.now(), RICSC_CanBeContacted__c = true, RICSC_ClientSegment__c = 'TestClientSegment',RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_Cartier'));
      Database.insert(masterRecord);
      List<Account> mergedRecordList = new List<Account>();
      for(Integer i=0; i<4; i++){
        Account a = new Account(FirstName = 'Test', LastName = '00'+String.valueOf(i), RICSC_Maison__c = 'Cartier', RICSC_FirstSalesDate__c = Date.today(), RICSC_ConsentTimestamp__c = Datetime.now().addMonths(-1), RICSC_CanBeContacted__c = false, RICSC_ClientSegment__c = 'TestClientSegment',RecordTypeId = RecordTypeHelper.getRTId('Account', 'RICSC_Cartier'));
        if(i==3){
          a.RICSC_NotToBeGrouped__c = true;
        }
        mergedRecordList.add(a);
      }
      Database.insert(mergedRecordList);
      List<RICSC_Email__c> emailsList = new List<RICSC_Email__c>();
      List<RICSC_SocialMediaID__c> smIDList = new List<RICSC_SocialMediaID__c>();
      List<RICSC_Phone__c> phonesList = new List<RICSC_Phone__c>();
      List<RICSC_Address__c> addressList = new List<RICSC_Address__c>();
      List<RICSC_Transaction__c> transactionsList = new List<RICSC_Transaction__c>();
      List<RICSC_Activity__c> activitiesList = new List<RICSC_Activity__c>();
      List<RICSC_Wishlist__c> wishlistsList = new List<RICSC_Wishlist__c>();
      RICSC_Email__c email = new RICSC_Email__c(RICSC_Account__c = masterRecord.Id);
      emailsList.add(email);
      RICSC_SocialMediaID__c smID = new RICSC_SocialMediaID__c(RICSC_Account__c = masterRecord.Id);
      smIDList.add(smId);
      RICSC_Phone__c phone = new RICSC_Phone__c(RICSC_Account__c = masterRecord.Id);
      phonesList.add(phone);
      RICSC_Address__c address = new RICSC_Address__c(RICSC_Account__c = masterRecord.Id);
      addressList.add(address);
      Product2 p = new Product2(Name = 'Test Product', RICSC_TechnicalProductType__c = 'Watches',RICSC_Maison__c='Cartier');
      insert p;
      RICSC_Transaction__c tr = new RICSC_Transaction__c(RICSC_Account__c = masterRecord.Id, RICSC_AmountWithTaxEUR__c = 10000, RICSC_ProductName__c = p.Id, RICSC_TransactionDate__c = Date.today(),RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES);
      transactionsList.add(tr);
      RICSC_Activity__c act = new RICSC_Activity__c(RICSC_Account__c = masterRecord.Id, Name = 'Activity test '+masterRecord.Name);
      activitiesList.add(act);
      RICSC_Wishlist__c wsh = new RICSC_Wishlist__c(RICSC_Account__c = masterRecord.Id);
      wishlistsList.add(wsh);
      for(Account a : mergedRecordList){
        email = new RICSC_Email__c(RICSC_Account__c = a.Id);
        emailsList.add(email);
        smID = new RICSC_SocialMediaID__c(RICSC_Account__c = a.Id);
        smIDList.add(smId);
        phone = new RICSC_Phone__c(RICSC_Account__c = a.Id);
        phonesList.add(phone);
        address = new RICSC_Address__c(RICSC_Account__c = a.Id);
        addressList.add(address);
        tr = new RICSC_Transaction__c(RICSC_Account__c = a.Id, RICSC_AmountWithTaxEUR__c = 60000, RICSC_ProductName__c = p.Id, RICSC_TransactionDate__c = Date.today(),RICSC_TransactionCategory__c=UtilityConstants.TRANSACTION_TYPE_SALES);
        transactionsList.add(tr);
        act = new RICSC_Activity__c(RICSC_Account__c = a.Id, Name = 'Activity test '+a.Name);
        activitiesList.add(act);
        wsh = new RICSC_Wishlist__c(RICSC_Account__c = a.Id);
        wishlistsList.add(wsh);
      }
      Database.insert(emailsList);
      Database.insert(smIDList);
      Database.insert(phonesList);
      Database.insert(addressList);
      Database.insert(transactionsList);
      Database.insert(activitiesList);
      Database.insert(wishlistsList);
    }

    @IsTest
    static void mergeTest(){
      Test.startTest();
      String query = Utility.getSOQLWithFieldsFilter('account', 'FirstName = \'Golden\' LIMIT 1', 'RICSC_MasterRecordScore__c', UtilityConstants.SOQLFieldsFilter.CREATABLE);
      SObject masterRecord = Database.query(query);
      query = Utility.getSOQLWithFieldsFilter('account', 'Name LIKE \'%Test%\'', 'RICSC_MasterRecordScore__c', UtilityConstants.SOQLFieldsFilter.CREATABLE);
      //Map<Id, Account> mergedRecordList = new Map<Id,Account>((List<Account>)Database.query(query));
      List<SObject> mergedRecordsList = Database.query(query);
      boolean exceptionThrown = false;
      try{
        MergeExtension.beforeMerge('001P', masterRecord, mergedRecordsList);
      }
      catch (dupcheck.dc3Exception.NoProcessException e){
        exceptionThrown = true;
      }
      System.assert(exceptionThrown, 'Exception not thrown');
      //UtilityAccount.goldenRecordManagement(masterRecord, mergedRecordList, null);
      Test.stopTest();
      masterRecord = [SELECT Id, RICSC_IsGoldenRecord__c, RICSC_HasLocalRecords__c, RICSC_GlobalSegment__c FROM Account WHERE Firstname = 'Golden' AND RICSC_HasLocalRecords__c = true LIMIT 1];
      List<Account> allAccounts = [SELECT Id, RICSC_CanBeContacted__c, RICSC_NotToBeGrouped__c FROM Account];
      System.debug('==> allAccounts: ' + allAccounts);
      Boolean canBeContacted = true;
      for(Account a : allAccounts){
        if(!a.RICSC_NotToBeGrouped__c && !a.RICSC_CanBeContacted__c){
          canBeContacted = false;
        }
      }
      System.assert((Boolean)masterRecord.get('RICSC_HasLocalRecords__c'), 'Master hasn\'t local records');
      System.assert((Boolean)masterRecord.get('RICSC_IsGoldenRecord__c'), 'Master isn\'t golden record');
      System.assert(masterRecord.get('RICSC_GlobalSegment__c') != null, 'GlobalSegment is null');
      Account notGroupedAcc = [SELECT Id, RICSC_IsGoldenRecord__c, RICSC_HasLocalRecords__c FROM Account WHERE RICSC_NotToBeGrouped__c = true];
      System.assert(!notGroupedAcc.RICSC_HasLocalRecords__c, 'Account not to be merged has been merged');
      System.assert(notGroupedAcc.RICSC_IsGoldenRecord__c, 'Account not to be merged has been merged');
      System.assert(canBeContacted, 'Error in consents propagation');
    }
}