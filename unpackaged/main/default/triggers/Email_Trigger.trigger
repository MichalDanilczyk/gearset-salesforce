trigger Email_Trigger on RICSC_Email__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

  TRG_TriggerDispatcher.MainEntry(
        'RICSC_Email__c', Trigger.isBefore,
        Trigger.isDelete, Trigger.isAfter,
        Trigger.isInsert, Trigger.isUpdate,
        Trigger.isUndelete, Trigger.isExecuting,
        Trigger.new, Trigger.newMap,
        Trigger.old, Trigger.oldMap
  );

}