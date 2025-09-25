/**
 * @description Domain class for Loan_Application__c implementing business logic for loan application processing.
 *              Handles submission, validation, product selection, and broker task creation.
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Extends fflib_SObjects and implements ILoanApplications interface for consistent domain pattern
 * • Contains core business logic: application validation, product selection, approval/rejection decisions
 * • Uses selector pattern to query related records (ContactsSelector, ProductsSelector) for data access
 * • Demonstrates Unit of Work pattern with two approaches: with UOW for services, without for triggers
 * • Encapsulates business rules: borrower validation, credit score assessment, task creation for brokers
 **/

public with sharing class LoanApplications extends fflib_SObjects
	implements ILoanApplications
{
	public static final String STATUS_DRAFT = 'Draft';
	public static final String STATUS_SUBMITTED = 'Submitted';
	public static final String STATUS_APPROVED = 'Approved';
	public static final String STATUS_REJECTED = 'Rejected';

	public static ILoanApplications newInstance(List<Loan_Application__c> recordList)
	{
		return (ILoanApplications) Application.Domain.newInstance(recordList);
	}
	
	public static ILoanApplications newInstance(Set<Id> recordIdSet)
	{
		return (ILoanApplications) Application.Domain.newInstance(recordIdSet);
	}
	
	public LoanApplications(List<Loan_Application__c> sObjectList)
	{
		super(sObjectList, Schema.Loan_Application__c.SObjectType);
	}

	public List<Loan_Application__c> getLoanApplications()
	{
		return (List<Loan_Application__c>) getRecords();
	}

	public Set<Id> getBorrowerIds()
	{
		Set<Id> borrowerIds = new Set<Id>();
		for (Loan_Application__c app : getLoanApplications())
		{
			if (app.Borrower__c != null)
			{
				borrowerIds.add(app.Borrower__c);
			}
		}
		return borrowerIds;
	}

		public void submitApplications(fflib_ISObjectUnitOfWork uow)
	{
		Set<Id> borrowerIds = getBorrowerIds();
		Map<Id, Contact> borrowerMap = new Map<Id, Contact>(
			ContactsSelector.newInstance().selectById(borrowerIds)
		);

		List<Product__c> allProducts = ProductsSelector.newInstance().selectAll();
		IProducts products = Products.newInstance(allProducts);

		for (Loan_Application__c app : getLoanApplications())
		{
			processApplication(app, borrowerMap.get(app.Borrower__c), products, uow);
		}
	}

	public void submitApplications()
	{
		Set<Id> borrowerIds = getBorrowerIds();
		Map<Id, Contact> borrowerMap = new Map<Id, Contact>(
			ContactsSelector.newInstance().selectById(borrowerIds)
		);

		List<Product__c> allProducts = ProductsSelector.newInstance().selectAll();
		IProducts products = Products.newInstance(allProducts);

		fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

		for (Loan_Application__c app : getLoanApplications())
		{
			processApplicationInTrigger(app, borrowerMap.get(app.Borrower__c), products, uow);
		}

		uow.commitWork();
	}

	private void processApplication(Loan_Application__c app, Contact borrower, IProducts products, fflib_ISObjectUnitOfWork uow)
	{
		String validationResult = validateApplication(app, borrower);
		
		if (String.isBlank(validationResult))
		{
			Product__c selectedProduct = products.selectBestProductForCreditScore(borrower.Credit_Score__c);
			
			if (selectedProduct != null)
			{
				app.Status__c = STATUS_APPROVED;
				app.Product__c = selectedProduct.Id;
				app.Approval_Outcome__c = 'Application approved with product: ' + selectedProduct.Name;
				createBrokerTask(app, uow);
			}
			else
			{
				app.Status__c = STATUS_REJECTED;
				app.Approval_Outcome__c = 'No eligible product found for credit score: ' + borrower.Credit_Score__c;
			}
		}
		else
		{
			app.Status__c = STATUS_REJECTED;
			app.Approval_Outcome__c = validationResult;
		}

		uow.registerDirty(app);
	}

	private void processApplicationInTrigger(Loan_Application__c app, Contact borrower, IProducts products, fflib_ISObjectUnitOfWork uow)
	{
		String validationResult = validateApplication(app, borrower);
		
		if (String.isBlank(validationResult))
		{
			Product__c selectedProduct = products.selectBestProductForCreditScore(borrower.Credit_Score__c);
			
			if (selectedProduct != null)
			{
				app.Status__c = STATUS_APPROVED;
				app.Product__c = selectedProduct.Id;
				app.Approval_Outcome__c = 'Application approved with product: ' + selectedProduct.Name;
				createBrokerTask(app, uow);
			}
			else
			{
				app.Status__c = STATUS_REJECTED;
				app.Approval_Outcome__c = 'No eligible product found for credit score: ' + borrower.Credit_Score__c;
			}
		}
		else
		{
			app.Status__c = STATUS_REJECTED;
			app.Approval_Outcome__c = validationResult;
		}
	}

	private String validateApplication(Loan_Application__c app, Contact borrower)
	{
		List<String> errors = new List<String>();

		if (borrower == null)
		{
			errors.add('Borrower not found');
		}
		else
		{
			if (String.isBlank(borrower.Email))
			{
				errors.add('Borrower email is required');
			}
			if (borrower.Annual_Income__c == null || borrower.Annual_Income__c <= 0)
			{
				errors.add('Borrower annual income must be greater than 0');
			}
			if (borrower.Credit_Score__c == null)
			{
				errors.add('Borrower credit score is required');
			}
		}

		if (app.Amount__c == null || app.Amount__c <= 0)
		{
			errors.add('Loan amount must be greater than 0');
		}

		return String.join(errors, '; ');
	}

	private void createBrokerTask(Loan_Application__c app, fflib_ISObjectUnitOfWork uow)
	{
		Task brokerTask = new Task();
		brokerTask.Subject = 'Prepare documents';
		brokerTask.WhatId = app.Id;
		brokerTask.ActivityDate = calculateBusinessDays(System.today(), 2);
		brokerTask.Status = 'Not Started';
		brokerTask.Priority = 'Normal';
		
		uow.registerNew(brokerTask);
	}

	private Date calculateBusinessDays(Date startDate, Integer businessDays)
	{
		Date resultDate = startDate;
		Integer daysAdded = 0;
		
		while (daysAdded < businessDays)
		{
			resultDate = resultDate.addDays(1);
			
			// Check if it's a weekday (Monday = 1, Sunday = 7)
			Datetime dt = Datetime.newInstance(resultDate, Time.newInstance(12, 0, 0, 0));
			String dayOfWeek = dt.format('u');
			
			if (dayOfWeek != '6' && dayOfWeek != '7') // Not Saturday or Sunday
			{
				daysAdded++;
			}
		}
		
		return resultDate;
	}

	public class Constructor implements fflib_IDomainConstructor
	{
		public fflib_SObjects construct(List<Object> objectList)
		{
			return new LoanApplications((List<SObject>) objectList);
		}
	}
} 