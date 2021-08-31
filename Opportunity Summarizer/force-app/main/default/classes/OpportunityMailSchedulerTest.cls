/****************************************************************************************************************
* @Name				: OpportunityMailSchedulerTest.apxc
* @Description		: Test class for OpportunityMailScheduler
* @Created By		: Berke Bakkaloğlu
* 
*****************************************************************************************************************/
@isTest
private class OpportunityMailSchedulerTest {
    @isTest
    private static void testDailyScheduledBatchSuccess() {
        OpportunityTestDataFactory.initData(8, 6, 6);
        
        Test.startTest();
        
        String jobId = System.schedule('Daily Opportunity Summarizer', OpportunityMailScheduler.DAILY_CRON_EXP, new OpportunityMailScheduler());
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        
        Test.stopTest();
        
        System.assertEquals(OpportunityMailScheduler.DAILY_CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2021-09-01 10:00:00', String.valueOf(ct.NextFireTime)); // Tested In: 2021-08-31 16:00:00
    }
    
    @isTest
    private static void testWeeklyScheduledBatchSuccess() {
        OpportunityTestDataFactory.initData(8, 6, 6);
        
        Test.startTest();
        
        String jobId = System.schedule('Weekly Opportunity Summarizer', OpportunityMailScheduler.WEEKLY_CRON_EXP, new OpportunityMailScheduler());
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        
        Test.stopTest();
        
        System.assertEquals(OpportunityMailScheduler.WEEKLY_CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2021-09-03 13:00:00', String.valueOf(ct.NextFireTime)); // Tested In: 2021-08-31 16:00:00
    }
    
    @isTest
    private static void testMonthlyScheduledBatchSuccess() {
        OpportunityTestDataFactory.initData(8, 6, 6);
        
        Test.startTest();
        
        String jobId = System.schedule('Monthly Opportunity Summarizer', OpportunityMailScheduler.MONTHLY_CRON_EXP, new OpportunityMailScheduler());
        
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        
        Test.stopTest();
        
        System.assertEquals(OpportunityMailScheduler.MONTHLY_CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2021-09-24 18:00:00', String.valueOf(ct.NextFireTime)); // Tested In: 2021-08-31 16:00:00
    }
}