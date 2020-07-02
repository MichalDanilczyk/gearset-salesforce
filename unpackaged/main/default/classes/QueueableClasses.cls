/******************************************************************************
 * @author       Silvan Sholla
 * @date         17/Dec/2019
 * @description  This class contains all the queueable classes
 ******************************************************************************/

public class QueueableClasses {

  public class VIPFlagPropagationOverGoldenRecordVCA implements Queueable
  {
    public final Set<Id> goldenRecordAccountIds;

    public VIPFlagPropagationOverGoldenRecordVCA(Set<Id> goldenRecordAccountIds)
    {
        this.goldenRecordAccountIds = goldenRecordAccountIds;
    }
    public void execute(QueueableContext context)
    {
      List<Account> goldenWithRelatedRecords = [SELECT Id,RICSC_Turnover__c,RICSC_ClientFlag__c,(SELECT RICSC_VIP__c FROM RICSC_AccountGoldenRecord__r) FROM Account WHERE Id IN : goldenRecordAccountIds];
      List<sObject> listOfUpdatedRecords = new List < sObject > ();

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
        listOfUpdatedRecords.add(goldenRecord);
      }

      // In this dml i do only golden record VIP population which doesnt have to propagate the VIP over the related objects
      // thats the reason i am dissabling it
      TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VIPFlagPropagation',true);
      Database.update(listOfUpdatedRecords);
      TRG_TriggerDispatcher.skipTriggerMap.put('AccountTriggerHandler.VIPFlagPropagation',false);
    }
  }


  public class FlagPropagationOverRelatedObjects implements Queueable
  {
    public final List<SObject> relatedRecords;
    public final Map<Id,Account> accountsThatChanged;
    public final String flagName;

    public FlagPropagationOverRelatedObjects(Map<Id,Account> accountsThatChanged,List<SObject> relatedRecords,String flagName)
    {
        this.relatedRecords = relatedRecords;
        this.accountsThatChanged = accountsThatChanged;
        this.flagName = flagName;
    }
    public void execute(QueueableContext context)
    {
      List<sObject> listOfUpdatedRecords = new List < sObject > ();

      for (SObject obj: relatedRecords) {
        Account acc = null;
        if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('ricsc_account__c')){
          acc = accountsThatChanged.get((Id)obj.get('ricsc_account__c'));
        }
        else if(obj.getSobjectType().getDescribe().fields.getMap().keySet().contains('accountid')){
          acc = accountsThatChanged.get((Id)obj.get('AccountId'));
        }
        if(acc != null){
          obj.put(flagName, acc.get(flagName));
          listOfUpdatedRecords.add(obj);
        }
      }
      Database.update(listOfUpdatedRecords);
    }
  }

  public class DefaultRecordCalculationForRelatedObjects implements Queueable
  {
    public final String objectName;
    public final String parentChildRelationShip;
    public final Set<Id> goldenRecordIds;
    public final String checkBoxFieldNameLR;
    public final String checkBoxFieldNameGR;

    public DefaultRecordCalculationForRelatedObjects(String objectName,String parentChildRelationShip,Set<Id> goldenRecordIds,String checkBoxFieldNameLR,String checkBoxFieldNameGR)
    {
        this.objectName = objectName;
        this.parentChildRelationShip = parentChildRelationShip;
        this.goldenRecordIds = goldenRecordIds;
        this.checkBoxFieldNameLR = checkBoxFieldNameLR;
        this.checkBoxFieldNameGR = checkBoxFieldNameGR;
    }
    public void execute(QueueableContext context)
    {
      CalculatingFieldsHandler.setDefaultRecordForObject(objectName,parentChildRelationShip,goldenRecordIds,checkBoxFieldNameLR,checkBoxFieldNameGR);
    }
  }
}