@isTest
private class OpportunityMailSchedulerTest {

    @testSetup
    private static void setup() {
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
            
            for (Integer i = 0; i < 6; i++) {
                Opportunity opportunity = new Opportunity();
                opportunity.Name = 'ClosedWon' + i;
                opportunity.StageName = 'Closed Won';
                opportunity.Amount = 1;
                opportunity.CloseDate = closeDate;
                opportunity.AccountId = account.Id;
                
                opportunities.add(opportunity);
            }
            
            for (Integer i = 0; i < 6; i++) {
                Opportunity opportunity = new Opportunity();
                opportunity.Name = 'ClosedLost' + i;
                opportunity.StageName = 'Closed Lost';
                opportunity.Amount = 2; //2 mil
                opportunity.CloseDate = closeDate;
                opportunity.AccountId = account.Id;
                
                opportunities.add(opportunity);
            }
            
            for (Integer i = 0; i < 6; i++) {
                Opportunity opportunity = new Opportunity();
                opportunity.Name = 'Open' + i;
                opportunity.StageName = 'Open';
                opportunity.Amount = 3; //9 hundred mil
                opportunity.CloseDate = closeDate;
                opportunity.AccountId = account.Id;
                
                opportunities.add(opportunity);
            }
            counter++;
        }
        insert contacts;
        insert opportunities;
    }
    
    @isTest
    private static void testDailyScheduledBatch() {
        Test.startTest();
        
        String jobId = System.schedule('Daily Opportunity Summarizer', OpportunityMailScheduler.DAILY_CRON_EXP, new OpportunityMailScheduler());
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        
        System.assertEquals(OpportunityMailScheduler.DAILY_CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2021-08-27 10:00:00', String.valueOf(ct.NextFireTime)); // Tested In: 2021-08-26 17:00:00
        
        Test.stopTest();
    }
    
    @isTest
    private static void testWeeklyScheduledBatch() {
        Test.startTest();
        
        String jobId = System.schedule('Weekly Opportunity Summarizer', OpportunityMailScheduler.WEEKLY_CRON_EXP, new OpportunityMailScheduler());
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        
        System.assertEquals(OpportunityMailScheduler.WEEKLY_CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2021-08-27 13:00:00', String.valueOf(ct.NextFireTime)); // Tested In: 2021-08-26 17:00:00
        
        Test.stopTest();
    }
    
    @isTest
    private static void testMonthlyScheduledBatch() {
        Test.startTest();
        
        String jobId = System.schedule('Monthly Opportunity Summarizer', OpportunityMailScheduler.MONTHLY_CRON_EXP, new OpportunityMailScheduler());
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        
        System.assertEquals(OpportunityMailScheduler.MONTHLY_CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2021-08-27 18:00:00', String.valueOf(ct.NextFireTime)); // Tested In: 2021-08-26 17:00:00
        
        Test.stopTest();
    }
}