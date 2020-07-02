/******************************************************************************
@author Silvan Sholla
@date 25/Nov/2019
@description This is a container of all trigger classes on RICSC_Email__c object used within the trigger framework.
******************************************************************************/

public with sharing class EmailTriggerHandler {

  public without sharing class VCARecordSharing implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Set<Id> accountIds = new Set<Id>();
      for(RICSC_Email__c email : (List<RICSC_Email__c>) td.newList){
        if(email.RICSC_Account__c != null){
          accountIds.add(email.RICSC_Account__c);
        }
        if(email.RICSC_GR__c != null){
          accountIds.add(email.RICSC_GR__c);
        }
      }

      if(td.isInsert){
        SharingRuleTriggerHelper.AfterInsert(td.newList,accountIds,'RICSC_Email__share');
      }
      if(td.isUpdate){
        SharingRuleTriggerHelper.AfterUpdate(td.newList,td.oldMap,accountIds,'RICSC_Email__share');
      }
    }
  }

  public without sharing class DefaultEmailCheck implements TRG_TriggerHandlerInterface {

    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      Set<Id> involvedAccs = new Set<Id>();

      if(td.isInsert){
        for(SObject currentRecord : (List<SObject>) td.newList){
          if(currentRecord.get('RICSC_GR__c') != null){
            involvedAccs.add(currentRecord.get('RICSC_GR__c').toString());
          }
        }
      }else if(td.isUpdate){
        for(SObject currentRecord : (List<SObject>) td.newList){
          if(currentRecord.get('RICSC_GR__c') != null){
            involvedAccs.add(currentRecord.get('RICSC_GR__c').toString());
          }
        }
      }

      if(involvedAccs.size()>0){
        if(!Utility.isAsync()){
          System.enqueueJob(new QueueableClasses.DefaultRecordCalculationForRelatedObjects('RICSC_Email__c','RICSC_EmailsGR__r',involvedAccs,'RICSC_DefaultEmail__c','RICSC_DefaultGREmail__c'));
        }else{
          CalculatingFieldsHandler.setDefaultRecordForObject('RICSC_Email__c','RICSC_EmailsGR__r',involvedAccs,'RICSC_DefaultEmail__c','RICSC_DefaultGREmail__c');
        }
      }
    }
  }

  /******************************************************************************
  @author Silvan Sholla
  @date 25/Nov/2019
  @description propagate golden record lookup of email based the accounts
               golden record : in case its populated on the account , then
               the golden record is filled with accounts golden record otherwise
               its getting filled with the local account id
  ******************************************************************************/
  public without sharing class GoldenRecordLookUpPopulate implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      UtilityAccount.goldenRecordLookUpPopulate('RICSC_EmailsAccount__r','RICSC_Account__c','RICSC_GR__c','EmailTriggerHandler',td.newList);
    }
  }
}