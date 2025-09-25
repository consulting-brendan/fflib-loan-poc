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

public class LoanApplicationsSelector extends fflib_SObjectSelector
	implements ILoanApplicationsSelector
{
	public static ILoanApplicationsSelector newInstance()
	{
		return (ILoanApplicationsSelector) Application.Selector.newInstance(Loan_Application__c.SObjectType);
	}
	
	public List<Schema.SObjectField> getSObjectFieldList()
	{
		return new List<Schema.SObjectField> {
			Loan_Application__c.Id,
			Loan_Application__c.Name,
			Loan_Application__c.Borrower__c,
			Loan_Application__c.Amount__c,
			Loan_Application__c.Status__c,
			Loan_Application__c.Product__c,
			Loan_Application__c.Approval_Outcome__c
		};
	}

	public Schema.SObjectType getSObjectType()
	{
		return Loan_Application__c.SObjectType;
	}

	public List<Loan_Application__c> selectById(Set<Id> idSet)
	{
		System.debug('LoanApplicationsSelector.selectById() - Querying ' + idSet.size() + ' IDs: ' + idSet);
		List<Loan_Application__c> results = (List<Loan_Application__c>) selectSObjectsById(idSet);
		System.debug('LoanApplicationsSelector.selectById() - Found ' + results.size() + ' records');
		return results;
	}

	public List<Loan_Application__c> selectByBorrower(Set<Id> borrowerIds)
	{
		return (List<Loan_Application__c>) Database.query(
			newQueryFactory()
				.assertIsAccessible()
				.setEnforceFLS(true)
				.setCondition('Borrower__c IN :borrowerIds')
				.toSOQL());
	}
		
	public List<Loan_Application__c> selectByStatus(String status)
	{
		return (List<Loan_Application__c>) Database.query(
			newQueryFactory()
				.assertIsAccessible()
				.setEnforceFLS(true)
				.setCondition('Status__c = :status')
				.toSOQL());
	}
} 