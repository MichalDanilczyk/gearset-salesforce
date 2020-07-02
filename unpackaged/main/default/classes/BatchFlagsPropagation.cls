/************************************************************************************
* @author       Dimitrios Rakantas
* @date         1/Nov/2019
* @description  Batch for propagating the VIP and the High Jewellery Client flag from an account to it's
*               related objects.Also for VCA propagates the VIP from local accounts to golden one.
***************************************************************************************/

public class BatchFlagsPropagation implements
  Database.Batchable < sObject >, Schedulable {
  public static final Integer MAX_SCOPE = 100;
  private Boolean skipTriggersOnAccount;
  private Set<String> recordTypes = UtilityConstants.PERSON_ACCOUNT_RT_SET_ID;
  private String query = 'SELECT Id, RICSC_RecomputeFlagsPropagation__c FROM Account WHERE RecordTypeId IN :recordTypes';

  public BatchFlagsPropagation(Boolean skipParam, String queryStr) {
        this.query = queryStr == null ? this.query : queryStr;
        skipTriggersOnAccount = skipParam;
  }

  public void execute(SchedulableContext sc) {
    BatchFlagsPropagation b = new BatchFlagsPropagation(false,null);
    Database.executeBatch(b, MAX_SCOPE);
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    return Database.getQueryLocator(this.query);
  }
  public void execute(Database.BatchableContext bc, List<Account> scope)  {
    List<Account> accList = [SELECT Id,RICSC_GoldenRecord__c,RICSC_VIP__c,RecordTypeId,RICSC_HighJewelleryClient__c,RICSC_CountryOfOrigin__c,RICSC_IsGoldenRecord__c,
                            (SELECT RICSC_HighJewelleryClient__c FROM Cases),
                            (SELECT RICSC_HighJewelleryClient__c,RICSC_VIP__c FROM RICSC_ActivitiesAccount__r),
                            (SELECT RICSC_HighJewelleryClient__c FROM RICSC_AddressesAccount__r),
                            (SELECT RICSC_HighJewelleryClient__c,RICSC_VIP__c FROM RICSC_EmailsAccount__r ),
                            (SELECT RICSC_HighJewelleryClient__c FROM RICSC_PhonesAccount__r),
                            (SELECT RICSC_HighJewelleryClient__c,RICSC_VIP__c FROM Assets),
                            (SELECT RICSC_HighJewelleryClient__c FROM RICSC_RelationsAccount__r),
                            (SELECT RICSC_HighJewelleryClient__c,RICSC_VIP__c FROM RICSC_SocialMediaIDsAccount__r),
                            (SELECT RICSC_HighJewelleryClient__c FROM RICSC_TransactionsAccount__r),
                            (SELECT RICSC_HighJewelleryClient__c FROM RICSC_WishlistsAccount__r) FROM Account WHERE Id IN :scope];

    List<Case> listCases = new List<Case>();
    List<RICSC_Activity__c> listActivitiesAccount = new List<RICSC_Activity__c>();
    List<RICSC_Address__c> listAddressesAccount = new List<RICSC_Address__c>();
    List<RICSC_Email__c> listEmailsAccount = new List<RICSC_Email__c>();
    List<RICSC_Phone__c> listPhonesAccount = new List<RICSC_Phone__c>();
    List<Asset> listAssets = new List<Asset>();
    List<RICSC_Relation__c> listRelationsAccount = new List<RICSC_Relation__c>();
    List<RICSC_SocialMediaID__c> listSocialMediaIDsAccount = new List<RICSC_SocialMediaID__c>();
    List<RICSC_Transaction__c> listTransactionsAccount = new List<RICSC_Transaction__c>();
    List<RICSC_Wishlist__c> listWishlistsAccount = new List<RICSC_Wishlist__c>();
    List<Account> listOfAccount = new List<Account>();

    Set<Id> goldenRecordIds = new Set<Id>();
    for(Account acc : accList){
      if(acc.RICSC_GoldenRecord__c != null && acc.RecordTypeId == RecordTypeHelper.getRTId('Account',UtilityConstants.PERSON_ACCOUNT_VCA_RT)){
        goldenRecordIds.add(acc.RICSC_GoldenRecord__c);
      }
    }

    List<Account> goldenWithRelatedRecords = [SELECT Id,RICSC_Turnover__c,RICSC_ClientFlag__c,(SELECT RICSC_VIP__c FROM RICSC_AccountGoldenRecord__r) FROM Account WHERE Id IN : goldenRecordIds];

    for(Account goldenRecord : goldenWithRelatedRecords){
      Boolean hasVipChilds = false;
      for(Account relatedLocal : goldenRecord.RICSC_AccountGoldenRecord__r){
        if(relatedLocal.RICSC_VIP__c == true){
          hasVipChilds = true;
          break;
        }
      }

      if(hasVipChilds == true){
        goldenRecord.RICSC_VIP__c = true;
      }
      else if((goldenRecord.RICSC_Turnover__c < 200000 && !UtilityConstants.CLIENT_FLAG_VIP_SET.contains(goldenRecord.RICSC_ClientFlag__c))){
        goldenRecord.RICSC_VIP__c = false;
      }
      listOfAccount.add(goldenRecord);
    }

    for(Account acc : accList){
      if(acc.Cases != null){
        listCases.addAll((List<Case>)updateRelatedObjects(acc,acc.Cases));
      }

      if(acc.RICSC_ActivitiesAccount__r != null){
        listActivitiesAccount.addAll((List<RICSC_Activity__c>)updateRelatedObjects(acc,acc.RICSC_ActivitiesAccount__r));
      }

      if(acc.RICSC_AddressesAccount__r != null){
        listAddressesAccount.addAll((List<RICSC_Address__c>)updateRelatedObjects(acc,acc.RICSC_AddressesAccount__r));
      }

      if(acc.RICSC_EmailsAccount__r != null){
        listEmailsAccount.addAll((List<RICSC_Email__c>)updateRelatedObjects(acc,acc.RICSC_EmailsAccount__r));
      }

      if(acc.RICSC_PhonesAccount__r != null){
        listPhonesAccount.addAll((List<RICSC_Phone__c>)updateRelatedObjects(acc,acc.RICSC_PhonesAccount__r));
      }

      if(acc.Assets != null){
        listAssets.addAll((List<Asset>)updateRelatedObjects(acc,acc.Assets));
      }

      if(acc.RICSC_RelationsAccount__r != null){
        listRelationsAccount.addAll((List<RICSC_Relation__c>)updateRelatedObjects(acc,acc.RICSC_RelationsAccount__r));
      }

      if(acc.RICSC_SocialMediaIDsAccount__r != null){
        listSocialMediaIDsAccount.addAll((List<RICSC_SocialMediaID__c>)updateRelatedObjects(acc,acc.RICSC_SocialMediaIDsAccount__r));
      }

      if(acc.RICSC_TransactionsAccount__r != null){
        listTransactionsAccount.addAll((List<RICSC_Transaction__c>)updateRelatedObjects(acc,acc.RICSC_TransactionsAccount__r));
      }

      if(acc.RICSC_WishlistsAccount__r != null){
        listWishlistsAccount.addAll((List<RICSC_Wishlist__c>)updateRelatedObjects(acc,acc.RICSC_WishlistsAccount__r));
      }
    }

    if(skipTriggersOnAccount){
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_SocialMediaID__c',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Phone__c',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Activity__c',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Address__c',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Email__c',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Relation__c',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Wishlist__c',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('Case',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('Asset',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Transaction__c',true);
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
    }

    Database.SaveResult[] srListA = Database.update(listCases,false);
    UtilityLogger.logAllErrors(srListA, false, 'BatchVFlagPropagation-Cases','execute');

    Database.SaveResult[] srListB = Database.update(listActivitiesAccount,false);
    UtilityLogger.logAllErrors(srListB, false, 'BatchVFlagPropagation-Activities','execute');

    Database.SaveResult[] srListC = Database.update(listAddressesAccount,false);
    UtilityLogger.logAllErrors(srListC, false, 'BatchVFlagPropagation-Addresses','execute');

    Database.SaveResult[] srListD = Database.update(listEmailsAccount,false);
    UtilityLogger.logAllErrors(srListD, false, 'BatchVFlagPropagation-Emails','execute');

    Database.SaveResult[] srListE = Database.update(listPhonesAccount,false);
    UtilityLogger.logAllErrors(srListE, false, 'BatchVFlagPropagation-Phones','execute');

    Database.SaveResult[] srListF = Database.update(listAssets,false);
    UtilityLogger.logAllErrors(srListF, false, 'BatchVFlagPropagation-Assets','execute');

    Database.SaveResult[] srListG = Database.update(listRelationsAccount,false);
    UtilityLogger.logAllErrors(srListG, false, 'BatchVFlagPropagation-Relations','execute');

    Database.SaveResult[] srListH = Database.update(listSocialMediaIDsAccount,false);
    UtilityLogger.logAllErrors(srListH, false, 'BatchVFlagPropagation-SocialMediaId','execute');

    Database.SaveResult[] srListI = Database.update(listTransactionsAccount,false);
    UtilityLogger.logAllErrors(srListI, false, 'BatchVFlagPropagation-Transactions','execute');

    Database.SaveResult[] srListJ = Database.update(listWishlistsAccount,false);
    UtilityLogger.logAllErrors(srListJ, false, 'BatchVFlagPropagation-WishList','execute');

    if(listOfAccount.size()>0){
      Database.SaveResult[] srListL = Database.update(listOfAccount,false);
      UtilityLogger.logAllErrors(srListL, false, 'BatchVFlagPropagation-Accounts','execute');
    }

    if(skipTriggersOnAccount){
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_SocialMediaID__c',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Phone__c',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Activity__c',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Address__c',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Email__c',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Relation__c',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Wishlist__c',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('Case',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('Asset',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('RICSC_Transaction__c',false);
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
    }

    //reset recompute flag on processed account if it is set
    List<Account> resetFlagList = new List<Account>();
    for(Account acc : scope){
      if(acc.RICSC_RecomputeFlagsPropagation__c){
        acc.RICSC_RecomputeFlagsPropagation__c = false;
        resetFlagList.add(acc);
        //to be improved here: only reset to false if the account hasn't been updated in the meanwhile from another process
        //and there was any error involving related objects of this account in this batch
      }
    }

    if(resetFlagList.size()>0){
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
      update resetFlagList;
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
    }

  }
  public void finish(Database.BatchableContext bc){

  }

  public static List<SObject> updateRelatedObjects(Account acc, List<SObject> involvedRecords){
    List<SObject> objToUpdate = new List<SObject>();
    for(SObject obj : involvedRecords){
      obj.put('RICSC_HighJewelleryClient__c', acc.RICSC_HighJewelleryClient__c);
      obj.put('RICSC_VIP__c', acc.RICSC_VIP__c);
      if(obj.getSObjectType()!= Schema.RICSC_Transaction__c.getSObjectType() && obj.getSObjectType()!= Schema.Asset.getSObjectType() && obj.getSObjectType()!= Schema.Case.getSObjectType()){
        obj.put('RICSC_CountryOfOrigin__c',acc.RICSC_CountryOfOrigin__c);
      }
      objToUpdate.add(obj);
    }
    return objToUpdate;
  }
}