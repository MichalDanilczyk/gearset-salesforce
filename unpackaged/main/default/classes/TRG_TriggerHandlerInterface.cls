/**********************************************************************************************
* @author       Piergiorgio Lisanti
* @date         22/Aug/2019
* @description  This interface is be used by TRG_TriggerDispatcher to create an instance
*               of "ObjectTriggerHandler" methods to execute for that trigger
**********************************************************************************************/
public virtual interface TRG_TriggerHandlerInterface {

    /**
    *   @description    Method used to execute overridden TRG_TriggerHandlerInterface logic
    *   @param  td      parameter containing trigger context information
    */
    void runTriggerHandler(TRG_TriggerDispatcher.TriggerData td);

}