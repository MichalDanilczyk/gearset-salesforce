trigger Ticket_Trigger on Case (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    TRG_TriggerDispatcher.MainEntry(
        'Case', Trigger.isBefore,
        Trigger.isDelete, Trigger.isAfter,
        Trigger.isInsert, Trigger.isUpdate,
        Trigger.isUndelete, Trigger.isExecuting,
        Trigger.new, Trigger.newMap,
        Trigger.old, Trigger.oldMap
    );

}