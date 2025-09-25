/**
 * @description Service implementation for loan application processing via domain layer
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Service layer orchestrates business processes by coordinating selectors, domains, and Unit of Work
 * • Implements interface to enable dependency injection and testing through Application.Service factory
 * • Demonstrates proper layering: service calls selector → creates domain → executes business logic → commits UOW
 * • Handles cross-cutting concerns like transaction management while delegating business logic to domains
 * • Entry point for external systems (REST APIs, batch jobs) to interact with loan application processing
 **/

public with sharing class LoanApplicationServiceImpl implements ILoanApplicationService
{
	public void submitApplications(Set<Id> applicationIds)
	{
		fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
		
		List<Loan_Application__c> applications = 
			LoanApplicationsSelector.newInstance().selectById(applicationIds);
		
		ILoanApplications loanApplications = LoanApplications.newInstance(applications);
		loanApplications.submitApplications(uow);
		
		uow.commitWork();
	}
} 