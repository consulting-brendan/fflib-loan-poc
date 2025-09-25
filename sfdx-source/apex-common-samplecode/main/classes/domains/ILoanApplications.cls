/**
 * @description Interface for Loan Applications domain class defining contract for loan application processing
 * @author Brendan Milton
 * @date 2025
 * @company Lendi (Interview Project)
 * @group Loan Applications
 * 
 * @learnings
 * • Extends fflib_ISObjects to inherit standard collection behavior while adding domain-specific methods
 * • Defines public contract for LoanApplications domain ensuring consistent API across implementations
 * • Method overloading: submitApplications() with and without UOW parameter for different contexts
 * • Enables mocking and testing by programming to interfaces rather than concrete implementations
 * • Supports dependency injection through factory pattern - services depend on interface, not implementation
 **/

public interface ILoanApplications extends fflib_ISObjects
{
	List<Loan_Application__c> getLoanApplications();
	void submitApplications(fflib_ISObjectUnitOfWork uow);
	void submitApplications();
	Set<Id> getBorrowerIds();
} 