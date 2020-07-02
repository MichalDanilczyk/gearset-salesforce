public with sharing class SharingRuleTriggerHelper {

  private static String accessLevel = 'read';
  private static Map < String, Id > getGroupIdByDeveloperName = Utility.getGroupIdByDeveloperName();
  private static Map < String, String > getRoleByCountryName = Utility.getRoleByCountryName();
  private static String country = '';
  private static String roleDeveloperName = '';
  private static String groupId = '';
  private static SObject sharingRuleBasedOnCountryOfOriginOfSA;
  private static SObject sharingRuleBasedOnCountryOfOriginOfTransaction;

/******************************************************************************
 * @author       Sholla Silvan
 * @date         21/10/2019
 * @description  creation of sharing records based on the reference sa of golden
 * record as well as the local , also based on the coutruy of origin of the
 * Transaction
 ******************************************************************************/
  public static void afterInsert(List<sObject> newSOBjectList ,Set<Id> accountIds ,String objectName) {
    Map < Id, Account > getAccountObjectByAccountId = getAccountObjectByAccountId(accountIds);
    List < SObject > sObjectShareList = new List < SObject > ();
    String goldenRecordLookUp = (objectName == 'RICSC_Transaction__share')?'RICSC_GoldenRecord__c':'RICSC_GR__c';
    for(sObject obj : newSOBjectList){

      if(obj.get('RICSC_Account__c') != null && getAccountObjectByAccountId.containsKey(obj.get('RICSC_Account__c').toString())
         && getAccountObjectByAccountId.get(obj.get('RICSC_Account__c').toString()).RecordTypeId == RecordTypeHelper.getRTId('Account',  UtilityConstants.PERSON_ACCOUNT_VCA_RT)){
        country = getAccountObjectByAccountId.get(obj.get('RICSC_Account__c').toString()).RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c;
        if(getRoleByCountryName.containsKey(country)){
          roleDeveloperName = getRoleByCountryName.get(country);
          groupId = getGroupIdByDeveloperName.get(roleDeveloperName);
          sharingRuleBasedOnCountryOfOriginOfSA = createSharingRules(obj.id,groupId,objectName,UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD);
          sObjectShareList.add(sharingRuleBasedOnCountryOfOriginOfSA);
        }
        if(objectName == 'RICSC_Transaction__share' && obj.get('RICSC_CountryOfOrigin__c') != null && getRoleByCountryName.containsKey(obj.get('RICSC_CountryOfOrigin__c').toString())){
          sharingRuleBasedOnCountryOfOriginOfTransaction = createSharingRules(obj.id,getGroupIdByDeveloperName.get(getRoleByCountryName.get(obj.get('RICSC_CountryOfOrigin__c').toString())),objectName,UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD);
          if(sharingRuleBasedOnCountryOfOriginOfSA != sharingRuleBasedOnCountryOfOriginOfTransaction){
            sObjectShareList.add(sharingRuleBasedOnCountryOfOriginOfTransaction);
          }
        }
      }

      if(obj.get(goldenRecordLookUp) != null && getAccountObjectByAccountId.containsKey(obj.get(goldenRecordLookUp).toString())
         && getAccountObjectByAccountId.get(obj.get(goldenRecordLookUp).toString()).RecordTypeId == RecordTypeHelper.getRTId('Account',  UtilityConstants.PERSON_ACCOUNT_VCA_RT)){
        country = getAccountObjectByAccountId.get(obj.get(goldenRecordLookUp).toString()).RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c;
        if(getRoleByCountryName.containsKey(country)){
          roleDeveloperName = getRoleByCountryName.get(country);
          groupId = getGroupIdByDeveloperName.get(roleDeveloperName);
          sharingRuleBasedOnCountryOfOriginOfSA = createSharingRules(obj.id,groupId,objectName,UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD);
          sObjectShareList.add(sharingRuleBasedOnCountryOfOriginOfSA);
        }
        if(objectName == 'RICSC_Transaction__share' && obj.get('RICSC_CountryOfOrigin__c') != null && getRoleByCountryName.containsKey(obj.get('RICSC_CountryOfOrigin__c').toString())){
          sharingRuleBasedOnCountryOfOriginOfTransaction = createSharingRules(obj.id,getGroupIdByDeveloperName.get(getRoleByCountryName.get(obj.get('RICSC_CountryOfOrigin__c').toString())),objectName,UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD);
          if(sharingRuleBasedOnCountryOfOriginOfSA != sharingRuleBasedOnCountryOfOriginOfTransaction){
            sObjectShareList.add(sharingRuleBasedOnCountryOfOriginOfTransaction);
          }
        }
      }
    }

    if(sObjectShareList.size() != 0){
      Database.Insert(sObjectShareList,false);
    }
  }

  public static void afterUpdate(List<sObject> newsOBjectList ,Map<Id,sObject> oldSObjectMap,Set<Id> accountIds,String objectName) {
    Map < Id, Account > getAccountObjectByAccountId = getAccountObjectByAccountId(accountIds);
    Set < Id > sObjectShareRemoveList = new Set < Id > ();
    List < SObject > sObjectShareList = new List < SObject > ();
    String goldenRecordLookUp = (objectName == 'RICSC_Transaction__share')?'RICSC_GoldenRecord__c':'RICSC_GR__c';

    for(sObject obj : newSOBjectList){

      //if true deletes the sharing settings
      if((obj.get('RICSC_Account__c') !=null && (obj.get('RICSC_Account__c') != oldSObjectMap.get(obj.Id).get('RICSC_Account__c'))) || (obj.get(goldenRecordLookUp) !=null && (obj.get(goldenRecordLookUp) != oldSObjectMap.get(obj.Id).get(goldenRecordLookUp))) ||
         ((obj.get('RICSC_CountryOfOrigin__c') != null && (obj.get('RICSC_CountryOfOrigin__c') != oldSObjectMap.get(obj.Id).get('RICSC_CountryOfOrigin__c'))) && objectName == 'RICSC_Transaction__share')){
        if(getAccountObjectByAccountId.containsKey(obj.get('RICSC_Account__c').toString())
          && getAccountObjectByAccountId.get(obj.get('RICSC_Account__c').toString()).RecordTypeId == RecordTypeHelper.getRTId('Account',  UtilityConstants.PERSON_ACCOUNT_VCA_RT)){
          sObjectShareRemoveList.add(obj.get('Id').toString());
          //if true create sharing settings (checks if the new related account is VIP)
          country = getAccountObjectByAccountId.get(obj.get('RICSC_Account__c').toString()).RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c;
          if(getRoleByCountryName.containsKey(country)){
            roleDeveloperName = getRoleByCountryName.get(country);
            groupId = getGroupIdByDeveloperName.get(roleDeveloperName);
            sharingRuleBasedOnCountryOfOriginOfSA = createSharingRules(obj.id,groupId,objectName,UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD);
            sObjectShareList.add(sharingRuleBasedOnCountryOfOriginOfSA);
          }
          if(objectName == 'RICSC_Transaction__share' &&  obj.get('RICSC_CountryOfOrigin__c') != null && getRoleByCountryName.containsKey(obj.get('RICSC_CountryOfOrigin__c').toString())){
            sharingRuleBasedOnCountryOfOriginOfTransaction = createSharingRules(obj.id,getGroupIdByDeveloperName.get(getRoleByCountryName.get(obj.get('RICSC_CountryOfOrigin__c').toString())),objectName,UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD);
            if(sharingRuleBasedOnCountryOfOriginOfSA != sharingRuleBasedOnCountryOfOriginOfTransaction){
              sObjectShareList.add(sharingRuleBasedOnCountryOfOriginOfTransaction);
            }
          }
        }else{
          sObjectShareRemoveList.add(obj.get('Id').toString());
        }
      }

      if(((obj.get('RICSC_Account__c') !=null && (obj.get('RICSC_Account__c') != oldSObjectMap.get(obj.Id).get('RICSC_Account__c'))) ||
         (obj.get(GoldenRecordLookUp) !=null && (obj.get(GoldenRecordLookUp) != oldSObjectMap.get(obj.Id).get(GoldenRecordLookUp)))) ||
         ((obj.get('RICSC_CountryOfOrigin__c') != null && (obj.get('RICSC_CountryOfOrigin__c') != oldSObjectMap.get(obj.Id).get('RICSC_CountryOfOrigin__c'))) &&
         objectName == 'RICSC_Transaction__share')){

        if(obj.get(GoldenRecordLookUp) != null && getAccountObjectByAccountId.containsKey(obj.get(GoldenRecordLookUp).toString())
          && getAccountObjectByAccountId.get(obj.get(GoldenRecordLookUp).toString()).RecordTypeId == RecordTypeHelper.getRTId('Account',  UtilityConstants.PERSON_ACCOUNT_VCA_RT)){
          sObjectShareRemoveList.add(obj.get('Id').toString());
          //if true create sharing settings (checks if the new related account is VIP)

          country = getAccountObjectByAccountId.get(obj.get(GoldenRecordLookUp).toString()).RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c;
          if(getRoleByCountryName.containsKey(country)){
            roleDeveloperName = getRoleByCountryName.get(country);
            groupId = getGroupIdByDeveloperName.get(roleDeveloperName);
            sharingRuleBasedOnCountryOfOriginOfSA = createSharingRules(obj.id,groupId,objectName,UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD);
            sObjectShareList.add(sharingRuleBasedOnCountryOfOriginOfSA);
          }
          if(objectName == 'RICSC_Transaction__share' &&  obj.get('RICSC_CountryOfOrigin__c') != null && getRoleByCountryName.containsKey(obj.get('RICSC_CountryOfOrigin__c').toString())){
            sharingRuleBasedOnCountryOfOriginOfTransaction = createSharingRules(obj.id,getGroupIdByDeveloperName.get(getRoleByCountryName.get(obj.get('RICSC_CountryOfOrigin__c').toString())),objectName,UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD);
            if(sharingRuleBasedOnCountryOfOriginOfSA != sharingRuleBasedOnCountryOfOriginOfTransaction){
              sObjectShareList.add(sharingRuleBasedOnCountryOfOriginOfTransaction);
            }
          }
        }else{
          sObjectShareRemoveList.add(obj.get('Id').toString());
        }
      }
    }

    if (sObjectShareRemoveList.size() != 0){
      Database.Delete(Database.query('SELECT Id FROM '+objectName+' WHERE ParentId IN :sObjectShareRemoveList'), false);
    }

    if (sObjectShareList.size() != 0){
      Database.Insert(sObjectShareList,false);
    }

  }


  public static Map < Id, Account >  getAccountObjectByAccountId(Set<Id> accountIds){
    Map < Id, Account > getAccountObjectByAccountId = new Map < Id, Account > ([SELECT Id, RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c,RecordTypeid FROM Account WHERE RICSC_VIP__c = true AND Id IN :accountIds]);
    return getAccountObjectByAccountId;
  }

  public static sObject createSharingRules(id objId,Id groupId,String objectName,String apexReason){
    Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
    SObject newSobject = sObjectType.newSObject();
    newSobject.put('ParentId', objId);
    newSobject.put('AccessLevel', accessLevel);
    newSobject.put('UserOrGroupId', groupId);
    newSobject.put('RowCause',apexReason);

    return newSobject;
  }

  public static Set < Id > sharingRulesRemovalsObject(List < sObject > sObjectList, Account acc,String lookup) {
   Set < Id > setOfIdsToBeRemoved = new Set < Id > ();
   for (sObject temp: sObjectList) {
    if (temp.get('RICSC_Account__c') == acc.Id) {
      setOfIdsToBeRemoved.add(temp.get('Id').toString());
    }else if(temp.get(lookup) == acc.Id){
      setOfIdsToBeRemoved.add(temp.get('Id').toString());
    }
   }
   return setOfIdsToBeRemoved;
  }
  public static List < sObject > createSharingRulesObject(List < sObject > sObjectList, Account acc, String accessLevel, String countryOfOrigin, String objectName, Map < String, Id > getGroupIdByDeveloperName,Map < String, String > getRoleByCountryName) {
    List < sObject > listOfsSharingRullesToBeAdded = new List < sObject > ();
    String goldenRecordLookUp = (objectName == 'RICSC_Transaction__share')?'RICSC_GoldenRecord__c':'RICSC_GR__c';

    for (sObject temp: sObjectList) {
      if (temp.get('RICSC_Account__c') == acc.Id) {
      Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
      SObject newSobject = sObjectType.newSObject();

      if(getGroupIdByDeveloperName.containsKey(getRoleByCountryName.get(countryOfOrigin))){
        newSobject.put('ParentId', temp.Id);
        newSobject.put('AccessLevel', accessLevel);
        newSobject.put('UserOrGroupId', getGroupIdByDeveloperName.get(getRoleByCountryName.get(countryOfOrigin)));
        newSobject.put('RowCause',UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD);
        listOfsSharingRullesToBeAdded.add(newSobject);
      }

      if (objectName == 'RICSC_Transaction__share' && temp.get('RICSC_CountryOfOrigin__c') != null && getRoleByCountryName.containsKey(temp.get('RICSC_CountryOfOrigin__c').toString())) {
        SObject newSobjectTransaction = sObjectType.newSObject();
        newSobjectTransaction.put('ParentId', temp.Id);
        newSobjectTransaction.put('AccessLevel', accessLevel);
        newSobjectTransaction.put('UserOrGroupId', getGroupIdByDeveloperName.get(getRoleByCountryName.get(temp.get('RICSC_CountryOfOrigin__c').toString())));
        newSobjectTransaction.put('RowCause',UtilityConstants.VCA_APEX_REASON_LOCAL_RECORD);

        if (newSobject != newSobjectTransaction){
          listOfsSharingRullesToBeAdded.add(newSobjectTransaction);
        }
      }
      }else if(temp.get(goldenRecordLookUp) == acc.Id){
      Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
      SObject newSobject = sObjectType.newSObject();

      if(getGroupIdByDeveloperName.containsKey(getRoleByCountryName.get(countryOfOrigin))){
        newSobject.put('ParentId', temp.Id);
        newSobject.put('AccessLevel', accessLevel);
        newSobject.put('UserOrGroupId', getGroupIdByDeveloperName.get(getRoleByCountryName.get(countryOfOrigin)));
        newSobject.put('RowCause',UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD);
        listOfsSharingRullesToBeAdded.add(newSobject);
      }

        if (objectName == 'RICSC_Transaction__share' && temp.get('RICSC_CountryOfOrigin__c') != null && getRoleByCountryName.containsKey(temp.get('RICSC_CountryOfOrigin__c').toString())) {
        SObject newSobjectTransaction = sObjectType.newSObject();
        newSobjectTransaction.put('ParentId', temp.Id);
        newSobjectTransaction.put('AccessLevel', accessLevel);
        newSobjectTransaction.put('UserOrGroupId', getGroupIdByDeveloperName.get(getRoleByCountryName.get(temp.get('RICSC_CountryOfOrigin__c').toString())));
        newSobjectTransaction.put('RowCause',UtilityConstants.VCA_APEX_REASON_GOLDEN_RECORD);

          if(newSobject != newSobjectTransaction){
            listOfsSharingRullesToBeAdded.add(newSobjectTransaction);
          }
        }
      }
    }
    return listOfsSharingRullesToBeAdded;
  }
}