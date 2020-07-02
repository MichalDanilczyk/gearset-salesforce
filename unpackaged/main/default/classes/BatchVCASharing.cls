/******************************************************************************
 * @author       Silvan Sholla
 * @date         11/11/2019
 * @description  Batch apex sharing for the following objects based on the country
 *               Of origin of the reference SA
 *               Address,SocialMediaId,Email,Phone And Transaction
 ******************************************************************************/

public class BatchVCASharing implements
Database.Batchable < sObject >, Schedulable {
  public static final Integer MAX_SCOPE = 100;

  public Database.QueryLocator start(Database.BatchableContext bc) {
      return Database.getQueryLocator('SELECT Id, RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c,RICSC_VIP__c,RICSC_HasLocalRecords__c,RICSC_IsGoldenRecord__c ' +
          'FROM Account ' +
          'WHERE RecordTypeId = \'' + RecordTypeHelper.getRTId('Account', UtilityConstants.PERSON_ACCOUNT_VCA_RT) + '\' '
      );
  }

  public void execute(SchedulableContext sc) {
    BatchVCASharing b = new BatchVCASharing();
    Database.executeBatch(b, MAX_SCOPE);
  }

  public void execute(Database.BatchableContext bc, List < Account > scope) {
      try {
          vCARecordSharing(scope);
      } catch (Exception e) {
          UtilityLogger.logException(e, e.getMessage(), 'BatchAccountScrambler', 'execute');
      }
  }
  public void finish(Database.BatchableContext bc) {
  }

  private void vCARecordSharing(List < Account > listOfAccounts) {
      //all records per object
    Set < Id > setOfIdsOfAccounts = new Set < Id > ();
    for (Account acc: listOfAccounts) {
        setOfIdsOfAccounts.add(acc.Id);
    }

    String accessLvl = 'read';
    Map < String, Id > getGroupIdByDeveloperName = Utility.getGroupIdByDeveloperName();
    Map < String, String > getRoleByCountryName = Utility.getRoleByCountryName();

    //all records per object
    List < RICSC_Email__c > emailList = [SELECT Id, RICSC_Account__c, RICSC_GR__c FROM RICSC_Email__c WHERE RICSC_Account__c IN: setOfIdsOfAccounts OR RICSC_GR__c IN: setOfIdsOfAccounts];
    List < RICSC_SocialMediaID__c > socialMediaList = [SELECT Id, RICSC_Account__c, RICSC_GR__c FROM RICSC_SocialMediaID__c WHERE RICSC_Account__c IN: setOfIdsOfAccounts OR RICSC_GR__c IN: setOfIdsOfAccounts];
    List < RICSC_Phone__c > phoneList = [SELECT Id, RICSC_Account__c, RICSC_GR__c FROM RICSC_Phone__c WHERE RICSC_Account__c IN: setOfIdsOfAccounts OR RICSC_GR__c IN: setOfIdsOfAccounts];
    List < RICSC_Address__c > addressesList = [SELECT Id, RICSC_Account__c, RICSC_GR__c FROM RICSC_Address__c WHERE RICSC_Account__c IN: setOfIdsOfAccounts OR RICSC_GR__c IN: setOfIdsOfAccounts];
    List < RICSC_Transaction__c > transactionList = [SELECT Id, RICSC_Account__c, RICSC_CountryOfOrigin__c, RICSC_GoldenRecord__c FROM RICSC_Transaction__c WHERE RICSC_Account__c IN: setOfIdsOfAccounts OR RICSC_GoldenRecord__c IN: setOfIdsOfAccounts];

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

    for (Account acc: listOfAccounts) {
        if (acc.RICSC_VIP__c == false) {
            if ((acc.RICSC_HasLocalRecords__c == false && acc.RICSC_IsGoldenRecord__c == true) ||
                (acc.RICSC_HasLocalRecords__c == false && acc.RICSC_IsGoldenRecord__c == false)) {
                emailShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(emailList, acc, 'RICSC_GR__c'));
                socialMediaShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(socialMediaList, acc, 'RICSC_GR__c'));
                phoneShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(phoneList, acc, 'RICSC_GR__c'));
                addressShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(addressesList, acc, 'RICSC_GR__c'));
                transactionShareRemoveList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(transactionList, acc, 'RICSC_GoldenRecord__c'));
            } else {
                emailShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(emailList, acc, 'RICSC_GR__c'));
                socialMediaShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(socialMediaList, acc, 'RICSC_GR__c'));
                phoneShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(phoneList, acc, 'RICSC_GR__c'));
                addressShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(addressesList, acc, 'RICSC_GR__c'));
                transactionShareRemoveGoldenList.addAll(SharingRuleTriggerHelper.sharingRulesRemovalsObject(transactionList, acc, 'RICSC_GoldenRecord__c'));
            }
        } else if (acc.RICSC_VIP__c == true) {
            sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(emailList, acc, accessLvl, acc.RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c, 'RICSC_Email__share', getGroupIdByDeveloperName, getRoleByCountryName));
            sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(socialMediaList, acc, accessLvl, acc.RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c, 'RICSC_SocialMediaID__share', getGroupIdByDeveloperName, getRoleByCountryName));
            sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(phoneList, acc, accessLvl, acc.RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c, 'RICSC_Phone__share', getGroupIdByDeveloperName, getRoleByCountryName));
            sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(addressesList, acc, accessLvl, acc.RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c, 'RICSC_Address__share', getGroupIdByDeveloperName, getRoleByCountryName));
            sharingRecordsToBeAdded.addAll(SharingRuleTriggerHelper.createSharingRulesObject(transactionList, acc, accessLvl, acc.RICSC_ReferenceSA__r.RICSC_CountryOfOrigin__c, 'RICSC_Transaction__share', getGroupIdByDeveloperName, getRoleByCountryName));
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
    UtilityLogger.logAllErrors(srUpdateList, false, 'BatchVCASharing','execute');
    Database.DeleteResult[] drList = Database.delete(sharingRecordsToBeDeleted,false);
    UtilityLogger.logAllErrors(drList, true, 'BatchVCASharing','execute');
  }
}