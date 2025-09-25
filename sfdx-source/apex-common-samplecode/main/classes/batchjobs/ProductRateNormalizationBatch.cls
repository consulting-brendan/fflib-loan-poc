/**
 * @description Batch job for Product Rate Normalization processing products asynchronously
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Product Management
 * 
 * @learnings
 * • Implements Database.Batchable<Product__c> for bulk processing with governor limit management
 * • Delegates business logic to service layer maintaining separation of concerns
 * • Uses ProductsSelector for data access ensuring consistent querying patterns and security
 * • Implements start(), execute(), and finish() methods for complete batch lifecycle management
 * • Handles bulk operations efficiently with configurable batch size for performance optimization
 * • Provides comprehensive logging for monitoring and troubleshooting batch execution
 **/

public with sharing class ProductRateNormalizationBatch implements Database.Batchable<SObject>, Database.Stateful 
{
	private Integer recordsProcessed = 0;
	private Integer batchesProcessed = 0;
	private List<String> errors = new List<String>();

	public Database.QueryLocator start(Database.BatchableContext bc) 
	{
		System.debug('ProductRateNormalizationBatch: Starting batch job');
		
		String queryString = 'SELECT Id, Name, Base_Rate__c, Min_Credit_Score__c FROM Product__c WHERE Base_Rate__c != null AND (Base_Rate__c < ' + Products.MIN_RATE + ' OR Base_Rate__c > ' + Products.MAX_RATE + ') WITH SECURITY_ENFORCED';
		return Database.getQueryLocator(queryString);
	}

	public void execute(Database.BatchableContext bc, List<SObject> scope) 
	{
		try 
		{
			batchesProcessed++;
			Integer scopeSize = scope.size();
			
			System.debug('ProductRateNormalizationBatch: Processing batch ' + batchesProcessed + ' with ' + scopeSize + ' records');
			
			if (!scope.isEmpty())
			{
				IProducts products = Products.newInstance((List<Product__c>) scope);
				Integer needingNormalization = products.countProductsNeedingNormalization();
				
				fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
				products.normalizeRates(uow);
				uow.commitWork();
				
				recordsProcessed += needingNormalization;
				
				System.debug('ProductRateNormalizationBatch: Normalized ' + needingNormalization + ' records in this batch');
			}
		}
		catch (Exception e) 
		{
			String errorMsg = 'Batch ' + batchesProcessed + ' failed: ' + e.getMessage();
			errors.add(errorMsg);
			System.debug('ProductRateNormalizationBatch ERROR: ' + errorMsg);
		}
	}

	public void finish(Database.BatchableContext bc) 
	{
		AsyncApexJob job = [
			SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedDate, CompletedDate
			FROM AsyncApexJob 
			WHERE Id = :bc.getJobId()
		];

		System.debug('ProductRateNormalizationBatch: Batch job completed');
		System.debug('Job Status: ' + job.Status);
		System.debug('Total Batches Processed: ' + job.JobItemsProcessed);
		System.debug('Total Records Normalized: ' + recordsProcessed);
		System.debug('Number of Errors: ' + job.NumberOfErrors);
		System.debug('Started: ' + job.CreatedDate);
		System.debug('Completed: ' + job.CompletedDate);

		if (!errors.isEmpty()) 
		{
			System.debug('Errors encountered:');
			for (String error : errors) 
			{
				System.debug('- ' + error);
			}
		}

		Integer remainingCount = ProductsSelector.newInstance().countProductsNeedingRateNormalization();
		if (remainingCount > 0) 
		{
			System.debug('WARNING: ' + remainingCount + ' products still need normalization after batch completion');
		}
		else 
		{
			System.debug('SUCCESS: All products are now within acceptable rate ranges');
		}
	}
} 