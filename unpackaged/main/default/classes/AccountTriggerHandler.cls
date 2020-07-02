/******************************************************************************
 * @author       Piergiorgio Lisanti
 * @date         22/Aug/2019
 * @description  This is a container of all trigger classes on Account object used within the trigger framework.
 ******************************************************************************/
public with sharing class AccountTriggerHandler {


 /******************************************************************************
  * @author       Silvan Sholla
  * @date         13/Sep/2019
  * @description  This class contains c/d sharing rulles for RICSC_Email__c
  * RICSC_Phone__c,RICSC_SocialMediaId__c And RICSC_Transaction__c Objects
  ******************************************************************************/

public without sharing class VCARecordSharing implements TRG_TriggerHandlerInterface {
  public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

    Set<Id> accountsThatChanged = changeHasBeenMade(td.oldMap,td.newList);
    if(accountsThatChanged.size() == 0){
    return;
    }


    String accessLvl = 'read';
    Map < Id, String > getCountryByContactId = getCountryByContactId(accountsThatChanged);
    Map < String, Id > getGroupIdByDeveloperName = Utility.getGroupIdByDeveloperName();
    Map < String, String > getRoleByCountryName = Utility.getRoleByCountryName();

    //all records per object
    List < RICSC_Email__c > emailList = new  List < RICSC_Email__c >();
    if (Schema.sObjectType.RICSC_Email__c.isAccessible()) {
      emailList = [SELECT Id, RICSC_Account__c,RICSC_GR__c FROM RICSC_Email__c WHERE RICSC_Account__c IN :accountsThatChanged OR RICSC_GR__c IN :accountsThatChanged];
    }
    List < RICSC_SocialMediaID__c > socialMediaList = new List < RICSC_SocialMediaID__c >();
    if (Schema.sObjectType.RICSC_SocialMediaID__c.isAccessible()){
      socialMediaList = [SELECT Id, RICSC_Account__c,RICSC_GR__c FROM RICSC_SocialMediaID__c WHERE RICSC_Account__c IN :accountsThatChanged OR RICSC_GR__c IN :accountsThatChanged];
    }
    List < RICSC_Phone__c > phoneList = new List < RICSC_Phone__c >();
    if (Schema.sObjectType.RICSC_Phone__c.isAccessible()){
      phoneList = [SELECT Id, RICSC_Account__c,RICSC_GR__c  FROM RICSC_Phone__c WHERE RICSC_Account__c IN :accountsThatChanged OR RICSC_GR__c IN :accountsThatChanged];
    }
    List < RICSC_Address__c> addressesList = new List < RICSC_Address__c>();
    if (Schema.sObjectType.RICSC_Address__c.isAccessible()){
      addressesList = [SELECT Id, RICSC_Account__c,RICSC_GR__c FROM RICSC_Address__c WHERE RICSC_Account__c IN :accountsThatChanged OR RICSC_GR__c IN :accountsThatChanged];
    }
    List < RICSC_Transaction__c > transactionList = new List < RICSC_Transaction__c >();
    if (Schema.sObjectType.RICSC_Transaction__c.isAccessible()){
      transactionList = [SELECT Id, RICSC_Account__c, RICSC_CountryOfOrigin__c,RICSC_GoldenRecord__c  FROM RICSC_Transaction__c WHERE RICSC_Account__c IN :accountsThatChanged OR RICSC_GoldenRecord__c IN :accountsThatChanged];
    }
    //lists with the records that has to get sharing rules
    Set < SObject > sharingRecordsToBeAdded = new Set < SObject >();
    List < SObject > sharingRecordsToBeDeleted = new List < SObject >();

    //set of ids of rules that has to get deleted | Local Sharing Records
    Set < Id > emailShareRemoveList = new Set < Id > ();
    Set < Id > socialMediaShareRemoveList = new Set < Id > ();
    Set < Id > phoneShareRemoveList = new Set < Id > ();
    Set < Id > addressShareRemoveList = new Set < Id > ();
    Set < Id > transactionShareRemoveList = new Set < Id > ();

    //set of ids of rules that has to get deleted | Golden Sharing Records
    Set < Id > emailShareRemoveGoldenList = new Set < Id > ();
    Set < Id > socialMediaShareRemoveGoldenList = new Set < Id > ();
    Set < Id > phoneShareRemoveGoldenList = new Set < Id > ();
    Set < Id > addressShareRemoveGoldenList = new Set < Id > ();
    Set < Id > transactionShareRemoveGoldenList = new Set < Id > ();

    for (Account acc:(List<Account>)td.newList) {

    String countryOfOrigin = getCountryByContactId.get(acc.RICSC_ReferenceSA__c);

    if (RecordTypeHelper.getRTId('Account', UtilityConstants.PERSON_ACCOUNT_VCA_RT) == acc.RecordTypeId &&
      acc.RICSC_VIP__c == true &&
      td.oldMap.get(acc.Id).get('RICSC_ReferenceSA__c') != acc.RICSC_ReferenceSA__c) {


      if((td.oldMap.get(acc.Id).get('RICSC_ReferenceSA__c') != null && getCountryByContactId.get(td.oldMap.get(acc.Id).get('RICSC_ReferenceSA__c').toString()) != getCountryByContactId.get(acc.RICSC_ReferenceSA__c)) ||
          td.oldMap.get(acc.Id).get('RICSC_ReferenceSA__c') == null && acc.RICSC_ReferenceSA__c != null) {

        if((acc.RICSC_HasLocalRecords__c == false && acc.RICSC_IsGoldenRecord__c == true) ||
          (acc.RICSC_HasLocalRecords__c == false && acc.RICSC_IsGoldenRecord__c == false)){
            emailShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(emailList, acc,'RICSC_GR__c'));
            socialMediaShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(socialMediaList, acc,'RICSC_GR__c'));
            phoneShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(phoneList, acc,'RICSC_GR__c'));
            addressShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(addressesList, acc,'RICSC_GR__c'));
            transactionShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(transactionList, acc,'RICSC_GoldenRecord__c'));
        }else{
            emailShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(emailList, acc,'RICSC_GR__c'));
            socialMediaShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(socialMediaList, acc,'RICSC_GR__c'));
            phoneShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(phoneList, acc,'RICSC_GR__c'));
            addressShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(addressesList, acc,'RICSC_GR__c'));
            transactionShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(transactionList, acc,'RICSC_GoldenRecord__c'));
        }

        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(emailList, acc, accessLvl, countryOfOrigin, 'RICSC_Email__share', getGroupIdByDeveloperName,getRoleByCountryName));
        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(socialMediaList, acc, accessLvl, countryOfOrigin, 'RICSC_SocialMediaID__share', getGroupIdByDeveloperName,getRoleByCountryName));
        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(phoneList, acc, accessLvl, countryOfOrigin, 'RICSC_Phone__share', getGroupIdByDeveloperName,getRoleByCountryName));
        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(addressesList, acc, accessLvl, countryOfOrigin, 'RICSC_Address__share', getGroupIdByDeveloperName,getRoleByCountryName));
        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(transactionList, acc, accessLvl, countryOfOrigin, 'RICSC_Transaction__share', getGroupIdByDeveloperName,getRoleByCountryName));
      }
    } else if (RecordTypeHelper.getRTId('Account', UtilityConstants.PERSON_ACCOUNT_VCA_RT) == acc.RecordTypeId &&
    acc.RICSC_VIP__c == false &&
    td.oldMap.get(acc.Id).get('RICSC_VIP__c') != acc.RICSC_VIP__c) {

    if((acc.RICSC_HasLocalRecords__c == false && acc.RICSC_IsGoldenRecord__c == true) ||
      (acc.RICSC_HasLocalRecords__c == false && acc.RICSC_IsGoldenRecord__c == false)){
        emailShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(emailList, acc,'RICSC_GR__c'));
        socialMediaShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(socialMediaList, acc,'RICSC_GR__c'));
        phoneShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(phoneList, acc,'RICSC_GR__c'));
        addressShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(addressesList, acc,'RICSC_GR__c'));
        transactionShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(transactionList, acc,'RICSC_GoldenRecord__c'));
    }else{
        emailShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(emailList, acc,'RICSC_GR__c'));
        socialMediaShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(socialMediaList, acc,'RICSC_GR__c'));
        phoneShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(phoneList, acc,'RICSC_GR__c'));
        addressShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(addressesList, acc,'RICSC_GR__c'));
        transactionShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(transactionList, acc,'RICSC_GoldenRecord__c'));
    }

    } else if (RecordTypeHelper.getRTId('Account', UtilityConstants.PERSON_ACCOUNT_VCA_RT) == acc.RecordTypeId &&
    acc.RICSC_VIP__c == true &&
    td.oldMap.get(acc.Id).get('RICSC_VIP__c') != acc.RICSC_VIP__c) {
        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(emailList, acc, accessLvl, countryOfOrigin, 'RICSC_Email__share', getGroupIdByDeveloperName,getRoleByCountryName));
        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(socialMediaList, acc, accessLvl, countryOfOrigin, 'RICSC_SocialMediaID__share', getGroupIdByDeveloperName,getRoleByCountryName));
        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(phoneList, acc, accessLvl, countryOfOrigin, 'RICSC_Phone__share', getGroupIdByDeveloperName,getRoleByCountryName));
        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(addressesList, acc, accessLvl, countryOfOrigin, 'RICSC_Address__share', getGroupIdByDeveloperName,getRoleByCountryName));
        sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(transactionList, acc, accessLvl, countryOfOrigin, 'RICSC_Transaction__share', getGroupIdByDeveloperName,getRoleByCountryName));
      }
    }

    if (emailShareRemoveList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_Email__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD AND ParentId IN: emailShareRemoveList]);
    }
    if (socialMediaShareRemoveList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_SocialMediaID__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD AND ParentId IN: socialMediaShareRemoveList]);
    }
    if (phoneShareRemoveList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_Phone__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD AND ParentId IN: phoneShareRemoveList]);
    }
    if (addressShareRemoveList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_Address__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD AND ParentId IN: addressShareRemoveList]);
    }
    if (transactionShareRemoveList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_Transaction__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD AND ParentId IN: transactionShareRemoveList]);
    }
    if (emailShareRemoveGoldenList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_Email__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD AND ParentId IN: emailShareRemoveGoldenList]);
    }
    if (socialMediaShareRemoveGoldenList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_SocialMediaID__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD AND ParentId IN: socialMediaShareRemoveGoldenList]);
    }
    if (phoneShareRemoveGoldenList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_Phone__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD AND ParentId IN: phoneShareRemoveGoldenList]);
    }
    if (addressShareRemoveGoldenList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_Address__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD AND ParentId IN: addressShareRemoveGoldenList]);
    }
    if (transactionShareRemoveGoldenList.size() != 0) {
      sharingRecordsToBeDeleted.addAll([SELECT Id FROM RICSC_Transaction__share WHERE RowCause =: UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD AND ParentId IN: transactionShareRemoveGoldenList]);
    }

    List<sObject> listToBeUpdated = new List<sObject>(sharingRecordsToBeAdded);
    Database.SaveResult[] srUpdateList = Database.insert(listToBeUpdated,false);
    for (Database.SaveResult sr : srUpdateList) {
      if (!sr.isSuccess()) {
        for(Database.Error e : sr.getErrors()) {
          UtilityLogger.loginfo(e.getMessage(),UtilityLogger.LOG_LEVEL_ERROR,'AccountTriggerHandler.VCARecordSharing','runTriggerHandler');
        }
      }
    }

    Database.DeleteResult[] drList = Database.delete(sharingRecordsToBeDeleted,false);
    // Iterate through each returned result
    for(Database.DeleteResult dr : drList) {
      if (!dr.isSuccess()) {
        for(Database.Error e : dr.getErrors()) {
          UtilityLogger.loginfo(e.getMessage(),UtilityLogger.LOG_LEVEL_ERROR,'AccountTriggerHandler.VCARecordSharing','runTriggerHandler');
        }
      }
    }
  }

  private Map < Id, String > getCountryByContactId(Set<Id> accIdsThatChanged) {
    Map < Id, String > countryByContactId = new Map < Id, String > ();
    for(Account cntct: [Select id,RICSC_ReferenceSA__c,RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c FROM Account WHERE Id IN :accIdsThatChanged]){
      countryByContactId.put(cntct.RICSC_ReferenceSA__c, cntct.RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c);
    }
    return countryByContactId;
  }

  private Set<Id> changeHasBeenMade(Map<Id,sObject> oldMap,List<sObject> newList){
   Set<Id> accountsThatChanged = new Set<Id>();
   for(Account acc : (List<Account>) newList){
    if(RecordTypeHelper.getRTId('Account', UtilityConstants.PERSON_ACCOUNT_VCA_RT) == acc.RecordTypeId &&
      (oldMap.get(acc.Id).get('RICSC_ReferenceSA__c') != acc.RICSC_ReferenceSA__c) || (oldMap.get(acc.Id).get('RICSC_VIP__c') != acc.RICSC_VIP__c)){
        accountsThatChanged.add(acc.Id);
      }
    }
    return accountsThatChanged;
  }
 }

  /******************************************************************************
  * @author       Silvan Sholla, Maurizio D'Antonio
  * @date         15/Oct/2019
  * @description  This class manages the propagation of the VIP flag on related
                  records via the 'RICSC_Account__c' lookup and (only for VCA)
                  from child to golden record.
  ******************************************************************************/
  public without sharing class VIPFlagPropagation implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Map<Id, Account> accountsThatChanged = checkVipFlagUpdated(td.oldMap,td.newList);

      Set<Id> goldenRecordIds = new Set<Id>();
      for(Account acc : accountsThatChanged.values()){
        if(acc.RICSC_GoldenRecord__c != null && acc.RecordTypeId == RecordTypeHelper.getRTId('Account',UtilityConstants.PERSON_ACCOUNT_VCA_RT)){
          goldenRecordIds.add(acc.RICSC_GoldenRecord__c);
        }
      }

      if(accountsThatChanged.size() > 0 ){
        if(!Utility.isAsync()){
          List<RICSC_Activity__c> activityList = [SELECT Id, RICSC_VIP__C,RICSC_Account__c FROM RICSC_Activity__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(activityList.size()>0){
            ID activityJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,activityList,'RICSC_VIP__c'));
          }

          List<RICSC_Address__c> addressList = [SELECT Id, RICSC_VIP__c,RICSC_Account__c FROM RICSC_Address__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(addressList.size()>0){
            ID addressJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,addressList,'RICSC_VIP__c'));
          }

          List<RICSC_Email__c> emailList = [SELECT Id, RICSC_VIP__c,RICSC_Account__c FROM RICSC_Email__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(emailList.size()>0){
            ID emailJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,emailList,'RICSC_VIP__c'));
          }

          List<RICSC_Phone__c> phoneList = [SELECT Id, RICSC_VIP__c,RICSC_Account__c FROM RICSC_Phone__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(phoneList.size()>0){
            ID phoneJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,phoneList,'RICSC_VIP__c'));
          }

          List<RICSC_SocialMediaID__c> socialMediaIdList = [SELECT Id, RICSC_VIP__c,RICSC_Account__c FROM RICSC_SocialMediaID__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(socialMediaIdList.size()>0){
            ID socialMediajobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,socialMediaIdList,'RICSC_VIP__c'));
          }

          List<RICSC_Relation__c> relationList = [SELECT Id, RICSC_VIP__c,RICSC_Account__c FROM RICSC_Relation__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(relationList.size()>0){
            ID relationJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,relationList,'RICSC_VIP__c'));
          }

          List<RICSC_Transaction__c> transactionList = [SELECT Id, RICSC_VIP__c,RICSC_Account__c FROM RICSC_Transaction__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(transactionList.size()>0){
            ID transactionJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,transactionList,'RICSC_VIP__c'));
          }

          List<Asset> assetList = [SELECT Id, RICSC_VIP__c,AccountId FROM Asset WHERE AccountId IN :accountsThatChanged.keySet()];
          if(assetList.size()>0){
            ID assetJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,assetList,'RICSC_VIP__c'));
          }

          List<Case> caseList = [SELECT Id, RICSC_VIP__c,AccountId FROM Case WHERE AccountId IN :accountsThatChanged.keySet()];
          if(caseList.size()>0){
            ID caseJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,caseList,'RICSC_VIP__c'));
          }

          List<RICSC_Wishlist__c> whishList = [SELECT Id, RICSC_VIP__c,RICSC_Account__c FROM RICSC_Wishlist__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(whishList.size()>0){
            ID whishlistJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,whishList,'RICSC_VIP__c'));
          }

          if(goldenRecordIds.size()>0){
            ID accountJobID = System.enqueueJob(new QueueableClasses.VIPFlagPropagationOverGoldenRecordVCA(goldenRecordIds));
          }
        } else {
          //mark the account to recompute flags propagation asynchronously in a batch job
          AccountTriggerHandler.addToFlagsRecalculationQueue(accountsThatChanged.keySet());
        }
      }
    }

    private Map<Id, Account> checkVipFlagUpdated(Map<Id,sObject> oldMap,List<sObject> newList){
      Map<Id, Account> accountsThatChanged = new Map<Id, Account>();
      for(Account acc : (List<Account>) newList){
        if((oldMap.get(acc.Id).get('RICSC_VIP__c') != acc.RICSC_VIP__c || oldMap.get(acc.Id).get('RICSC_GoldenRecord__c') != acc.RICSC_GoldenRecord__c)){
          accountsThatChanged.put(acc.Id, acc);
        }
      }
      return accountsThatChanged;
    }
  }

  /******************************************************************************
  * @description  This class manages the propagation of the High Jewellery flag on related
                  records.
  ******************************************************************************/
  public without sharing class HighJewelleryFlagPropagation implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Map<Id, Account> accountsThatChanged = new Map<Id, Account>();

      for(Account acc : (List<Account>) td.newList){
        if(acc.RICSC_HighJewelleryClient__c != td.oldMap.get(acc.Id).get('RICSC_HighJewelleryClient__c')){
          accountsThatChanged.put(acc.Id,acc);
        }
      }

      if(accountsThatChanged.size() != 0){
        if(!Utility.isAsync()){
          List<RICSC_Activity__c> activityList = [SELECT Id, RICSC_Account__c FROM RICSC_Activity__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(activityList.size()>0){
            ID activityJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,activityList,'RICSC_HighJewelleryClient__c'));
          }

          List<RICSC_Address__c> addressList = [SELECT Id, RICSC_Account__c FROM RICSC_Address__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(addressList.size()>0){
            ID addressJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,addressList,'RICSC_HighJewelleryClient__c'));
          }

          List<RICSC_Email__c> emailList = [SELECT Id, RICSC_Account__c FROM RICSC_Email__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(emailList.size()>0){
            ID emailJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,emailList,'RICSC_HighJewelleryClient__c'));
          }

          List<RICSC_Phone__c> phoneList = [SELECT Id,RICSC_Account__c FROM RICSC_Phone__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(phoneList.size()>0){
            ID phoneJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,phoneList,'RICSC_HighJewelleryClient__c'));
          }

          List<RICSC_SocialMediaID__c> socialMediaIdList = [SELECT Id,RICSC_Account__c FROM RICSC_SocialMediaID__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(socialMediaIdList.size()>0){
            ID socialMediajobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,socialMediaIdList,'RICSC_HighJewelleryClient__c'));
          }

          List<RICSC_Relation__c> relationList = [SELECT Id,RICSC_Account__c FROM RICSC_Relation__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(relationList.size()>0){
            ID relationJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,relationList,'RICSC_HighJewelleryClient__c'));
          }

          List<RICSC_Transaction__c> transactionList = [SELECT Id,RICSC_Account__c FROM RICSC_Transaction__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(transactionList.size()>0){
            ID transactionJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,transactionList,'RICSC_HighJewelleryClient__c'));
          }

          List<Asset> assetList = [SELECT Id,AccountId FROM Asset WHERE AccountId IN :accountsThatChanged.keySet()];
          if(assetList.size()>0){
            ID assetJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,assetList,'RICSC_HighJewelleryClient__c'));
          }

          List<Case> caseList = [SELECT Id,AccountId FROM Case WHERE AccountId IN :accountsThatChanged.keySet()];
          if(caseList.size()>0){
            ID caseJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,caseList,'RICSC_HighJewelleryClient__c'));
          }

          List<RICSC_Wishlist__c> whishList = [SELECT Id,RICSC_Account__c FROM RICSC_Wishlist__c WHERE RICSC_Account__c IN :accountsThatChanged.keySet()];
          if(whishList.size()>0){
            ID whishlistJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(accountsThatChanged,whishList,'RICSC_HighJewelleryClient__c'));
          }
        } else {
          //mark the account to recompute flags propagation asynchronously in a batch job
          AccountTriggerHandler.addToFlagsRecalculationQueue(accountsThatChanged.keySet());
        }
      }
    }

    private void updateRelatedRecords (Account acc, Map<SObjectType, List<SObject>> type2records){
      List<SObject> objects = new List<SObject>();
      objects.addAll(acc.Cases);
      objects.addAll(acc.RICSC_ActivitiesAccount__r);
      objects.addAll(acc.RICSC_AddressesAccount__r);
      objects.addAll(acc.RICSC_EmailsAccount__r);
      objects.addAll(acc.RICSC_PhonesAccount__r);
      objects.addAll(acc.Assets);
      objects.addAll(acc.RICSC_RelationsAccount__r);
      objects.addAll(acc.RICSC_SocialMediaIDsAccount__r);
      objects.addAll(acc.RICSC_TransactionsAccount__r);
      objects.addAll(acc.RICSC_WishlistsAccount__r);

      for(SObject obj : objects){
        obj.put('RICSC_HighJewelleryClient__c', acc.RICSC_HighJewelleryClient__c);
        Utility.addRecordToMap(type2records, obj);
      }
    }
  }

  /******************************************************************************
  * @author       Dimitrios Rakantas
  * @date         12/Nov/2019
  * @description  Propagation of country of origin from acccunt record to related Objects
  *               (Activity,address,email,phone.social media,relation,wishlist).
  ******************************************************************************/
  public without sharing class PropagateCountryOfOriginOnRelatedObjects implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Map<Id, Account> involvedAccs = new Map<Id, Account>();
      List<SObject> objectsToUpdate = new List<SObject>();
      for (Account acc : (List<Account>)td.newList){
        if(td.isInsert && acc.RICSC_SourceCRM__c == UtilityConstants.SOURCE_CRM_SAP){
          involvedAccs.put(acc.id,acc);
        }
        else if(td.isUpdate){
          if((td.oldMap.get(acc.Id).get('RICSC_CountryOfOrigin__c') != acc.RICSC_CountryOfOrigin__c) && acc.RICSC_SourceCRM__c == UtilityConstants.SOURCE_CRM_SAP){
             involvedAccs.put(acc.id,acc);
          }
        }
      }

      if(involvedAccs.size() > 0){
        if(!Utility.isAsync()){
          List<RICSC_Activity__c> activityList = [SELECT Id, RICSC_CountryOfOrigin__c,RICSC_Account__c FROM RICSC_Activity__c WHERE RICSC_Account__c IN :involvedAccs.keySet()];
          if(activityList.size()>0){
            ID activityJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(involvedAccs,activityList,'RICSC_CountryOfOrigin__c'));
          }
          List<RICSC_Address__c> addressList = [SELECT Id, RICSC_CountryOfOrigin__c,RICSC_Account__c FROM RICSC_Address__c WHERE RICSC_Account__c IN :involvedAccs.keySet()];
          if(addressList.size()>0){
            ID addressJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(involvedAccs,addressList,'RICSC_CountryOfOrigin__c'));
          }

          List<RICSC_Email__c> emailList = [SELECT Id, RICSC_CountryOfOrigin__c,RICSC_Account__c FROM RICSC_Email__c WHERE RICSC_Account__c IN :involvedAccs.keySet()];
          if(emailList.size()>0){
            ID emailJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(involvedAccs,emailList,'RICSC_CountryOfOrigin__c'));
          }

          List<RICSC_Phone__c> phoneList = [SELECT Id, RICSC_CountryOfOrigin__c,RICSC_Account__c FROM RICSC_Phone__c WHERE RICSC_Account__c IN :involvedAccs.keySet()];
          if(phoneList.size()>0){
            ID phoneJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(involvedAccs,phoneList,'RICSC_CountryOfOrigin__c'));
          }

          List<RICSC_SocialMediaID__c> socialMediaIdList = [SELECT Id, RICSC_CountryOfOrigin__c,RICSC_Account__c FROM RICSC_SocialMediaID__c WHERE RICSC_Account__c IN :involvedAccs.keySet()];
          if(socialMediaIdList.size()>0){
            ID socialMediajobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(involvedAccs,socialMediaIdList,'RICSC_CountryOfOrigin__c'));
          }

          List<RICSC_Relation__c> relationList = [SELECT Id, RICSC_CountryOfOrigin__c,RICSC_Account__c FROM RICSC_Relation__c WHERE RICSC_Account__c IN :involvedAccs.keySet()];
          if(relationList.size()>0){
            ID relationJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(involvedAccs,relationList,'RICSC_CountryOfOrigin__c'));
          }

          List<RICSC_Wishlist__c> whishList = [SELECT Id, RICSC_CountryOfOrigin__c,RICSC_Account__c FROM RICSC_Wishlist__c WHERE RICSC_Account__c IN :involvedAccs.keySet()];
          if(whishList.size()>0){
            ID whishlistJobID = System.enqueueJob(new QueueableClasses.FlagPropagationOverRelatedObjects(involvedAccs,whishList,'RICSC_CountryOfOrigin__c'));
          }
        } else {
          //mark the account to recompute flags propagation asynchronously in a batch job
          AccountTriggerHandler.addToFlagsRecalculationQueue(involvedAccs.keySet());
        }
      }
    }
  }

  public static void addToFlagsRecalculationQueue(Set<Id> recalculationListIds){
    List<Account> recalculationList = new List<Account>();
    for(Id accId : recalculationListIds){
      Account a = new Account();
      a.put('Id', accId);
      a.put('RICSC_RecomputeFlagsPropagation__c', true);
      recalculationList.add(a);
    }
    Boolean alreadySkippingTriggers = false;
    if(TRG_TriggerDispatcher.skipTriggerMap != null && TRG_TriggerDispatcher.skipTriggerMap.containsKey('Account') && TRG_TriggerDispatcher.skipTriggerMap.get('Account') == true){
      alreadySkippingTriggers = true;
    }
    TRG_TriggerDispatcher.skipTriggerMap.put('Account',true);
    update recalculationList;
    if(!alreadySkippingTriggers){
      TRG_TriggerDispatcher.skipTriggerMap.put('Account',false);
    }
  }

  /******************************************************************************
  * @author       Silvan Sholla
  * @date         15/Oct/2019
  * @description  This class contains trigger logic fired when accounts are inserted/modified/deleted.
  *               It computes calculated fields on Account records for the following fields:
  *               - Notes, Spot Notes, Product of Interest, Collection of Interest, Hobbies concat fields
  *               - LocalVip and E-cards checkbox fields
  *               - Vip flag
  *               - Reference Boutique for VCA
  ******************************************************************************/
  public without sharing class CalculatingFields implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Set<Id> involvedAccIds = new Set<Id>();
      Set<Account> vipAccs = new Set<Account>();

      List<Account> trgLst = td.IsDelete ? (List<Account>) td.oldList : (List<Account>) td.newList;

      for(Account ac : trgLst){
          if(td.isInsert){
            if(ac.RICSC_GoldenRecord__c != null){
              involvedAccIds.add(ac.RICSC_GoldenRecord__c);
            }
            if (ac.RICSC_Turnover__c != null || ac.RICSC_ClientFlag__c != null || ac.RICSC_GlobalSegment__c != null){
                vipAccs.add(ac);
            }
          } else if(td.isUpdate){
              if(ac.RICSC_GoldenRecord__c != td.oldMap.get(ac.Id).get('RICSC_GoldenRecord__c') ||
                    ac.RICSC_Notes__c != td.oldMap.get(ac.Id).get('RICSC_Notes__c') ||
                    ac.RICSC_SpotNotes__c != td.oldMap.get(ac.Id).get('RICSC_SpotNotes__c') ||
                    ac.RICSC_ECard__c != td.oldMap.get(ac.Id).get('RICSC_ECard__c') ||
                    ac.RICSC_ProductOfInterests__c != td.oldMap.get(ac.Id).get('RICSC_ProductOfInterests__c') ||
                    ac.RICSC_Hobbies__c != td.oldMap.get(ac.Id).get('RICSC_Hobbies__c') ||
                    ac.RICSC_CollectionOfInterests__c != td.oldMap.get(ac.Id).get('RICSC_CollectionOfInterests__c') ||
                    ac.RICSC_VIP__c != td.oldMap.get(ac.Id).get('RICSC_VIP__c')){

              if(ac.RICSC_GoldenRecord__c != null){
                involvedAccIds.add(ac.RICSC_GoldenRecord__c);
              }
              //lookup GR changed
              if(ac.RICSC_GoldenRecord__c != td.oldMap.get(ac.Id).get('RICSC_GoldenRecord__c') &&
                  td.oldMap.get(ac.Id).get('RICSC_GoldenRecord__c') != null){

                involvedAccIds.add(td.oldMap.get(ac.Id).get('RICSC_GoldenRecord__c').toString());
              }
            }

            if (ac.RICSC_Turnover__c != td.oldMap.get(ac.Id).get('RICSC_Turnover__c') ||
                  ac.RICSC_ClientFlag__c != td.oldMap.get(ac.Id).get('RICSC_ClientFlag__c') ||
                  ac.RICSC_GlobalSegment__c != td.oldMap.get(ac.Id).get('RICSC_GlobalSegment__c') &&
                  (ac.RICSC_Turnover__c != null || ac.RICSC_ClientFlag__c != null || ac.RICSC_GlobalSegment__c != null)){

                        vipAccs.add(ac);
            }
          } else if(td.isDelete && ac.RICSC_GoldenRecord__c != null){
            involvedAccIds.add(ac.RICSC_GoldenRecord__c);
          }
        }

        Map<Id,CalculatingFieldsHandler.CalculatedAccountFieldCont> calculatedValuesXAccountId = new Map <Id,CalculatingFieldsHandler.CalculatedAccountFieldCont>();

        if(involvedAccIds.size()>0){
          CalculatingFieldsHandler.computeConcatenatedFieldsOnGR(involvedAccIds,calculatedValuesXAccountId);
        }
        if(vipAccs.size()>0){
          CalculatingFieldsHandler.computeVipFlag(vipAccs,calculatedValuesXAccountId);
        }

        List<Account> accountsToUpdate = CalculatingFieldsHandler.getComputedAccounts(calculatedValuesXAccountId.values());
        if (Schema.sObjectType.Account.isUpdateable()){
          update accountsToUpdate;
        }
    }
  }

  /******************************************************************************
  * @author       Maurizio D'Antonio
  * @date         18/Oct/2019
  * @description  Management of manual linking of Account Record to Golden Record.
                  This trigger fires when user changes the lookup from an Account
                  record to a GR with a non-null value. The merge method is called
                  once for every golden record found for the accounts involved in
                  the trigger, whose ID is the key of mapGrToMergedAccounts map.
                  Values of this map are the accounts to be linked to the key GR.
                  At the end, the segment is recalculated in the old GRs (for the
                  new ones it is already done in the method).
  ******************************************************************************/

  public without sharing class GRManualLink implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Set<Id> accountIds = new Set<Id>();
      Set<Id> oldGRToRecalculateSegment = new Set<Id>();
      for(Account acc : (List<Account>)td.newList){
        if(acc.RICSC_GoldenRecord__c != null && td.oldMap.get(acc.Id).get('RICSC_GoldenRecord__c') != acc.RICSC_GoldenRecord__c && !acc.RICSC_NotToBeGrouped__c){
          if(td.oldMap.get(acc.Id).get('RICSC_GoldenRecord__c') != null){
            oldGRToRecalculateSegment.add((Id)td.oldMap.get(acc.Id).get('RICSC_GoldenRecord__c'));
          }
          accountIds.add(acc.RICSC_GoldenRecord__c);
          accountIds.add(acc.Id);
        }
        else if (acc.RICSC_GoldenRecord__c != null && td.oldMap.get(acc.Id).get('RICSC_GoldenRecord__c') != acc.RICSC_GoldenRecord__c && acc.RICSC_NotToBeGrouped__c){
          acc.addError(Label.Exception_CannotMergeAccount);
        }
      }

      if(accountIds.size() > 0){
        String query = Utility.getSOQLWithFieldsFilter('account', '(Id IN :accountIds OR RICSC_GoldenRecord__c IN :accountIds) AND RICSC_NotToBeGrouped__c = false', null, UtilityConstants.SOQLFieldsFilter.ALL);
        Map<Id, Account> accountMap = new Map<Id,Account>((List<Account>)Database.query(query));
        Map<Id, List<SObject>> relatedObjectsMap = UtilityAccount.getAccountsRelatedObjects(accountMap.keySet());
        Map<Id, List<Account>> mapGrToMergedAccounts = new Map<Id, List<Account>>();
        for(Account acc : (List<Account>)td.newList){
          if(acc.RICSC_GoldenRecord__c != null && td.oldMap.get(acc.Id).get('RICSC_GoldenRecord__c') != acc.RICSC_GoldenRecord__c){
            Account goldenRecord = accountMap.get(acc.RICSC_GoldenRecord__c);
            List<Account> mergedAccounts = new List<Account>();
            Account masterRecord;
            if(goldenRecord.RICSC_HasLocalRecords__c && goldenRecord.RICSC_MasterRecordScore__c < acc.RICSC_MasterRecordScore__c){
                masterRecord = acc;
                mergedAccounts.add(goldenRecord);
            }
            for(Account a : accountMap.values()){
              if(a.RICSC_GoldenRecord__c == goldenRecord.Id){
                mergedAccounts.add(a);
              }
            }
            if(masterRecord != null){
              mapGrToMergedAccounts.put(masterRecord.Id, mergedAccounts);
            }
            else{
              mapGrToMergedAccounts.put(goldenRecord.Id, mergedAccounts);
            }
          }
        }
        if(mapGrToMergedAccounts.size() > 0){
          for(Id accId : mapGrToMergedAccounts.keySet()){
            Account masterClone = (Account)accountMap.get(accId).clone(false, true, false, false);
            Account masterAccount = accountMap.get(accId);
            if(!Test.isRunningTest()){
              masterAccount = UtilityAccount.copyFieldsOnMasterFromLocals(masterAccount, new Map<Id, Account>(mapGrToMergedAccounts.get(accId)));
            }
            UtilityAccount.goldenRecordManagement(masterAccount, new Map<Id, Account>(mapGrToMergedAccounts.get(accId)), masterClone, relatedObjectsMap);
          }
          UtilityAccount.calculateSegment(oldGRToRecalculateSegment, true, false);
        }
      }
    }
  }
  /******************************************************************************
  * @author       Maurizio D'Antonio
  * @date         18/Oct/2019
  * @description  Management of manual unlinking of Account Record to Golden Record
  ******************************************************************************/

  public without sharing class GRManualUnlink implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Set<Id> accountIds = new Set<Id>();

      for(Account acc : (List<Account>)td.newList){
        if(acc.RICSC_GoldenRecord__c == null && td.oldMap.get(acc.Id).get('RICSC_GoldenRecord__c') != null){
          accountIds.add((Id)td.oldMap.get(acc.Id).get('RICSC_GoldenRecord__c'));
        }
      }

      if(accountIds.size() > 0){
        Set<Id> newIds = td.newMap.keySet();
        String query = Utility.getSOQLWithFieldsFilter('account', '(Id IN :accountIds OR Id IN :newIds OR RICSC_GoldenRecord__c IN :accountIds)', 'RICSC_HasLocalRecords__c, RICSC_GoldenRecord__c, RICSC_MasterRecordScore__c, RICSC_Externalid__c, RICSC_ClientID__c, RICSC_SWSEID__c, RICSC_MasterRecord__c, RICSC_ExternalID__pc, RICSC_ClientSegment__c, RICSC_HistoricalExternalID__c', UtilityConstants.SOQLFieldsFilter.GOLDENRECORD);
        Map<Id, Account> accountMap = new Map<Id,Account>((List<Account>)Database.query(query));
        Map<Id, List<SObject>> relatedObjectsMap = UtilityAccount.getAccountsRelatedObjects(accountMap.keySet());
        Map<Id, List<Account>> mapGrToRelatedRecords = new Map<Id, List<Account>>();
        for(Account acc : accountMap.values()){
          if(accountIds.contains(acc.Id) && !mapGrToRelatedRecords.containsKey(acc.Id)){
              mapGrToRelatedRecords.put(acc.Id, new List<Account>());
          }
          else if(!accountIds.contains(acc.Id)){
            Id goldenRecordId = acc.RICSC_GoldenRecord__c != null ? acc.RICSC_GoldenRecord__c : (Id)td.oldMap.get(acc.Id).get('RICSC_GoldenRecord__c');
            if (!mapGrToRelatedRecords.containsKey(goldenRecordId)){
              mapGrToRelatedRecords.put(goldenRecordId, new List<Account>());
            }
            List<Account> lrList = mapGrToRelatedRecords.get(goldenRecordId);
            lrList.add(acc);
            mapGrToRelatedRecords.put(goldenRecordId, lrList);
          }
        }
        List<Account> accountsToDelete = new List<Account>();
        Map<SObjectType, List<SObject>> type2records = new Map<SObjectType, List<SObject>>();
        Set<Id> grIDsForSegmentation = new Set<Id>();
        List<dupcheck__dcDiscard__c> dcDiscardList = new List<dupcheck__dcDiscard__c>();
        for(Id grID : mapGrToRelatedRecords.keySet()){
          Account goldenRecord = accountMap.get(grID);
          List<Account> lrList = mapGrToRelatedRecords.get(grId);
          if(lrList.size() <= 2){
            for(Account a : lrList){
              if(a.RICSC_MasterRecord__c){
                accountsToDelete.add(a);
                List<Schema.FieldSetMember> fields = Schema.SObjectType.Account.fieldSets.FieldsToCopyOnGR.getFields();
                List<String> fieldsToCopy = new List<String>();
                for(Schema.FieldSetMember m : fields){
                  fieldsToCopy.add(m.getFieldPath());
                }
                Map <String,Object> populatedFieldsMap = a.getPopulatedFieldsAsMap();
                for (String v : populatedFieldsMap.keySet()){
                  if(fieldsToCopy.contains(v)){
                    goldenRecord.put(v,populatedFieldsMap.get(v));
                  }
                }
                goldenRecord.RICSC_ClientID__c = a.RICSC_ClientID__c;
                goldenRecord.RICSC_SWSEID__c = a.RICSC_SWSEID__c;
                goldenRecord.RICSC_ExternalID__pc = a.RICSC_ExternalID__pc;
                goldenRecord.RICSC_Externalid__c = a.RICSC_Externalid__c;
                goldenRecord.RICSC_HistoricalExternalID__c = a.RICSC_HistoricalExternalID__c;
                goldenRecord.RICSC_HasLocalRecords__c = false;
                goldenRecord.RICSC_GlobalSegment__c = a.RICSC_ClientSegment__c;
                UtilityAccount.updateDeletedRecordRelatedObjects(a, goldenRecord.Id, goldenRecord.Id, type2records, relatedObjectsMap);
                Utility.addRecordToMap(type2Records, goldenRecord);
              }
              else{
                a.RICSC_IsGoldenRecord__c = true;
                a.RICSC_HasLocalRecords__c = false;
                a.RICSC_GoldenRecord__c = null;
                UtilityAccount.updateAccountRelatedObjects(a, null, a.Id, type2records, relatedObjectsMap);
                dupcheck__dcDiscard__c discardRecord = new dupcheck__dcDiscard__c(dupcheck__objectA__c = a.Id, dupcheck__objectB__c = goldenRecord.Id, dupcheck__recordA__c = a.Id, dupcheck__recordB__c=goldenRecord.Id, dupcheck__Relation__c = 'False Duplicate');
                dcDiscardList.add(discardRecord);
              }
            }
          }
          else{
            grIDsForSegmentation.add(goldenRecord.Id);
            for(Account a : lrList){
              if(td.oldMap.keySet().contains(a.Id)){
                a.RICSC_IsGoldenRecord__c = true;
                a.RICSC_HasLocalRecords__c = false;
                a.RICSC_GlobalSegment__c = a.RICSC_ClientSegment__c;
                UtilityAccount.updateAccountRelatedObjects(a, null, a.Id, type2records, relatedObjectsMap);
                dupcheck__dcDiscard__c discardRecord = new dupcheck__dcDiscard__c(dupcheck__objectA__c = a.Id, dupcheck__objectB__c = goldenRecord.Id, dupcheck__recordA__c = a.Id, dupcheck__recordB__c=goldenRecord.Id, dupcheck__Relation__c = 'False Duplicate');
                dcDiscardList.add(discardRecord);
              }
            }
          }
        }
        if(!accountsToDelete.isEmpty() && Schema.sObjectType.Account.isDeletable()){
          Database.delete(accountsToDelete);
        }
        List<SObject> recordsToUpdate = new List<SObject>();
        for(Integer i = 0; i < type2records.values().size(); i++) {
          recordsToUpdate.addAll(type2records.values()[i]);
        }
        if(!recordsToUpdate.isEmpty()) {
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualLink',true);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualUnlink',true);
          Database.update(recordsToUpdate);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualLink',false);
          TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.GRManualUnlink',false);
        }
        if(dcDiscardList.size() > 0 && Schema.sObjectType.dupcheck__dcDiscard__c.isCreateable()){
          Database.insert(dcDiscardList);
        }
        UtilityAccount.calculateSegment(GRIDsForSegmentation, true, false);
      }
    }
  }

  public without sharing class LocalisationPropagation implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      if(td.isInsert){
        for(Account acc : (List<Account>)td.newList){
          if(acc.RecordTypeId == RecordTypeHelper.getRTId('Account', UtilityConstants.ACCOUNTBOUTIQUE_RT) && acc.RICSC_CountryOfOrigin__c != null && acc.RICSC_Maison__c != null){
            acc.RICSC_Localisation__c = Utility.getLocalisationId(acc.RICSC_Maison__c, acc.RICSC_CountryOfOrigin__c);
          }
        }
      }

      if(td.isUpdate){
        for(Account acc : (List<Account>)td.newList){
          if(acc.RecordTypeId == RecordTypeHelper.getRTId('Account',UtilityConstants.ACCOUNTBOUTIQUE_RT) &&
            (acc.RICSC_CountryOfOrigin__c != td.oldMap.get(acc.Id).get('RICSC_CountryOfOrigin__c') || acc.RICSC_Maison__c != td.oldMap.get(acc.Id).get('RICSC_Maison__c'))){
            acc.RICSC_Localisation__c = Utility.getLocalisationId(acc.RICSC_Maison__c, acc.RICSC_CountryOfOrigin__c);
          }
        }
      }
    }
  }

  /******************************************************************************
  * @author       Maurizio D'Antonio
  * @date         31/Oct/2019
  * @description  Propagation of consents from local to golden record or from
                  golden to all local records.
  ******************************************************************************/
  public without sharing class PropagateConsentsOnRecords implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Map<Id, Account> mapSlaveToMasterRecord = new Map<Id, Account>();
      for(Account acc : (List<Account>)td.newList){
        Boolean consentIsChanged = consentIsChanged((Account)td.oldMap.get(acc.Id), acc);
        Boolean newTimestamp = newTimestamp((Account)td.oldMap.get(acc.Id), acc);
        if(consentIsChanged && !newTimestamp && td.isBefore){
          acc.RICSC_ConsentTimestamp__c = (Datetime)td.oldMap.get(acc.Id).get('RICSC_ConsentTimestamp__c');
          acc.RICSC_CanBeContacted__c = (Boolean)td.oldMap.get(acc.Id).get('RICSC_CanBeContacted__c');
          acc.RICSC_ElectronicContact__c = (Boolean)td.oldMap.get(acc.Id).get('RICSC_ElectronicContact__c');
          acc.RICSC_PostalContact__c = (Boolean)td.oldMap.get(acc.Id).get('RICSC_PostalContact__c');
          acc.RICSC_VoiceContact__c = (Boolean)td.oldMap.get(acc.Id).get('RICSC_VoiceContact__c');
        }
        if(consentIsChanged && newTimestamp && td.isAfter && (!acc.RICSC_IsGoldenRecord__c || acc.RICSC_HasLocalRecords__c)){
          mapSlaveToMasterRecord.put(acc.RICSC_HasLocalRecords__c ? acc.Id : acc.RICSC_GoldenRecord__c, acc);
        }
      }
      List<Account> slaveRecords = new List<Account>();
      if (Schema.sObjectType.Account.isUpdateable()) {
        if(mapSlaveToMasterRecord.size() > 0){
          slaveRecords = [SELECT Id, RICSC_GoldenRecord__c, RICSC_ConsentTimestamp__c, RICSC_CanBeContacted__c, RICSC_PostalContact__c, RICSC_ElectronicContact__c, RICSC_VoiceContact__c
                          FROM Account
                          WHERE (RICSC_GoldenRecord__c IN :mapSlaveToMasterRecord.keySet() OR Id IN :mapSlaveToMasterRecord.keySet())];
        }
      }
      List<Account> accountsToUpdate = new List<Account>();
      for(Account a : slaveRecords){
        Account master;
        if(mapSlaveToMasterRecord.containsKey(a.id)){
          master = mapSlaveToMasterRecord.get(a.Id);
        }
        else if(mapSlaveToMasterRecord.containsKey(a.RICSC_GoldenRecord__c)){
          master = mapSlaveToMasterRecord.get(a.RICSC_GoldenRecord__c);
        }
        accountsToUpdate.add(updateAccountConsents(master, a));
      }

      if(accountsToUpdate.size()>0){
        update accountsToUpdate;
      }
    }

    private Boolean consentIsChanged(Account oldAccount, Account newAccount){
      return (oldAccount.RICSC_CanBeContacted__c != newAccount.RICSC_CanBeContacted__c ||
                oldAccount.RICSC_PostalContact__c != newAccount.RICSC_PostalContact__c ||
                oldAccount.RICSC_ElectronicContact__c != newAccount.RICSC_ElectronicContact__c ||
                oldAccount.RICSC_VoiceContact__c != newAccount.RICSC_VoiceContact__c);
    }
    private Boolean newTimestamp(Account oldAccount, Account newAccount){
      return ((oldAccount.RICSC_ConsentTimestamp__c == null && newAccount.RICSC_ConsentTimestamp__c != null) ||
              (oldAccount.RICSC_ConsentTimestamp__c == null && newAccount.RICSC_ConsentTimestamp__c == null) ||
              (oldAccount.RICSC_ConsentTimestamp__c < newAccount.RICSC_ConsentTimestamp__c));
    }
    private Account updateAccountConsents(Account master, Account slave){
      if(master.RICSC_ConsentTimestamp__c != null){
        slave.RICSC_ConsentTimestamp__c = master.RICSC_ConsentTimestamp__c;
      }
      else{
        slave.RICSC_ConsentTimestamp__c = Datetime.now();
      }
      slave.RICSC_CanBeContacted__c = master.RICSC_CanBeContacted__c;
      slave.RICSC_ElectronicContact__c = master.RICSC_ElectronicContact__c;
      slave.RICSC_PostalContact__c = master.RICSC_PostalContact__c;
      slave.RICSC_VoiceContact__c = master.RICSC_VoiceContact__c;
      return slave;
    }
  }

  /******************************************************************************
  * @author       Silvan Sholla
  * @date         1/Nov/2019
  * @description  Class Code Calculation Based on the Transaction classes
  *               Trigger on before Update / Insert
  *               Trigger runs only for GR that have local records
  *               The GR-LocalRecords come froms the integration
  ******************************************************************************/

  public without sharing class ClassCodeCalculation implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      if(td.isInsert){
        for(Account acc : (List<Account>)td.newList){
          if(UtilityConstants.PERSON_ACCOUNT_RT_SET_ID.contains(acc.RecordTypeId) && acc.RICSC_IsGoldenRecord__c == true && acc.RICSC_HasLocalRecords__c == true){
            CalculatingFieldsHandler.calculateClassCode(acc);
          }
        }
      }
      if(td.isUpdate){
        for(Account acc : (List<Account>)td.newList){
          if((UtilityConstants.PERSON_ACCOUNT_RT_SET_ID.contains(acc.RecordTypeId)) &&
            (acc.RICSC_TransactionChannelsSelected__c != td.oldMap.get(acc.Id).get('RICSC_TransactionChannelsSelected__c') ||
            acc.RICSC_DataOrigin__c != td.oldMap.get(acc.Id).get('RICSC_DataOrigin__c') ||
            acc.RICSC_TotalNumberOfSales__c != td.oldMap.get(acc.Id).get('RICSC_TotalNumberOfSales__c') ||
            acc.RICSC_TotalNumberOfRepairs__c != td.oldMap.get(acc.Id).get('RICSC_TotalNumberOfRepairs__c')) && acc.RICSC_IsGoldenRecord__c == true && acc.RICSC_HasLocalRecords__c == true){
            CalculatingFieldsHandler.calculateClassCode(acc);
          }
        }
      }
    }
  }

  /******************************************************************************
  * @author       Maurizio D'Antonio
  * @date         04/Nov/2019
  * @description  Trigger to start automatic deduplication process for Account
                  with turnover higher than the threshold defined by maison.
  ******************************************************************************/
  public without sharing class AutomaticDeduplicationProcess implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      List<dupcheck__dcDelta__c> dcDeltas = new List<dupcheck__dcDelta__c>();
      for(Account acc : (List<Account>)td.newList){
        if(acc.RICSC_IsGoldenRecord__c && acc.RICSC_Turnover__c != null && acc.RICSC_Turnover__c != 0 &&
        (td.oldMap.get(acc.Id).get('RICSC_Turnover__c') == 0 ||
          td.oldMap.get(acc.Id).get('RICSC_Turnover__c') == null ||
          dcCombinedFieldsChanged(acc, (Account)td.oldMap.get(acc.Id)))){
          dupcheck__dcDelta__c dcDelta = new dupcheck__dcDelta__c(dupcheck__object__c = acc.Id, dupcheck__Priority__c = 1, dupcheck__Type__c = 'BULK_INSERT');
          dcDeltas.add(dcDelta);
        }
      }
      if(dcDeltas.size() > 0 && !Test.isRunningTest()){
        Database.insert(dcDeltas);
      }
    }

    private Boolean dcCombinedFieldsChanged(Account newAccount, Account oldAccount){
      return newAccount.RICSC_DC8DigitCombinedPhones__c != oldAccount.RICSC_DC8DigitCombinedPhones__c ||
            newAccount.RICSC_DCCombinedEmail__c != oldAccount.RICSC_DCCombinedEmail__c ||
            newAccount.RICSC_DCCombinedPhone__c != oldAccount.RICSC_DCCombinedPhone__c ||
            newAccount.RICSC_DCCombinedSocialID__c != oldAccount.RICSC_DCCombinedSocialID__c ||
            newAccount.RICSC_DCPostalCode__c != oldAccount.RICSC_DCPostalCode__c ||
            newAccount.RICSC_DCStreet__c != oldAccount.RICSC_DCStreet__c ||
            newAccount.RICSC_DCCity__c != oldAccount.RICSC_DCCity__c ||
            newAccount.RICSC_DCCountry__c != oldAccount.RICSC_DCCountry__c ||
            newAccount.RICSC_DCStreetNumber__c != oldAccount.RICSC_DCStreetNumber__c;
    }
  }

  /******************************************************************************
  * @author       Silvan Sholla
  * @date         13/Nov/2019
  * @description  Default Records based on MasterRecord score
  ******************************************************************************/

  public without sharing class defaultRecordsBasedOnMasterRecordScore implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Set<Id> involvedAccs = new Set<Id>();
      List<SObject> objectsToUpdate = new List<SObject>();
      for (Account acc : (List<Account>)td.newList){
        if(((td.oldMap.get(acc.Id).get('RICSC_MRScoreFrequency__c') != acc.RICSC_MRScoreFrequency__c) ||
            (td.oldMap.get(acc.Id).get('RICSC_MRScoreTurnover__c') != acc.RICSC_MRScoreTurnover__c) ||
            (td.oldMap.get(acc.Id).get('RICSC_GoldenRecord__c') != acc.RICSC_GoldenRecord__c)) && acc.RICSC_IsGoldenRecord__c == true){
          involvedAccs.add(acc.Id);
        }
      }

      if(involvedAccs.size()>0){
        if(!Utility.isAsync()){
          System.enqueueJob(new QueueableClasses.DefaultRecordCalculationForRelatedObjects('RICSC_Email__c','RICSC_EmailsGR__r',involvedAccs,'RICSC_DefaultEmail__c','RICSC_DefaultGREmail__c'));
          System.enqueueJob(new QueueableClasses.DefaultRecordCalculationForRelatedObjects('RICSC_Address__c','RICSC_AddressesGR__r',involvedAccs,'RICSC_LRMainAddress__c','RICSC_GRMainAddress__c'));
          System.enqueueJob(new QueueableClasses.DefaultRecordCalculationForRelatedObjects('RICSC_Phone__c','RICSC_PhonesGR__r',involvedAccs,'RICSC_DefaultPhone__c','RICSC_DefaultGRPhone__c'));
          System.enqueueJob(new QueueableClasses.DefaultRecordCalculationForRelatedObjects('RICSC_SocialMediaID__c','RICSC_SocialMediaIDsGR__r',involvedAccs,'RICSC_DefaultSocialMediaID__c','RICSC_DefaultGRSocialMediaID__c'));
        }else{
          CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_Email__c','RICSC_EmailsGR__r',involvedAccs,'RICSC_DefaultEmail__c','RICSC_DefaultGREmail__c');
          CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_Address__c','RICSC_AddressesGR__r',involvedAccs,'RICSC_LRMainAddress__c','RICSC_GRMainAddress__c');
          CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_Phone__c','RICSC_PhonesGR__r',involvedAccs,'RICSC_DefaultPhone__c','RICSC_DefaultGRPhone__c');
          CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_SocialMediaID__c','RICSC_SocialMediaIDsGR__r',involvedAccs,'RICSC_DefaultSocialMediaID__c','RICSC_DefaultGRSocialMediaID__c');
        }
      }
    }
  }

  /******************************************************************************
  * @author       Silvan Sholla
  * @date         7/Jan/2020
  * @description  Reference Market/Boutique Calculation for VCA Maison
  ******************************************************************************/

  public without sharing class ReferenceMarketCalculationVCA implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Set<Id> relatedAccountsIds = new Set<Id>();
      if(td.isInsert){
        for(Account acc : (List<Account>)td.newList){
          if(RecordTypeHelper.getRTId('Account', UtilityConstants.PERSON_ACCOUNT_VCA_RT) == acc.RecordTypeId &&
            acc.RICSC_IsGoldenRecord__c == true &&
            acc.RICSC_HasLocalRecords__c == false &&
            acc.RICSC_ReferenceBoutique__c != null){
            relatedAccountsIds.add(acc.Id);
          }
        }
      }
      if(td.isUpdate){
        for(Account acc : (List<Account>)td.newList){
          if(RecordTypeHelper.getRTId('Account', UtilityConstants.PERSON_ACCOUNT_VCA_RT) == acc.RecordTypeId &&
            acc.RICSC_ReferenceBoutique__c != td.oldMap.get(acc.Id).get('RICSC_ReferenceBoutique__c') &&
            acc.RICSC_IsGoldenRecord__c == true &&
            acc.RICSC_HasLocalRecords__c == false &&
            acc.RICSC_ReferenceBoutique__c != null){
            relatedAccountsIds.add(acc.Id);
          }
        }
      }

      if(relatedAccountsIds.size()>0){
       update CalculatingFieldsHandler.referenceMarketCalculation(relatedAccountsIds);
      }
    }
  }
}