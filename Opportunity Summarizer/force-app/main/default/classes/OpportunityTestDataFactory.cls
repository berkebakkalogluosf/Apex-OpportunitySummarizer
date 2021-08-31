/****************************************************************************************************************
* @Name				: OpportunityTestDataFactory.apxc
* @Description		: Test class to create the test data with Accounts that have primary Contacts 
and the given amount of Opportunities per stage
* @Created By		: Berke Bakkaloğlu
* 
*****************************************************************************************************************/
@isTest
public class OpportunityTestDataFactory {
    @TestVisible
    private static void initData(Integer openOpps, Integer wonOpps, Integer lostOpps) {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for (Integer i = 0; i < 10; i++) {
            accounts.add(new Account(Name = 'Account' + i));
        }
        
        insert accounts;
        
        Integer counter = 0;
        for (Account account : [SELECT Id FROM Account]) {
            Contact contact = new Contact();
            contact.LastName = 'primaryForAccount' + counter;
            contact.Email = 'morakti@hotmail.com';
            contact.Is_Primary_Contact__c = TRUE;
            contact.AccountId = account.Id;
            
            contacts.add(contact);
            
            DateTime now = System.now();
            Date closeDate = Date.newInstance(now.year() + 1, now.month(), now.day());
            
            for (Integer i = 0; i < openOpps; i++) {
                Opportunity opportunity = new Opportunity();
                opportunity.Name = 'Open' + i;
                opportunity.StageName = 'Open';
                opportunity.Amount = 6;
                opportunity.CloseDate = closeDate;
                opportunity.AccountId = account.Id;
                
                opportunities.add(opportunity);
            }
            
            for (Integer i = 0; i < wonOpps; i++) {
                Opportunity opportunity = new Opportunity();
                opportunity.Name = 'ClosedWon' + i;
                opportunity.StageName = 'Closed Won';
                opportunity.Amount = 4;
                opportunity.CloseDate = closeDate;
                opportunity.AccountId = account.Id;
                
                opportunities.add(opportunity);
            }
            
            for (Integer i = 0; i < lostOpps; i++) {
                Opportunity opportunity = new Opportunity();
                opportunity.Name = 'ClosedLost' + i;
                opportunity.StageName = 'Closed Lost';
                opportunity.Amount = 2;
                opportunity.CloseDate = closeDate;
                opportunity.AccountId = account.Id;
                
                opportunities.add(opportunity);
            }
            counter++;
        }
        insert contacts;
        insert opportunities;
    }
}