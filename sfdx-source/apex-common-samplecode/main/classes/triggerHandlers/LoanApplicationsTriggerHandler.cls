/**
 * @description Trigger handler for Loan_Application__c implementing fflib SObjectDomain pattern.
 *              Handles validation, defaults, and status change processing for loan applications.
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Extends fflib_SObjectDomain to inherit trigger context awareness and domain-driven design patterns
 * • Overrides onApplyDefaults(), onValidate(), onBeforeUpdate(), onAfterUpdate() for specific trigger events
 * • Separates concerns: validation in onValidate(), business logic in processStatusChanges() 
 * • Interfaces with domain layer (LoanApplications) through Application.Domain.newInstance() factory pattern
 * • Demonstrates before/after trigger separation: status processing in before, contact updates in after
 **/

public class LoanApplicationsTriggerHandler extends fflib_SObjectDomain
{
	public LoanApplicationsTriggerHandler(List<Loan_Application__c> sObjectList)
	{
		super(sObjectList);
	}

	public override void onApplyDefaults()
	{
		for(Loan_Application__c app : (List<Loan_Application__c>) this.records)
		{
			if (String.isBlank(app.Status__c))
			{
				app.Status__c = LoanApplications.STATUS_DRAFT;
			}
		}
	}

	public override void onValidate()
	{
		for(Loan_Application__c app : (List<Loan_Application__c>) this.records)
		{
			if(app.Borrower__c == null)
			{
				app.Borrower__c.addError( 
					error('Borrower is required for loan applications.', app, Loan_Application__c.Borrower__c) 
				);
			}
			
			if(app.Amount__c != null && app.Amount__c <= 0)
			{
				app.Amount__c.addError( 
					error('Loan amount must be greater than zero.', app, Loan_Application__c.Amount__c) 
				);
			}
		}
	}

	public override void onValidate(Map<Id,SObject> existingRecords)
	{
		for (Loan_Application__c app : (List<Loan_Application__c>) this.records)
		{
			Loan_Application__c existingApp = (Loan_Application__c) existingRecords.get(app.Id);
			
			if (app.Borrower__c != existingApp.Borrower__c && 
				existingApp.Status__c != LoanApplications.STATUS_DRAFT)
			{
				app.Borrower__c.addError( 
					error('You cannot change the borrower once the application has been submitted.', 
						  app, Loan_Application__c.Borrower__c) 
				);
			}
			
			if (app.Amount__c != existingApp.Amount__c && 
				existingApp.Status__c != LoanApplications.STATUS_DRAFT)
			{
				app.Amount__c.addError( 
					error('You cannot change the loan amount once the application has been submitted.', 
						  app, Loan_Application__c.Amount__c) 
				);
			}
		}
	}

	public override void onBeforeUpdate(Map<Id,SObject> existingRecords)
	{
		processStatusChanges(existingRecords);
	}

	private void processStatusChanges(Map<Id,SObject> existingRecords)
	{
		List<Loan_Application__c> applicationsToSubmit = new List<Loan_Application__c>();
		
		for (Loan_Application__c app : (List<Loan_Application__c>) this.records)
		{
			Loan_Application__c existingApp = (Loan_Application__c) existingRecords.get(app.Id);
			
			if (existingApp.Status__c == LoanApplications.STATUS_DRAFT && 
				app.Status__c == LoanApplications.STATUS_SUBMITTED)
			{
				applicationsToSubmit.add(app);
			}
		}
		
		if (!applicationsToSubmit.isEmpty())
		{
			ILoanApplications loanApplications = (ILoanApplications) Application.Domain.newInstance(applicationsToSubmit);
			loanApplications.submitApplications();
		}
	}

	public override void onAfterUpdate(Map<Id,SObject> existingRecords)
	{
		updateContactActivity(existingRecords);
	}

	private void updateContactActivity(Map<Id,SObject> existingRecords)
	{
		Set<Id> borrowerIds = new Set<Id>();
		
		for (Loan_Application__c app : (List<Loan_Application__c>) this.records)
		{
			Loan_Application__c existingApp = (Loan_Application__c) existingRecords.get(app.Id);
			
			if (existingApp.Status__c != app.Status__c && 
				(app.Status__c == LoanApplications.STATUS_APPROVED || 
				 app.Status__c == LoanApplications.STATUS_REJECTED))
			{
				if (app.Borrower__c != null)
				{
					borrowerIds.add(app.Borrower__c);
				}
			}
		}
		
		if (!borrowerIds.isEmpty())
		{
			List<Contact> borrowers = ContactsSelector.newInstance().selectById(borrowerIds);
			IContacts contacts = (IContacts) Application.Domain.newInstance(borrowers);
			contacts.updateAccountActivity();
			
			fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
			uow.registerDirty(contacts.getRecords());
			uow.commitWork();
		}
	}

	public class Constructor implements fflib_SObjectDomain.IConstructable
	{
		public fflib_SObjectDomain construct(List<SObject> sObjectList)
		{
			return new LoanApplicationsTriggerHandler(sObjectList);
		}
	}
} 