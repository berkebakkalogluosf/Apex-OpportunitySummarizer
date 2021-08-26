/****************************************************************************************************************
* @Name				: OpportunitySummarizer.apxc
* @Description		: Maps out the total amounts for each of the specified stages of Opportunities for each Account 
* 					  and sends this data to the primary contact of each Account
* @Created By		: Berke Bakkaloğlu
* 
*****************************************************************************************************************/
global class OpportunitySummarizer implements Database.Batchable<sObject>, Database.Stateful {
    static final String STAGE_OPEN = 'Open';
    static final String STAGE_CLOSED_WON = 'Closed Won';
    static final String STAGE_CLOSED_LOST = 'Closed Lost';
    static final Set<String> STAGES_TO_REPORT = new Set<String>{STAGE_CLOSED_WON, STAGE_OPEN, STAGE_CLOSED_LOST};
    private Map<Id, Map<String, Decimal>> accountOpportunities = new Map<Id, Map<String, Decimal>>();
    
    global Database.QueryLocator start (Database.BatchableContext bc) {
        try {  
            return Database.getQueryLocator('SELECT Id, AccountId, StageName, Amount ' +
                                            'FROM Opportunity WHERE StageName IN :STAGES_TO_REPORT ' + 
                                            'AND (CreatedDate = THIS_MONTH OR LastActivityDate = THIS_MONTH)');
        } catch (QueryException e) {
            System.debug(e);
        }
        
        return null;
    }
    
    global void execute (Database.BatchableContext bc, List<Opportunity> scope) {
        for (Opportunity opp : scope) {
            checkAccountMap(opp);
        }
    }
    
    global void finish (Database.BatchableContext bc) {
        Set<Id> accountIds = accountOpportunities.keySet();
        List<Account> accounts = new List<Account>();
        List<Contact> primaryContacts = new List<Contact>();
        Map<Id, String> accountNames = new Map<Id, String>();
        Map<Id, String> primaryContactEmails = new Map<Id, String>();
        
        try {
            accounts = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];
            primaryContacts = [SELECT Id, AccountId, Email FROM Contact WHERE AccountId IN :accountIds AND Is_Primary_Contact__c = TRUE];
        } catch (QueryException e) {
            System.debug(e);
        }
        
        for (Account acc : accounts) {
            accountNames.put(acc.Id, acc.Name);
        }
        
        for (Contact cont : primaryContacts) {
            primaryContactEmails.put(cont.AccountId, cont.Email);
        }
        
        for (Id accountId : accountIds) {
            Map<String, Decimal> stageTotalAmounts = accountOpportunities.get(accountId);
            Decimal totalOpen = stageTotalAmounts.get(STAGE_OPEN);
            Decimal totalClosedWon = stageTotalAmounts.get(STAGE_CLOSED_WON);
            Decimal totalClosedLost = stageTotalAmounts.get(STAGE_CLOSED_LOST);
            String accountName = accountNames.get(accountId);
            String primaryContactEmail = primaryContactEmails.get(accountId);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            mail.setToAddresses(new List<String> {primaryContactEmail});
            mail.setSenderDisplayName(accountName + ' Salesforce Scheduled Job Interface');
            mail.setSubject('Opportunity Summary for ' + accountName);
            mail.setUseSignature(TRUE);
            
            mail.setHtmlBody('<html><body>Below is a table of opportunities related to the account: ' + accountName + '<br/><table>' + 
                             '<tr><th>Account</th><th>Stage</th><th>Amount</th></tr>' +
                             '<tr><td>' + accountName + '</td><td>Open</td><td>' + totalOpen + '</td></tr>' +
                             '<tr><td>' + accountName + '</td><td>Closed Won</td><td>' + totalClosedWon + '</td></tr>' +
                             '<tr><td>' + accountName + '</td><td>Closed Lost</td><td>' + totalClosedLost + '</td></tr>' +
                             '</table></body></html>');
            
            Messaging.sendEmail(new List<Messaging.Email> {mail});
        }
    }
    
    /****************************************************************************************************************
    * @Name				: checkAccountMap
    * @Description		: Checks if the Opportunity's Account exists in the map, 
    * 					  checks the stages if it exists, creates a new map entry if it doesn't
    * @Created By		: Berke Bakkaloğlu
    * @Param	opp	Opportunity	Iterative element of the data we get from the start block
    * 
    *****************************************************************************************************************/
    private void checkAccountMap(Opportunity opp) {
        if (accountOpportunities.containsKey(opp.AccountId)) {
            checkStageNameMap(opp);
        } else {
            createMapEntry(opp.AccountId, opp.StageName, opp.Amount);
        }
    }
    
    /****************************************************************************************************************
    * @Name				: checkStageNameMap
    * @Description		: Checks if the Account's stages exists in the map, 
    * 					  checks the amount if it exists, creates a new map entry if it doesn't
    * @Created By		: Berke Bakkaloğlu
    * @Param	opp	Opportunity	Iterative element of the data we get from the start block
    * 
    *****************************************************************************************************************/
    private void checkStageNameMap(Opportunity opp) {
        Map<String, Decimal> stageTotalAmounts = accountOpportunities.get(opp.AccountId);
        if (stageTotalAmounts.containsKey(opp.StageName)) {
            checkAmountMap(opp, stageTotalAmounts);
        } else {
            createMapEntry(opp.AccountId, opp.StageName, opp.Amount);
        }
    }
    
    /****************************************************************************************************************
    * @Name				: checkAmountMap
    * @Description		: Checks if the stage's amount exists in the map, 
    * 					  adds the amount to the existing amount and updates the map if it exists,
    * 					  creates a new map entry if it doesn't
    * @Created By		: Berke Bakkaloğlu
    * @Param	opp	Opportunity	Iterative element of the data we get from the start block
    * @Param	stageTotalAmounts Map<String, Decimal> Map of stages and amounts that already exist for the Account
    * 
    *****************************************************************************************************************/
    private void checkAmountMap(Opportunity opp, Map<String, Decimal> stageTotalAmounts) {
        Decimal totalAmount = stageTotalAmounts.get(opp.StageName);
        if (totalAmount != null) {
            Decimal newTotalAmount = totalAmount + opp.Amount;
            
            createMapEntry(opp.AccountId, opp.StageName, newTotalAmount);
        } else {
            createMapEntry(opp.AccountId, opp.StageName, opp.Amount);
        }
    }
    
    /****************************************************************************************************************
    * @Name				: createMapEntry
    * @Description		: Creates or updates an accountOpportunities map entry using the parameters
    * @Created By		: Berke Bakkaloğlu
    * @Param	accountId	Id		The id of the current Opportunity's Account
    * @Param	stageName	String	The stage name for the current Opportunity
    * @Param	amount		Decimal	The amount for the current Opportunity
    * 
    *****************************************************************************************************************/
    private void createMapEntry(Id accountId, String stageName, Decimal amount) {
        accountOpportunities.put(accountId, new Map<String, Decimal>{stageName => amount});
    }
}