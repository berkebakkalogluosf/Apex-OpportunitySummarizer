global class OpportunitySummarizer implements Database.Batchable<sObject> {
    public Database.QueryLocator start (Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Name, ' +
                                        '(SELECT Id, Amount, StageName FROM Opportunities),' +
                                        '(SELECT Id, EMail FROM Contacts WHERE Is_Primary_Contact__c = TRUE)' +
                                        'FROM Account');
    }
    
    global void execute (Database.BatchableContext bc, List<Account> scope) {
        for (Account acc : scope) {
            Decimal totalOpen = 0;
            Decimal totalClosedWon = 0;
            Decimal totalClosedLost = 0;
            
            for (Opportunity opp : acc.Opportunities) {
                switch on opp.StageName {
                    when 'Closed Won' {
                        totalClosedWon += opp.Amount;
                    }
                    when 'Closed Lost' {
                        totalClosedLost += opp.Amount;
                    }
                    when else {
                        totalOpen += opp.Amount;
                    }
                }
            }
            
            Contact primaryContact = acc.Contacts;
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            mail.setToAddresses(new List<String> {primaryContact.Email});
            mail.setSenderDisplayName(acc.Name + ' Salesforce Scheduled Job Interface');
            mail.setSubject('Opportunity Summary for ' + acc.Name);
            mail.setUseSignature(TRUE);
            
            mail.setHtmlBody('<html><body>Below is a table of opportunities related to the account: ' + acc.Name + '<table>' + 
                             '<tr><th>Account</th><th>Stage</th><th>Amount</th></tr>' +
                             '<tr><td>' + acc.Name + '</td><td>Open</td><td>' + totalOpen + '</td></tr>' +
                             '<tr><td>' + acc.Name + '</td><td>Closed Won</td><td>' + totalClosedWon + '</td></tr>' +
                             '<tr><td>' + acc.Name + '</td><td>Closed Lost</td><td>' + totalClosedLost + '</td></tr>' +
                             '</table></body></html>');
            
            Messaging.sendEmail(new List<Messaging.Email> {mail});
        }
    }
    
    global void finish (Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                          TotalJobItems, CreatedBy.Email
                          FROM AsyncApexJob WHERE Id =
                          :bc.getJobId()];
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {job.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
        mail.setSubject('Apex Sharing Recalculation ' + job.Status);
        mail.setPlainTextBody
            ('The batch Apex job processed ' + job.TotalJobItems +
             ' batches with '+ job.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}