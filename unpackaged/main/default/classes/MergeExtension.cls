global class MergeExtension implements dupcheck.dc3Plugin.InterfaceMerge {

  global static void beforeMerge(String objectPrefix, Sobject masterRecord, List < sobject > mergedRecordList) {
    System.debug('==> beforeMerge');
    if(objectPrefix.equalsIgnoreCase('001P')){
      System.debug('==> object prefix match');
      Set<Id> mergedRecordsIds = new Set<Id>();
      for(SObject mergeRecord : mergedRecordList) {
          mergedRecordsIds.add(mergeRecord.Id);
      }
      Set<Id> mergedIdsAndMaster = new Set<Id>(mergedRecordsIds);
      mergedIdsAndMaster.add(masterRecord.Id);
      if(!UtilityAccount.falseDuplicatesInSet(mergedIdsAndMaster)){
        String query = Utility.getSOQLWithFieldsFilter('account', '(Id IN :mergedIdsAndMaster OR RICSC_GoldenRecord__c IN :mergedRecordsIds) AND RICSC_NotToBeGrouped__c = false', null, UtilityConstants.SOQLFieldsFilter.ALL);
        Map<Id, Account> mergedAccounts = new Map<Id,Account>((List<Account>)Database.query(query));
        if(mergedAccounts.size() > 1){
          Map<Id, List<SObject>> relatedObjectsMap = UtilityAccount.getAccountsRelatedObjects(mergedAccounts.keySet());
          if(mergedAccounts.get(masterRecord.Id) == null){
            Decimal higherMasterRecordScore;
            for(Account acc: mergedAccounts.values()){
              if(higherMasterRecordScore == null || acc.RICSC_MasterRecordScore__c > higherMasterRecordScore){
                masterRecord = acc;
                higherMasterRecordScore = acc.RICSC_MasterRecordScore__c;
              }
            }
          }
          UtilityAccount.goldenRecordManagement((Account)masterRecord, mergedAccounts, null, relatedObjectsMap);
        }
      }
      throw new dupcheck.dc3Exception.NoProcessException('NO_MERGE');
    }
  }

  global void mergeFailed(String objectPrefix, Sobject masterRecord, Set < id > mergedRecordsIds, dupcheck.dc3Exception.MergeException exceptionData) {
    System.debug('==> merge Failed');
    return;
  }

  global void afterMerge(String objectPrefix, Sobject masterRecord, Set < id > mergedRecordIds) {
    System.debug('==> After merge');
  }

}