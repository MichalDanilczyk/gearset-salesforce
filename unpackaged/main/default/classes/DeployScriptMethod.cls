/**********************************************************************************************
* @author       Piergiorgio Lisanti
* @date         26/Aug/2019
* @description  This interface will be used in DeployScript to dynamically invoke 
*				configured methods
**********************************************************************************************/
public virtual interface DeployScriptMethod {
    
    /**
    *   @description        Method used to execute overridden DeployScriptMethod logic
    *   @param  parameters  map of generic parameters to the method, for future use          
    */
    void run(Map<String,String> parameters);
    
}