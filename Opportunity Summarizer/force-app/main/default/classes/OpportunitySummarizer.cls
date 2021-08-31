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
    @TestVisible private static Map<Id, Map<String, Decimal>> accountOpportunities = new Map<Id, Map<String, Decimal>>();
    
    global Database.QueryLocator start (Database.BatchableContext bc) {
        try {  
            return Database.getQueryLocator('SELECT Id, AccountId, StageName, Amount ' +
                                            'FROM Opportunity WHERE StageName IN :STAGES_TO_REPORT ' + 
                                            'AND (CreatedDate = THIS_MONTH OR LastModifiedDate = THIS_MONTH)');
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
            
            try {
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {mail});
            } catch (Exception e) {
                System.debug(e);
            }
        }
    }
    
    /****************************************************************************************************************
    * @Name				: checkAccountMap
    * @Description		: Checks if the Opportunity's Account exists in the map, 
    * 					  adds the amount of the Opportunity to the corresponding stage if it exists,
    * 					  maps all the stages and sets the amount for the Opportunity's amount for the right stage otherwise
    * @Created By		: Berke Bakkaloğlu
    * @Param	opp	Opportunity	Iterative element of the data we get from the start block
    * 
    *****************************************************************************************************************/
    private void checkAccountMap(Opportunity opp) {
        if (accountOpportunities.containsKey(opp.AccountId)) {
            Map<String, Decimal> stageTotalAmounts = accountOpportunities.get(opp.AccountId);
            sumAmounts(opp, stageTotalAmounts);
        } else {
            initializeAccount(opp);
        }
    }
    
    /****************************************************************************************************************
    * @Name				: sumAmounts
    * @Description		: Adds the amount of the current Opportunity to the existing amount in the map and updates the map
    * @Created By		: Berke Bakkaloğlu
    * @Param	opp	Opportunity	Iterative element of the data we get from the start block
    * @Param	stageTotalAmounts	Map<String, Decimal> Map of stages and amounts that already exist for the Account
    * 
    *****************************************************************************************************************/
    private void sumAmounts(Opportunity opp, Map<String, Decimal> stageTotalAmounts) {
        Decimal totalAmount = stageTotalAmounts.get(opp.StageName);
        Decimal newTotalAmount = totalAmount + opp.Amount;
            
        stageTotalAmounts.put(opp.StageName, newTotalAmount);
        accountOpportunities.put(opp.AccountId, stageTotalAmounts);
    }
    
    /****************************************************************************************************************
    * @Name				: initializeAccount
    * @Description		: Creates all the stages for the current Opportunity's Account with zero amount
    * 					  and updates the stage that corresponds to the current Opportunity
    * @Created By		: Berke Bakkaloğlu
    * @Param	opp	Opportunity	Iterative element of the data we get from the start block
    * 
    *****************************************************************************************************************/
    private void initializeAccount(Opportunity opp) {
        Map<String, Decimal> initialStageAmounts = new Map<String, Decimal>();
        // Initialize all stages
        initialStageAmounts.put(STAGE_OPEN, 0);
        initialStageAmounts.put(STAGE_CLOSED_WON, 0);
        initialStageAmounts.put(STAGE_CLOSED_LOST, 0);
        
        // Update the stage that corresponds to the Opportunity
        initialStageAmounts.put(opp.StageName, opp.Amount);
        accountOpportunities.put(opp.AccountId, initialStageAmounts);
    }
}