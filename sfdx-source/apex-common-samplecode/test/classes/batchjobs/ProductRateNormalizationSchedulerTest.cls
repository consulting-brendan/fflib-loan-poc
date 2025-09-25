/**
 * @description Test class for ProductRateNormalizationScheduler
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Product Management Tests
 * 
 * @learnings
 * • Tests scheduled job functionality with Schedulable interface patterns
 * • Uses System.schedule() for testing scheduled execution with cron expressions
 * • Validates job management: scheduling, cancellation, and status checking
 * • Tests conditional batch execution based on data presence
 * • Demonstrates proper cleanup of scheduled jobs to avoid test interference
 **/

@IsTest
private class ProductRateNormalizationSchedulerTest 
{
	@IsTest
	private static void testSchedulerExecuteWithProductsNeedingNormalization()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Too Low Rate', Base_Rate__c = 0.001, Min_Credit_Score__c = 600),
			new Product__c(Name = 'Too High Rate', Base_Rate__c = 0.18, Min_Credit_Score__c = 700)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationScheduler scheduler = new ProductRateNormalizationScheduler();
		scheduler.execute(null);
		Test.stopTest();

		List<Product__c> normalizedProducts = [SELECT Name, Base_Rate__c FROM Product__c ORDER BY Name];
		
