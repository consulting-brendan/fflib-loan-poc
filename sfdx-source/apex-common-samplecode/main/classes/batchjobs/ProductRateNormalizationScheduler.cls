/**
 * @description Scheduler for nightly Product Rate Normalization batch job execution
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Product Management
 * 
 * @learnings
 * • Implements Schedulable interface for automated job execution via Apex Scheduler
 * • Provides static setup methods for easy deployment and configuration of scheduled jobs
 * • Uses cron expressions for flexible scheduling (nightly at 2 AM by default)
 * • Encapsulates batch job instantiation and execution with configurable batch size
 * • Includes utility methods for job management: setup, cancel, and status checking
 * • Follows single responsibility principle: only handles scheduling, delegates processing to batch
 **/

public with sharing class ProductRateNormalizationScheduler implements Schedulable 
{
	public static final String DEFAULT_CRON_EXPRESSION = '0 0 2 * * ?'; // Daily at 2 AM
	public static final String DEFAULT_JOB_NAME = 'Product Rate Normalization - Nightly';
	public static final Integer DEFAULT_BATCH_SIZE = 200;

	private Integer batchSize;

	public ProductRateNormalizationScheduler() 
	{
		this(DEFAULT_BATCH_SIZE);
	}

	public ProductRateNormalizationScheduler(Integer batchSize) 
	{
		this.batchSize = batchSize != null ? batchSize : DEFAULT_BATCH_SIZE;
	}

	public void execute(SchedulableContext sc) 
	{
		System.debug('ProductRateNormalizationScheduler: Starting scheduled rate normalization');
		
		Integer productsNeedingNormalization = ProductsSelector.newInstance().countProductsNeedingRateNormalization();
		System.debug('Products needing normalization: ' + productsNeedingNormalization);
		
		if (productsNeedingNormalization > 0) 
		{
			ProductRateNormalizationBatch batch = new ProductRateNormalizationBatch();
			Id batchId = Database.executeBatch(batch, batchSize);
			
			System.debug('ProductRateNormalizationScheduler: Batch job queued with ID: ' + batchId);
		}
		else 
		{
			System.debug('ProductRateNormalizationScheduler: No products need normalization, skipping batch execution');
		}
	}

	public static Id scheduleNightly() 
	{
		return scheduleNightly(DEFAULT_JOB_NAME, DEFAULT_CRON_EXPRESSION, DEFAULT_BATCH_SIZE);
	}

	public static Id scheduleNightly(String jobName, String cronExpression, Integer batchSize) 
	{
		ProductRateNormalizationScheduler scheduler = new ProductRateNormalizationScheduler(batchSize);
		
		System.debug('ProductRateNormalizationScheduler: Scheduling job "' + jobName + '" with cron: ' + cronExpression);
		
		return System.schedule(jobName, cronExpression, scheduler);
	}

	public static void cancelScheduledJob(String jobName) 
	{
		List<CronTrigger> jobs = [
			SELECT Id, CronJobDetail.Name 
			FROM CronTrigger 
			WHERE CronJobDetail.Name = :jobName
		];
		
		for (CronTrigger job : jobs) 
		{
			System.abortJob(job.Id);
			System.debug('ProductRateNormalizationScheduler: Cancelled job: ' + job.CronJobDetail.Name);
		}
	}

	public static List<CronTrigger> getScheduledJobs() 
	{
		return [
			SELECT Id, CronJobDetail.Name, CronExpression, NextFireTime, State
			FROM CronTrigger 
			WHERE CronJobDetail.Name LIKE '%Product Rate Normalization%'
		];
	}

	public static void setupSchedule() 
	{
		cancelScheduledJob(DEFAULT_JOB_NAME);
		scheduleNightly();
		System.debug('ProductRateNormalizationScheduler: Setup completed - nightly job scheduled');
	}
} 