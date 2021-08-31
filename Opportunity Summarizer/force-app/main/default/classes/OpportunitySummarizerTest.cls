/****************************************************************************************************************
* @Name				: OpportunitySummarizerTest.apxc
* @Description		: Test class for OpportunitySummarizer
* @Created By		: Berke Bakkaloğlu
* 
*****************************************************************************************************************/
@isTest
private class OpportunitySummarizerTest {
    @isTest
    private static void testBatchableRanSuccess() {
        OpportunityTestDataFactory.initData(8, 6, 6);
        
        Test.startTest();
        
        OpportunitySummarizer oppSum = new OpportunitySummarizer();
        Database.executeBatch(oppSum);
        
        Test.stopTest();
        
        assertAmounts(48, 24, 12);
    }
    
    @isTest
    private static void testZeroClosedOppsSuccess() {
        OpportunityTestDataFactory.initData(8, 0, 0);
        
        Test.startTest();
        
        OpportunitySummarizer oppSum = new OpportunitySummarizer();
        Database.executeBatch(oppSum);
        
        Test.stopTest();
        
        assertAmounts(48, 0, 0);
    }
    
    private static void assertAmounts(Decimal expectedOpenAmount, Decimal expectedWonAmount, Decimal expectedLostAmount) {
        Map<Id, Map<String, Decimal>> accOpps = OpportunitySummarizer.accountOpportunities;
        for (Id accountId : accOpps.keySet()) {
            Map<String, Decimal> stageAmounts = accOpps.get(accountId);
            for (String stageName : stageAmounts.keySet()) {
                Decimal amount = stageAmounts.get(stageName);
                
                if (stageName == 'Open') {
                    System.assertEquals(expectedOpenAmount, amount);
                }
                
                if (stageName == 'Closed Won') {
                    System.assertEquals(expectedWonAmount, amount);
                }
                
                if (stageName == 'Closed Lost') {
                    System.assertEquals(expectedLostAmount, amount);
                }
            }
        }
    }
}