		for (Product__c p : normalizedProducts) {
			if (p.Name == 'Too Low Rate') {
				System.assertEquals(Products.MIN_RATE, p.Base_Rate__c);
			} else if (p.Name == 'Too High Rate') {
				System.assertEquals(Products.MAX_RATE, p.Base_Rate__c);
			}
		}
	}

	@IsTest
	private static void testSchedulerExecuteWithNoProductsNeedingNormalization()
	{
		List<Product__c> testProducts = new List<Product__c>{
			new Product__c(Name = 'Good Rate 1', Base_Rate__c = 0.06, Min_Credit_Score__c = 600),
			new Product__c(Name = 'Good Rate 2', Base_Rate__c = 0.08, Min_Credit_Score__c = 700)
		};
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationScheduler scheduler = new ProductRateNormalizationScheduler();
		scheduler.execute(null);
		Test.stopTest();

		List<Product__c> unchangedProducts = [SELECT Base_Rate__c FROM Product__c];
		System.assertEquals(0.06, unchangedProducts[0].Base_Rate__c);
		System.assertEquals(0.08, unchangedProducts[1].Base_Rate__c);
	}

	@IsTest
	private static void testSchedulerExecuteWithEmptyDatabase()
	{
		Test.startTest();
		ProductRateNormalizationScheduler scheduler = new ProductRateNormalizationScheduler();
		scheduler.execute(null);
		Test.stopTest();

		Integer productCount = [SELECT COUNT() FROM Product__c];
		System.assertEquals(0, productCount);
	}

	@IsTest
	private static void testSchedulerWithCustomBatchSize()
	{
		List<Product__c> testProducts = new List<Product__c>();
		for (Integer i = 0; i < 10; i++) {
			testProducts.add(new Product__c(
				Name = 'Product ' + i,
				Base_Rate__c = 0.001,
				Min_Credit_Score__c = 600 + i
			));
		}
		insert testProducts;

		Test.startTest();
		ProductRateNormalizationScheduler scheduler = new ProductRateNormalizationScheduler(5);
		scheduler.execute(null);
		Test.stopTest();

		List<Product__c> normalizedProducts = [SELECT Base_Rate__c FROM Product__c];
		for (Product__c p : normalizedProducts) {
			System.assertEquals(Products.MIN_RATE, p.Base_Rate__c);
		}
	}

	@IsTest
	private static void testScheduleNightlyDefault()
	{
		Test.startTest();
		Id jobId = ProductRateNormalizationScheduler.scheduleNightly();
		Test.stopTest();

		List<CronTrigger> scheduledJobs = ProductRateNormalizationScheduler.getScheduledJobs();
		System.assertEquals(1, scheduledJobs.size());
		System.assertEquals(ProductRateNormalizationScheduler.DEFAULT_JOB_NAME, scheduledJobs[0].CronJobDetail.Name);
		System.assertNotEquals(null, jobId);

		ProductRateNormalizationScheduler.cancelScheduledJob(ProductRateNormalizationScheduler.DEFAULT_JOB_NAME);
	}

	@IsTest
	private static void testScheduleNightlyCustom()
	{
		String customJobName = 'Custom Rate Normalization Job';
		String customCron = '0 0 3 * * ?'; // 3 AM daily
		Integer customBatchSize = 100;

		Test.startTest();
		Id jobId = ProductRateNormalizationScheduler.scheduleNightly(customJobName, customCron, customBatchSize);
		Test.stopTest();

		List<CronTrigger> scheduledJobs = [
			SELECT Id, CronJobDetail.Name, CronExpression
			FROM CronTrigger 
			WHERE CronJobDetail.Name = :customJobName
		];
		
		System.assertEquals(1, scheduledJobs.size());
		System.assertEquals(customJobName, scheduledJobs[0].CronJobDetail.Name);
		System.assertEquals(customCron, scheduledJobs[0].CronExpression);
		System.assertNotEquals(null, jobId);

		ProductRateNormalizationScheduler.cancelScheduledJob(customJobName);
	}

	@IsTest
	private static void testCancelScheduledJob()
	{
		String testJobName = 'Test Rate Normalization Job';
		
		Test.startTest();
		Id jobId = ProductRateNormalizationScheduler.scheduleNightly(testJobName, '0 0 4 * * ?', 150);
		
		List<CronTrigger> beforeCancel = [
			SELECT Id, CronJobDetail.Name 
			FROM CronTrigger 
			WHERE CronJobDetail.Name = :testJobName
		];
		System.assertEquals(1, beforeCancel.size());
		
		ProductRateNormalizationScheduler.cancelScheduledJob(testJobName);
		Test.stopTest();

		List<CronTrigger> afterCancel = [
			SELECT Id, CronJobDetail.Name 
			FROM CronTrigger 
			WHERE CronJobDetail.Name = :testJobName
		];
		System.assertEquals(0, afterCancel.size());
	}

	@IsTest
	private static void testGetScheduledJobs()
	{
		String jobName1 = 'Product Rate Normalization Test 1';
		String jobName2 = 'Product Rate Normalization Test 2';

		Test.startTest();
		Id jobId1 = ProductRateNormalizationScheduler.scheduleNightly(jobName1, '0 0 2 * * ?', 100);
		Id jobId2 = ProductRateNormalizationScheduler.scheduleNightly(jobName2, '0 0 3 * * ?', 150);
		Test.stopTest();

		List<CronTrigger> scheduledJobs = ProductRateNormalizationScheduler.getScheduledJobs();
		System.assertEquals(2, scheduledJobs.size());

		Set<String> jobNames = new Set<String>();
		for (CronTrigger job : scheduledJobs) {
			jobNames.add(job.CronJobDetail.Name);
		}
		
		System.assert(jobNames.contains(jobName1));
		System.assert(jobNames.contains(jobName2));

		ProductRateNormalizationScheduler.cancelScheduledJob(jobName1);
		ProductRateNormalizationScheduler.cancelScheduledJob(jobName2);
	}

	@IsTest
	private static void testSetupSchedule()
	{
		Test.startTest();
		ProductRateNormalizationScheduler.setupSchedule();
		Test.stopTest();

		List<CronTrigger> scheduledJobs = ProductRateNormalizationScheduler.getScheduledJobs();
		System.assertEquals(1, scheduledJobs.size());
		System.assertEquals(ProductRateNormalizationScheduler.DEFAULT_JOB_NAME, scheduledJobs[0].CronJobDetail.Name);
		System.assertEquals(ProductRateNormalizationScheduler.DEFAULT_CRON_EXPRESSION, scheduledJobs[0].CronExpression);

		ProductRateNormalizationScheduler.cancelScheduledJob(ProductRateNormalizationScheduler.DEFAULT_JOB_NAME);
	}

	@IsTest
	private static void testSetupScheduleReplacesExisting()
	{
		Test.startTest();
		ProductRateNormalizationScheduler.setupSchedule();
		
		List<CronTrigger> firstSetup = ProductRateNormalizationScheduler.getScheduledJobs();
		System.assertEquals(1, firstSetup.size());
		
		ProductRateNormalizationScheduler.setupSchedule();
		Test.stopTest();

		List<CronTrigger> secondSetup = ProductRateNormalizationScheduler.getScheduledJobs();
		System.assertEquals(1, secondSetup.size());
		System.assertEquals(ProductRateNormalizationScheduler.DEFAULT_JOB_NAME, secondSetup[0].CronJobDetail.Name);

		ProductRateNormalizationScheduler.cancelScheduledJob(ProductRateNormalizationScheduler.DEFAULT_JOB_NAME);
	}

	@IsTest
	private static void testSchedulerConstructors()
	{
		Test.startTest();
		ProductRateNormalizationScheduler defaultScheduler = new ProductRateNormalizationScheduler();
		ProductRateNormalizationScheduler customScheduler = new ProductRateNormalizationScheduler(250);
		ProductRateNormalizationScheduler nullScheduler = new ProductRateNormalizationScheduler(null);
		Test.stopTest();

		System.assertNotEquals(null, defaultScheduler);
		System.assertNotEquals(null, customScheduler);
		System.assertNotEquals(null, nullScheduler);
	}
} 