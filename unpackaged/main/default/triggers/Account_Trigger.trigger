trigger Account_Trigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    system.debug(Logginglevel.Error, '------> START:');
    system.debug(Logginglevel.Error, 'CPU :' + limits.getCpuTime()); 
    system.debug(Logginglevel.Error, 'SOQL:' + limits.getQueries());
    system.debug(Logginglevel.Error, 'DMLR:' + limits.getDMLRows());
	system.debug(Logginglevel.Error, 'DMLR:' + limits.getDMLStatements());
    
    TRG_TriggerDispatcher.MainEntry(
        'Account', Trigger.isBefore,
        Trigger.isDelete, Trigger.isAfter,
        Trigger.isInsert, Trigger.isUpdate,
        Trigger.isUndelete, Trigger.isExecuting,
        Trigger.new, Trigger.newMap,
        Trigger.old, Trigger.oldMap
    );
    
    system.debug(Logginglevel.Error, '------> END:');
    system.debug(Logginglevel.Error, 'CPU :' + limits.getCpuTime()); 
    system.debug(Logginglevel.Error, 'SOQL:' + limits.getQueries());
    system.debug(Logginglevel.Error, 'DMLR:' + limits.getDMLRows());
	system.debug(Logginglevel.Error, 'DMLR:' + limits.getDMLStatements());

}