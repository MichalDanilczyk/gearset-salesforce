/******************************************************************************
@author Silvan Sholla
@date 25/Nov/2019
@description This is a container of all trigger classes on RICSC_Relation__c object used within the trigger framework.
******************************************************************************/

public with sharing class RelationTriggerHandler {

 /******************************************************************************
  * @author       Maurizio D'Antonio
  * @date         01/Oct/2019
  * @description  This class contains creation rules for RICSC_Relation__c object update
  ******************************************************************************/

  public without sharing class RelationUpdate implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {

      List<RICSC_Relation__c> relationsToUpdate = new List<RICSC_Relation__c>();

      Set<Id> inverseRelationshipsIds = new Set<Id>();
      Set<Id> relatedAccountIds = new Set<Id>();
      for(RICSC_Relation__c rel : (List<RICSC_Relation__c>) td.newList){
        if(rel.RICSC_InverseRelationship__c != null && rel.RICSC_Account__c != null){
          inverseRelationshipsIds.add(rel.RICSC_InverseRelationship__c);
          relatedAccountIds.add(rel.RICSC_Account__c);
        }
      }
      if(inverseRelationshipsIds.size() > 0){
        Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id, RICSC_SourceCRM__c FROM Account WHERE Id IN :relatedAccountIds]);
        Map<Id, RICSC_Relation__c> inverseRelationships = new Map<Id, RICSC_Relation__c>([SELECT Id, RICSC_EndDate__c FROM RICSC_Relation__c WHERE Id IN :inverseRelationshipsIds]);
        for(RICSC_Relation__c rel : (List<RICSC_Relation__c>) td.newList){
          if(rel.RICSC_InverseRelationship__c != null && rel.RICSC_Account__c != null){
            String sourceCRM = accountsMap.get(rel.RICSC_Account__c).RICSC_SourceCRM__c;
            if(rel.RICSC_RelatedAccount__c != null && sourceCRM != null && sourceCRM.equals('SAP_CRM')){
              if(rel.RICSC_EndDate__c != td.oldMap.get(rel.Id).get('RICSC_EndDate__c')){
                RICSC_Relation__c inverseRelationship = inverseRelationships.get(rel.RICSC_InverseRelationship__c);
                inverseRelationship.RICSC_EndDate__c = rel.RICSC_EndDate__c;
                relationsToUpdate.add(inverseRelationship);
              }
            }
          }
        }
        if(relationsToUpdate.size() > 0){
          Database.update(relationsToUpdate);
        }
      }
    }
  }


  /******************************************************************************
  * @author       Maurizio D'Antonio
  * @date         01/Oct/2019
  * @description  This class contains creation rules for RICSC_Relation__c object creation
  ******************************************************************************/

  public without sharing class RelationCreation implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      Map<Id, RICSC_Relation__c> relIdToInverseRelationship = new Map<Id, RICSC_Relation__c>();
      Map<Id, RICSC_Relation__c> inverseRelationshipsMap = new Map<Id, RICSC_Relation__c>();
      Set<Id> relatedAccountIds = new Set<Id>();
      Set<Id> relationsIds = new Set<Id>();
      Set<Id> inverseRelationshipsIds = new Set<Id>();
      List<RICSC_Relation__c> relationsToUpdate = new List<RICSC_Relation__c>();
      for(RICSC_Relation__c rel : (List<RICSC_Relation__c>) td.newList){
        if(rel.RICSC_Account__c != null && rel.RICSC_RelatedAccount__c != null){
          relatedAccountIds.add(rel.RICSC_Account__c);
          if(rel.RICSC_InverseRelationship__c != null){
            inverseRelationshipsIds.add(rel.RICSC_InverseRelationship__c);
          }
          relationsIds.add(rel.Id);
        }
      }

      if(relationsIds.size()>0 && Schema.sObjectType.RICSC_Relation__c.isUpdateable()){
        if(inverseRelationshipsIds.size() > 0){
          inverseRelationshipsMap = new Map<Id,RICSC_Relation__c>([SELECT Id, RICSC_InverseRelationship__c FROM RICSC_Relation__c WHERE Id IN :inverseRelationshipsIds]);
        }
        List<String> selectFields = new List<String>(Schema.getGlobalDescribe().get('RICSC_Relation__c').getDescribe().fields.getMap().keySet());
        String query = 'SELECT RICSC_RelationType__r.RICSC_InverseRelationshipRole__c,' + String.join(selectFields, ',') + ' FROM RICSC_Relation__c WHERE Id IN :relationsIds';
        List<RICSC_Relation__c> relations = Database.query(query);
        Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id, RICSC_SourceCRM__c FROM Account WHERE Id IN :relatedAccountIds]);
        for(RICSC_Relation__c rel : relations){
          if(rel.RICSC_InverseRelationship__c == null){
            String sourceCRM = accountsMap.get(rel.RICSC_Account__c).RICSC_SourceCRM__c;
            if(rel.RICSC_RelatedAccount__c != null && sourceCRM != null && sourceCRM.equals('SAP_CRM')){
              RICSC_Relation__c inverseRelationship = rel.clone(false, true, false, false);
              inverseRelationship.RICSC_Account__c = rel.RICSC_RelatedAccount__c;
              inverseRelationship.RICSC_RelatedAccount__c = rel.RICSC_Account__c;
              inverseRelationship.RICSC_ExternalID__c = null;
              inverseRelationship.RICSC_InverseRelationship__c = rel.Id;
              inverseRelationship.RICSC_RelationType__c = rel.RICSC_RelationType__r.RICSC_InverseRelationshipRole__c;
              relIdToInverseRelationship.put(rel.Id, inverseRelationship);
            }
          }
          else{
            RICSC_Relation__c inverseRelationship = inverseRelationshipsMap.get(rel.RICSC_InverseRelationship__c);
            if(inverseRelationship.RICSC_InverseRelationship__c == null){
              inverseRelationship.RICSC_InverseRelationship__c = rel.Id;
              relationsToUpdate.add(inverseRelationship);
            }
          }
        }
        if(relIdToInverseRelationship.size() > 0){
          Database.insert(relIdToInverseRelationship.values());
        }
        if(relationsToUpdate.size()>0){
          Database.update(relationsToUpdate);
        }
      }
    }
  }

  /******************************************************************************
  @author Silvan Sholla
  @date 25/Nov/2019
  @description propagate golden record lookup of relation based the accounts
               golden record : in case its populated on the account , then
               the golden record is filled with accounts golden record otherwise
               its getting filled with the local account id
  ******************************************************************************/
  public without sharing class GoldenRecordLookUpPopulate implements TRG_TriggerHandlerInterface {
    public void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td) {
      UtilityAccount.goldenRecordLookUpPopulate('RICSC_RelationsAccount__r','RICSC_Account__c','RICSC_GoldenRecord__c','RelationTriggerHandler',td.newList);
    }
  }
}