global class OpportunityMailScheduler implements Schedulable {

    public static final String DAILY_CRON_EXP = '0 0 10 * * ?';
    public static final String WEEKLY_CRON_EXP = '0 0 13 ? * FRI';
    public static final String MONTHLY_CRON_EXP = '0 0 18 ? * FRIL';
    
    global void execute(SchedulableContext sc) {
        OpportunitySummarizer oppSum = new OpportunitySummarizer();
        Id batchId = Database.executeBatch(oppSum);
    }
}