/**
 * Copyright (c) 2012-2014, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

public class LoanApplicationsTriggerHandler extends fflib_SObjectDomain
{
	public LoanApplicationsTriggerHandler(List<Loan_Application__c> sObjectList)
	{
		// Domain classes are initialised with lists to enforce bulkification throughout
		super(sObjectList);
	}

	public override void onApplyDefaults()
	{
		System.debug('LoanApplicationsTriggerHandler.onApplyDefaults() - Processing ' + this.records.size() + ' records');
		// Apply defaults to loan applications
		for(Loan_Application__c app : (List<Loan_Application__c>) this.records)
		{
			if (String.isBlank(app.Status__c))
			{
				System.debug('Setting default status to Draft for loan application: ' + app.Id);
				app.Status__c = LoanApplications.STATUS_DRAFT;
			}
		}
	}

	public override void onValidate()
	{
		System.debug('LoanApplicationsTriggerHandler.onValidate() - Validating ' + this.records.size() + ' records');
		// Validate loan applications on insert
		for(Loan_Application__c app : (List<Loan_Application__c>) this.records)
		{
			// Ensure borrower is specified
			if(app.Borrower__c == null)
			{
				System.debug('Validation error: Missing borrower for loan application: ' + app.Id);
				app.Borrower__c.addError( 
					error('Borrower is required for loan applications.', app, Loan_Application__c.Borrower__c) 
				);
			}
			
			// Ensure amount is positive
			if(app.Amount__c != null && app.Amount__c <= 0)
			{
				System.debug('Validation error: Invalid amount for loan application: ' + app.Id + ', Amount: ' + app.Amount__c);
				app.Amount__c.addError( 
					error('Loan amount must be greater than zero.', app, Loan_Application__c.Amount__c) 
				);
			}
		}
	}

	public override void onValidate(Map<Id,SObject> existingRecords)
	{
		// Validate changes to loan applications
		for (Loan_Application__c app : (List<Loan_Application__c>) this.records)
		{
			Loan_Application__c existingApp = (Loan_Application__c) existingRecords.get(app.Id);
			
			// Prevent changing borrower once application is submitted
			if (app.Borrower__c != existingApp.Borrower__c && 
				existingApp.Status__c != LoanApplications.STATUS_DRAFT)
			{
				app.Borrower__c.addError( 
					error('You cannot change the borrower once the application has been submitted.', 
						  app, Loan_Application__c.Borrower__c) 
				);
			}
			
			// Prevent changing amount once application is submitted
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
		System.debug('LoanApplicationsTriggerHandler.onBeforeUpdate() - Processing ' + this.records.size() + ' records');
		// Process status changes from Draft to Submitted
		processStatusChanges(existingRecords);
	}

	private void processStatusChanges(Map<Id,SObject> existingRecords)
	{
		List<Loan_Application__c> applicationsToSubmit = new List<Loan_Application__c>();
		
		for (Loan_Application__c app : (List<Loan_Application__c>) this.records)
		{
			Loan_Application__c existingApp = (Loan_Application__c) existingRecords.get(app.Id);
			
			// Check if status is changing from Draft to Submitted
			if (existingApp.Status__c == LoanApplications.STATUS_DRAFT && 
				app.Status__c == LoanApplications.STATUS_SUBMITTED)
			{
				applicationsToSubmit.add(app);
			}
		}
		
		if (!applicationsToSubmit.isEmpty())
		{
			// Process applications through domain logic
			ILoanApplications loanApplications = (ILoanApplications) Application.Domain.newInstance(applicationsToSubmit);
			fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
			loanApplications.submitApplications(uow);
			uow.commitWork();
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
			
			// Check if status changed to approved or rejected
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
			// Update contact activity for processed applications
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