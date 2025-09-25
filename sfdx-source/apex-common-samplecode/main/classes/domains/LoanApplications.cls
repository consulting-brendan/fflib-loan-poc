/**
 * Copyright (c) 2013-2016, FinancialForce.com, inc
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
		System.debug('LoanApplications.submitApplications() - Processing ' + getLoanApplications().size() + ' applications');
		// Get borrower information for validation
		Set<Id> borrowerIds = getBorrowerIds();
		System.debug('LoanApplications.submitApplications() - Found ' + borrowerIds.size() + ' borrower IDs');
		Map<Id, Contact> borrowerMap = new Map<Id, Contact>(
			ContactsSelector.newInstance().selectById(borrowerIds)
		);

		// Get all products for selection
		List<Product__c> allProducts = ProductsSelector.newInstance().selectAll();
		IProducts products = Products.newInstance(allProducts);

		for (Loan_Application__c app : getLoanApplications())
		{
			if (app.Status__c == STATUS_DRAFT)
			{
				System.debug('LoanApplications.submitApplications() - Processing application: ' + app.Id);
				processApplication(app, borrowerMap.get(app.Borrower__c), products, uow);
			}
		}
	}

	private void processApplication(Loan_Application__c app, Contact borrower, IProducts products, fflib_ISObjectUnitOfWork uow)
	{
		// Validate application
		String validationResult = validateApplication(app, borrower);
		
		if (String.isBlank(validationResult))
		{
			// Application is valid - try to select a product
			Product__c selectedProduct = products.selectBestProductForCreditScore(borrower.Credit_Score__c);
			
			if (selectedProduct != null)
			{
				// Approve application
				app.Status__c = STATUS_APPROVED;
				app.Product__c = selectedProduct.Id;
				app.Approval_Outcome__c = 'Application approved with product: ' + selectedProduct.Name;
				
				// Create task for broker
				createBrokerTask(app, uow);
			}
			else
			{
				// No eligible product found
				app.Status__c = STATUS_REJECTED;
				app.Approval_Outcome__c = 'No eligible product found for credit score: ' + borrower.Credit_Score__c;
			}
		}
		else
		{
			// Application failed validation
			app.Status__c = STATUS_REJECTED;
			app.Approval_Outcome__c = validationResult;
		}

		uow.registerDirty(app);
	}

	private String validateApplication(Loan_Application__c app, Contact borrower)
	{
		List<String> errors = new List<String>();

		// Validate borrower
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

		// Validate application amount
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